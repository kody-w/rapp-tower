#!/bin/bash
# train.sh — the train-position board: where every ring's tip is (local vs origin),
# its VERSION, its promotion-lock source, and whether the newest archived
# qualification run attested the commit origin currently serves. Run before any
# promote/qualify decision, or whenever you need to know where the train is.
set -uo pipefail

RINGS=(
  "canary|$HOME/Documents/GitHub/rapp-canary"
  "nightly|$HOME/Documents/GitHub/rapp-nightly"
  "alpha|$HOME/Documents/GitHub/rapp-alpha"
  "beta|$HOME/Documents/GitHub/rapp-beta"
  "grail|$HOME/.brainstem/src"
)
ATTN_ROOT="$HOME/Documents/GitHub/rapp-canary/.ring/attestations"

if [ -t 1 ]; then RED=$'\033[31m'; GRN=$'\033[32m'; RST=$'\033[0m'; else RED=""; GRN=""; RST=""; fi

# One python3 pass over all JSON: newest run (by archived_at) + its per-ring
# attested commits, plus each promotion target's upstream.lock source commit.
FACTS=$(python3 - "$ATTN_ROOT" "$HOME" <<'PYEOF'
import glob, json, os, sys
from datetime import datetime, timezone
attn_root, home = sys.argv[1], sys.argv[2]

runs = []
for rj in glob.glob(os.path.join(attn_root, "run-*", "RUN.json")):
    try:
        d = json.load(open(rj))
        runs.append((d.get("archived_at", ""), d.get("run_id", "?"), os.path.dirname(rj)))
    except Exception:
        pass
runs.sort()
if runs:
    archived_at, run_id, run_dir = runs[-1]
    age = "?"
    try:
        ts = datetime.fromisoformat(archived_at.replace("Z", "+00:00"))
        age = "%.1f" % ((datetime.now(timezone.utc) - ts).total_seconds() / 86400)
    except Exception:
        pass
    print("RUN %s %s" % (run_id, age))
    for f in glob.glob(os.path.join(run_dir, "*", "*.json")):
        try:
            d = json.load(open(f))
            ring, commit = d.get("ring"), (d.get("payload") or {}).get("commit")
            if ring and commit:
                print("ATTN %s %s %s" % (ring, commit, d.get("result", "?")))
        except Exception:
            pass
else:
    print("RUN none ?")

for ring in ("nightly", "alpha", "beta"):
    lock = os.path.join(home, "Documents/GitHub/rapp-%s" % ring, ".ring", "upstream.lock.json")
    try:
        d = json.load(open(lock))
        print("LOCK %s %s" % (ring, (d.get("source") or {}).get("commit", "?")))
    except Exception:
        pass
PYEOF
)

run_line=$(printf '%s\n' "$FACTS" | grep '^RUN ' | head -1)
run_id=$(printf '%s' "$run_line" | awk '{print $2}')
run_age=$(printf '%s' "$run_line" | awk '{print $3}')

printf "%-8s %-32s %-8s %-9s %-7s %-9s %-10s %s\n" \
  "RING" "CHECKOUT" "LOCAL" "ORIGIN" "VER" "LOCK-SRC" "ATTESTED" "VERDICT"

beta_ver="?"; grail_ver="?"
for entry in "${RINGS[@]}"; do
    ring="${entry%%|*}"; path="${entry##*|}"
    name="~${path#"$HOME"}"
    if [ ! -d "$path/.git" ]; then
        printf "%-8s %-32s %s\n" "$ring" "$name" "missing checkout"
        continue
    fi
    local_tip=$(git -C "$path" rev-parse --short=7 main 2>/dev/null || echo "?")
    origin_full=$(git -C "$path" ls-remote origin main 2>/dev/null | awk '{print $1}')
    origin_tip="${origin_full:0:7}"; [ -n "$origin_tip" ] || origin_tip="?"
    origin_disp="$origin_tip"
    if [ "$origin_tip" != "?" ] && [ "$local_tip" != "$origin_tip" ]; then
        origin_disp="${RED}${origin_tip}!${RST}"
    fi
    ver=$(head -1 "$path/rapp_brainstem/VERSION" 2>/dev/null || echo "?")
    [ "$ring" = "beta" ] && beta_ver="$ver"
    [ "$ring" = "grail" ] && grail_ver="$ver"
    lock=$(printf '%s\n' "$FACTS" | awk -v r="$ring" '$1=="LOCK" && $2==r {print substr($3,1,7)}')
    [ -n "$lock" ] || lock="-"
    attn_full=$(printf '%s\n' "$FACTS" | awk -v r="$ring" '$1=="ATTN" && $2==r {print $3}')
    attn="${attn_full:0:7}"
    if [ -z "$attn_full" ]; then
        attn="-"; verdict="NO-ATTN"
    elif [ "$origin_tip" = "?" ]; then
        verdict="ORIGIN?"
    elif [ "$attn_full" = "$origin_full" ]; then
        verdict="${GRN}ATTESTED${RST}"
    else
        verdict="${RED}MOVED${RST}"
    fi
    # pad manually: ANSI codes break printf width math
    printf "%-8s %-32s %-8s %-9b %-7s %-9s %-10s %b\n" \
      "$ring" "$name" "$local_tip" "$origin_disp" "$ver" "$lock" "$attn" "$verdict"
done

echo ""
if [ "$grail_ver" = "$beta_ver" ]; then
    echo "grail VERSION $grail_ver == beta VERSION $beta_ver ${GRN}(in step)${RST}"
else
    echo "grail VERSION $grail_ver != beta VERSION $beta_ver ${RED}(grail behind/ahead of beta)${RST}"
fi
echo "newest qualification run: ${run_id} (${run_age}d old)"
