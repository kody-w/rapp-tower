#!/bin/bash
# release_gate.sh — pre-release wrapper that must PASS before grail_gate.py --export-to.
# Answers: (A) CONTAINMENT — is grail main's tip an ancestor of the qualified canary
# commit (else this release silently reverts a grail hotfix)? (B) SOAK EVIDENCE — has
# that exact commit soaked on :7073 for >= MIN_SOAK_DAYS (default 2)? Run before every release.
set -uo pipefail

ATT_DIR="$HOME/Documents/GitHub/rapp-canary/.ring/attestations"
SOAK_DIR="$HOME/.brainstem-soak"
MIN_SOAK_DAYS="${MIN_SOAK_DAYS:-2}"
CANARY_URL="https://github.com/kody-w/rapp-canary.git"
GRAIL_URL="https://github.com/kody-w/rapp-installer.git"

if [ -t 1 ]; then
  RED=$'\033[31m'; GRN=$'\033[32m'; RST=$'\033[0m'
else
  RED=""; GRN=""; RST=""
fi
PASS="${GRN}PASS${RST}"; FAIL="${RED}FAIL${RST}"

OVERRIDE_REASON=""
if [ "${1:-}" = "--override" ]; then
  OVERRIDE_REASON="${2:-}"
  [ -n "$OVERRIDE_REASON" ] || { echo "usage: release_gate.sh [--override <reason>]" >&2; exit 64; }
elif [ -n "${1:-}" ]; then
  echo "usage: release_gate.sh [--override <reason>]" >&2; exit 64
fi

row() { printf "%-14s %-6b %s\n" "$1" "$2" "$3"; }

# --- newest archived attestation run ---------------------------------------
run_dir=""
for d in $(ls -td "$ATT_DIR"/run-*/ 2>/dev/null); do
  [ -f "$d/RUN.json" ] && { run_dir="${d%/}"; break; }
done
[ -n "$run_dir" ] || { echo "${RED}NO-GO${RST}: no archived attestation runs under $ATT_DIR" >&2; exit 1; }

canary_json=$(find "$run_dir" -name canary.json 2>/dev/null | head -1)
[ -n "$canary_json" ] || { echo "${RED}NO-GO${RST}: $run_dir has no canary.json" >&2; exit 1; }

attested=$(python3 - "$canary_json" <<'PY'
import json, sys
j = json.load(open(sys.argv[1]))
c = j.get("payload", {}).get("commit") or j.get("commit") or j.get("ring_commit") or ""
print(c)
PY
)
[ -n "$attested" ] || { echo "${RED}NO-GO${RST}: no commit field in $canary_json" >&2; exit 1; }

echo "release_gate — attestation $(basename "$run_dir")  (canary attested ${attested:0:12})"
echo ""

# --- (A) CONTAINMENT: grail tip must be ancestor of attested canary --------
a_ok=0; a_note=""; grail_tip="(unfetched)"
SCRATCH=$(mktemp -d "${TMPDIR:-/tmp}/release_gate.XXXXXX")
trap 'rm -rf "$SCRATCH"' EXIT
if git clone -q --bare "$CANARY_URL" "$SCRATCH/canary.git" 2>/dev/null \
   && git -C "$SCRATCH/canary.git" fetch -q "$GRAIL_URL" main 2>/dev/null; then
  grail_tip=$(git -C "$SCRATCH/canary.git" rev-parse FETCH_HEAD 2>/dev/null)
  if ! git -C "$SCRATCH/canary.git" cat-file -e "${attested}^{commit}" 2>/dev/null; then
    a_note="attested commit not found in kody-w/rapp-canary remote"
  elif git -C "$SCRATCH/canary.git" merge-base --is-ancestor "$grail_tip" "$attested" 2>/dev/null; then
    a_ok=1; a_note="grail tip is contained in attested canary commit"
  else
    a_note="grail tip NOT an ancestor — release would revert grail hotfix(es)"
  fi
else
  a_note="could not clone canary / fetch grail main (network?)"
fi
row "CONTAINMENT" "$([ $a_ok = 1 ] && echo "$PASS" || echo "$FAIL")" "grail ${grail_tip:0:12}  ->  canary ${attested:0:12}  ($a_note)"
if [ $a_ok = 0 ] && [ "$grail_tip" != "(unfetched)" ]; then
  echo "  containment-breaking commits (attested..grail_tip):"
  git -C "$SCRATCH/canary.git" log --oneline "${attested}..${grail_tip}" 2>/dev/null | sed 's/^/    /' | head -10
fi

# --- (B) SOAK EVIDENCE ------------------------------------------------------
b_ok=0; soak_commit="(none)"; soak_age="?"; b_note=""
if [ -f "$SOAK_DIR/render.json" ]; then
  soak_commit=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("source_commit",""))' "$SOAK_DIR/render.json")
fi
if [ -f "$SOAK_DIR/soaking-since" ]; then
  since=$(awk '{print $NF}' "$SOAK_DIR/soaking-since")
  soak_age=$(python3 - "$since" <<'PY'
import sys, datetime
try:
    t = datetime.datetime.fromisoformat(sys.argv[1].replace("Z", "+00:00"))
    d = datetime.datetime.now(datetime.timezone.utc) - t
    print(f"{d.total_seconds()/86400:.1f}")
except Exception:
    print("?")
PY
)
fi
if [ "$soak_commit" != "$attested" ]; then
  b_note="soaked commit != attested commit"
elif [ "$soak_age" = "?" ]; then
  b_note="soak start time unreadable ($SOAK_DIR/soaking-since)"
elif python3 -c 'import sys; sys.exit(0 if float(sys.argv[1]) >= float(sys.argv[2]) else 1)' "$soak_age" "$MIN_SOAK_DAYS"; then
  b_ok=1; b_note="soaked ${soak_age}d >= ${MIN_SOAK_DAYS}d minimum"
else
  b_note="only ${soak_age}d soaked, need >= ${MIN_SOAK_DAYS}d"
fi
row "SOAK" "$([ $b_ok = 1 ] && echo "$PASS" || echo "$FAIL")" "soaked ${soak_commit:0:12} for ${soak_age}d  vs attested ${attested:0:12}  ($b_note)"

# --- verdict ----------------------------------------------------------------
echo ""
if [ $a_ok = 1 ] && [ $b_ok = 1 ]; then
  echo "${GRN}GO${RST} — proceed to grail_gate.py --export-to"
  exit 0
fi

if [ -n "$OVERRIDE_REASON" ]; then
  today=$(date +%Y-%m-%d)
  gaps=""
  [ $a_ok = 0 ] && gaps="containment"
  [ $b_ok = 0 ] && gaps="${gaps:+$gaps, }soak-evidence"
  echo "${RED}NO-GO${RST} — override requested. Write this to work/${today}-release-override/DECISION.md"
  echo "before proceeding, then run grail_gate.py manually:"
  echo ""
  cat <<EOF
  # Release override decision record
  - date: ${today}
  - attestation run: $(basename "$run_dir")
  - attested canary commit: ${attested}
  - grail tip: ${grail_tip}
  - gaps overridden: ${gaps}
  - reason: ${OVERRIDE_REASON}
  - operator: $(id -un) <wildhavenhomesllc@gmail.com>
EOF
  exit 2
fi

echo "${RED}NO-GO${RST} — do not run grail_gate.py. Fix the failed gate(s) above or re-run with --override <reason>."
exit 1
