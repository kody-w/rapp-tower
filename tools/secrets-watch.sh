#!/bin/bash
# secrets-watch.sh — ends "alerts fire into a void". GitHub secret-scanning
# already runs on most public repos, but its alerts land in a dashboard nobody
# opens — a leaked Azure key sat open for weeks. This sweeps OPEN
# secret-scanning alerts across every kody-w repo, plus flags any public repo
# with scanning DISABLED (the blind spots). Run it on a schedule; a non-empty
# result is an incident.
set -uo pipefail

RED=""; GRN=""; YEL=""; RST=""
if [ -t 1 ]; then RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; RST=$'\033[0m'; fi

LIMIT="${1:-300}"
echo "sweeping kody-w repos for open secret-scanning alerts + scanning gaps..."
repos=$(gh repo list kody-w --limit "$LIMIT" --json name,visibility,isArchived \
  --jq '.[] | select(.isArchived==false) | [.name,.visibility] | @tsv' 2>/dev/null)
if [ -z "$repos" ]; then echo "${RED}gh repo list failed (auth?)${RST}"; exit 2; fi

alert_total=0; disabled_public=0; scanned=0
ALERTS=""; GAPS=""
while IFS=$'\t' read -r name vis; do
  [ -z "$name" ] && continue
  scanned=$((scanned+1))
  # open alerts (works only where scanning is enabled + token has scope)
  n=$(gh api "repos/kody-w/$name/secret-scanning/alerts?state=open" --jq 'length' 2>/dev/null || echo "NA")
  if [ "$n" = "NA" ]; then
    # scanning disabled or no access. For PUBLIC repos that is itself a gap.
    if [ "$vis" = "public" ]; then
      ppro=$(gh api "repos/kody-w/$name" --jq '.security_and_analysis.secret_scanning.status // "unknown"' 2>/dev/null || echo unknown)
      if [ "$ppro" = "disabled" ]; then disabled_public=$((disabled_public+1)); GAPS="${GAPS}  ${name} (public, scanning DISABLED)\n"; fi
    fi
    continue
  fi
  if [ "$n" -gt 0 ] 2>/dev/null; then
    alert_total=$((alert_total+n))
    det=$(gh api "repos/kody-w/$name/secret-scanning/alerts?state=open" \
      --jq '.[] | "    #\(.number) \(.secret_type_display_name) | opened \(.created_at[0:10]) | \(.html_url)"' 2>/dev/null | head -10)
    ALERTS="${ALERTS}${RED}${name}${RST} [$vis] — ${n} open:\n${det}\n"
  fi
done <<< "$repos"

echo ""
echo "== OPEN SECRET-SCANNING ALERTS =="
if [ "$alert_total" -eq 0 ]; then echo "  ${GRN}none${RST} across $scanned repos"; else printf "$ALERTS"; fi
echo ""
echo "== PUBLIC REPOS WITH SCANNING DISABLED (blind spots) =="
if [ "$disabled_public" -eq 0 ]; then echo "  ${GRN}none${RST}"; else printf "$GAPS"; echo "  fix: gh api -X PATCH repos/kody-w/<name> -f 'security_and_analysis[secret_scanning][status]=enabled' -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled'"; fi
echo ""
echo "scanned $scanned repos · ${alert_total} open alert(s) · ${disabled_public} public blind spot(s)"
[ "$alert_total" -eq 0 ] && [ "$disabled_public" -eq 0 ] && exit 0 || exit 1
