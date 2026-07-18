#!/bin/bash
# crawl-discover.sh — PHASE 0 of the RAPP ecosystem brain: find EVERYTHING
# (known + unknown) and classify each node PUBLIC vs PRIVATE. Read-only.
#
# Outputs two manifests, to two PHYSICALLY SEPARATE repos (parallel-writer safe,
# leak-safe by construction — private names never enter the public tree):
#   <public brain>/atlas/_census-public.tsv    (tracked — public seed)
#   <private brain>/_census-private.tsv         (separate PRIVATE repo)
#
# Private census location resolves in order: $RAPP_BRAIN_PRIVATE, else the
# private repo checkout ~/Documents/GitHub/rapp-brain-private, else the private
# tower work/ dir. It is NEVER written inside the public repo.
#
# Sources: gh repo list (all visibilities) + rapp-map estate-map.json + local
# checkouts. Discovery of repos NOT in any registry is the point — the
# "ungoverned frontier." NEVER prints secret values. Needs authenticated `gh`.
set -uo pipefail

BRAIN="$(cd "$(dirname "$0")/.." && pwd)"
MAP="${RAPP_MAP:-$HOME/Documents/GitHub/rapp-map}"
GH_DIR="${GH_CHECKOUTS:-$HOME/Documents/GitHub}"
PUB="$BRAIN/atlas/_census-public.tsv"
# Private census goes OUTSIDE the public repo, always.
if [ -n "${RAPP_BRAIN_PRIVATE:-}" ]; then PRIVDIR="$RAPP_BRAIN_PRIVATE"
elif [ -d "$HOME/Documents/GitHub/rapp-brain-private/.git" ]; then PRIVDIR="$HOME/Documents/GitHub/rapp-brain-private"
else PRIVDIR="${RAPP_TOWER:-$HOME/Documents/GitHub/rapp-tower}/work/rapp-brain-private"; fi
mkdir -p "$PRIVDIR"
PRIV="$PRIVDIR/_census-private.tsv"

RED=""; GRN=""; YEL=""; RST=""
if [ -t 1 ]; then RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; RST=$'\033[0m'; fi

echo "PHASE 0 — discovering the RAPP ecosystem..."

# 1) Every kody-w repo, all visibilities.
raw=$(gh repo list kody-w --limit 600 --json name,visibility,isArchived,isFork,description,pushedAt \
  --jq '.[] | [.name, .visibility, (.isArchived|tostring), (.isFork|tostring), (.pushedAt[0:10]), (.description // "")] | @tsv' 2>/dev/null)
if [ -z "$raw" ]; then echo "${RED}gh repo list failed (auth?)${RST}"; exit 2; fi

# 2) Which repos does the estate-map already know? (role/layer enrichment + frontier detection)
known=""
if [ -f "$MAP/estate-map.json" ]; then
  known=$(python3 - "$MAP/estate-map.json" <<'PY' 2>/dev/null || true
import json,sys
d=json.load(open(sys.argv[1]))
repos=d.get("repos") or d.get("estate") or []
for r in repos:
    if isinstance(r,dict):
        print(r.get("repo") or r.get("name") or r.get("slug",""))
PY
)
fi
is_known(){ printf '%s\n' "$known" | grep -qxF "$1"; }

# 3) Emit manifests.
printf "name\tvisibility\tarchived\tfork\tpushed\tin_estate_map\tdescription\n" > "$PUB"
printf "name\tvisibility\tarchived\tfork\tpushed\tin_estate_map\tdescription\n" > "$PRIV"
npub=0; npriv=0; nfrontier=0
while IFS=$'\t' read -r name vis arch fork pushed desc; do
  [ -z "$name" ] && continue
  inmap="no"; is_known "$name" && inmap="yes"
  vl=$(printf '%s' "$vis" | tr '[:upper:]' '[:lower:]')
  line="$name	$vl	$arch	$fork	$pushed	$inmap	$desc"
  if [ "$vl" = "public" ]; then
    printf '%s\n' "$line" >> "$PUB"; npub=$((npub+1))
    if [ "$inmap" = "no" ] && [ "$arch" = "false" ]; then nfrontier=$((nfrontier+1)); fi
  else
    printf '%s\n' "$line" >> "$PRIV"; npriv=$((npriv+1))
  fi
done <<< "$raw"

# 4) Local-only sources (private brain): checkouts + brainstem dirs not on GitHub.
{
  echo ""
  echo "# local-only sources (private brain — never published):"
  for d in "$GH_DIR"/*/; do
    [ -d "$d/.git" ] || continue
    b=$(basename "$d")
    origin=$(git -C "$d" remote get-url origin 2>/dev/null || echo "NO-REMOTE")
    printf "local\t%s\t%s\n" "$b" "$origin"
  done
  for d in "$HOME/.brainstem" "$HOME/.brainstem-soak" "$HOME/.rapp-flight" "$HOME/SecondBrain"; do
    [ -d "$d" ] && printf "local-dir\t%s\n" "$d"
  done
} >> "$PRIV"

echo ""
echo "  ${GRN}public nodes:${RST}  $npub  -> $PUB"
echo "  ${YEL}private nodes:${RST} $npriv -> $PRIV (SEPARATE private location)"
echo "  ${RED}ungoverned public frontier:${RST} $nfrontier public repos NOT in estate-map.json"
echo ""
echo "next: Phase 1 (extract per node). Public extraction reads PUBLIC bytes only."
echo "      Feed atlas/nodes/_census-public.tsv to the extraction fan-out."
echo "      The private census lives in a SEPARATE private repo and never touches this tree."
