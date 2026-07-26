#!/usr/bin/env bash
# Publish the four submissions ONE AT A TIME, end to end.
#
# staging/_pending.json is a single shared file, and each workflow run checks
# out main at its own start. Editing four issues at once made four Process runs
# race: the last writer won and the other three items vanished, so their Approve
# runs found nothing to promote. Two of them still reported "✅ Approved and
# promoted" and closed the issue. Serialising each issue through BOTH phases is
# the only safe sequence against that design.
set -uo pipefail
REPO=kody-w/RAPP_Store

wait_run() {  # wait_run <workflow-name>
  local wf="$1" st
  for _ in $(seq 1 60); do
    sleep 7
    st=$(gh run list --repo "$REPO" --limit 1 --workflow "$wf" 2>/dev/null | awk '{print $1" "$2}')
    case "$st" in completed*) echo "$st"; return 0 ;; esac
  done
  echo "TIMEOUT"; return 1
}

listed() {
  gh api "repos/$REPO/contents/index.json" --jq .content 2>/dev/null | base64 -d | python3 -c "
import json,sys
d=json.load(sys.stdin); items=d if isinstance(d,list) else d.get('rapplications') or d.get('items') or []
want={'rapp_shot','rapp_voice','rapp_crispy','rapp_rewind'}
print(' '.join(sorted(f\"{i['id']}@{i.get('version')}\" for i in items if i.get('id') in want)))"
}

for n in "$@"; do
  echo "===== issue #$n"
  gh issue reopen "$n" --repo "$REPO" >/dev/null 2>&1
  gh issue edit "$n" --repo "$REPO" --remove-label approved --remove-label promoted >/dev/null 2>&1

  # 1. re-stage: an edit re-runs Process, which re-adds this issue to _pending
  gh issue view "$n" --repo "$REPO" --json body -q .body > "/tmp/pub-$n.md"
  printf '\n<!-- serial publish %s -->\n' "$(date +%s)" >> "/tmp/pub-$n.md"
  gh issue edit "$n" --repo "$REPO" --body-file "/tmp/pub-$n.md" >/dev/null
  echo "  process:  $(wait_run 'Process rapplication submission')"

  # 2. confirm the item is actually staged before approving
  sleep 5
  staged=$(gh api "repos/$REPO/contents/staging/_pending.json" --jq .content 2>/dev/null | base64 -d \
    | python3 -c "import json,sys;print(','.join(str(i.get('issue')) for i in json.load(sys.stdin).get('items',[])))")
  echo "  staged:   [$staged]"
  case ",$staged," in
    *",$n,"*) ;;
    *) echo "  SKIP — #$n is not staged; approving would report a promotion that cannot happen"; continue ;;
  esac

  # 3. approve
  gh issue edit "$n" --repo "$REPO" --add-label approved >/dev/null 2>&1
  echo "  approve:  $(wait_run 'Approve rapplication submission')"
  sleep 6

  # 4. verify against the catalogue, not against the workflow's own claim
  verdict=$(gh issue view "$n" --repo "$REPO" --json comments -q '.comments[-1].body' | head -1)
  echo "  report:   $verdict"
  echo "  catalog:  $(listed)"
done
