#!/bin/bash
# pages.sh — Pages-live vs origin parity board for the six public surfaces.
# Answers: did the last Pages deploy go green, is the live site current with
# origin HEAD, does each install.sh answer, and (train only) do live bytes
# match the local checkout? Run after pushes, before demos, or on drift-oracle
# suspicion. Rings serve a RENDERED identity — byte-compare is only valid for
# rapp-train; rings/installer are judged by deploy-vs-push recency instead.
set -uo pipefail

RED=""; GRN=""; YEL=""; RST=""
if [ -t 1 ]; then RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; RST=$'\033[0m'; fi

# repo|mode  — workflow: Pages deployed by publish-pages.yml (rendered ring
# identity); legacy: classic branch-built Pages (pages/builds API).
SURFACES=(
  "rapp-train|legacy"
  "rapp-canary|workflow"
  "rapp-nightly|workflow"
  "rapp-alpha|workflow"
  "rapp-beta|workflow"
  "rapp-installer|legacy"
)

printf "%-15s %-13s %-9s %-9s %-11s %s\n" "SURFACE" "PAGES" "DEPLOYED" "PUSHED" "INSTALL.SH" "NOTES"

for entry in "${SURFACES[@]}"; do
    repo="${entry%%|*}"; mode="${entry##*|}"

    head_json=$(gh api "repos/kody-w/$repo/commits/HEAD" 2>/dev/null || echo '{}')
    if [ "$mode" = "workflow" ]; then
        deploy_json=$(gh api "repos/kody-w/$repo/actions/workflows/publish-pages.yml/runs?per_page=1" 2>/dev/null || echo '{}')
    else
        deploy_json=$(gh api "repos/kody-w/$repo/pages/builds/latest" 2>/dev/null || echo '{}')
    fi

    line=$(HEAD_JSON="$head_json" DEPLOY_JSON="$deploy_json" MODE="$mode" REPO="$repo" python3 <<'PY'
import json, os, sys
from datetime import datetime, timezone

def ts(s):
    if not s: return None
    return datetime.fromisoformat(s.replace("Z", "+00:00"))

def rel(t):
    if t is None: return "?"
    s = int((datetime.now(timezone.utc) - t).total_seconds())
    if s < 0: s = 0
    if s < 3600: return "%dm" % (s // 60)
    if s < 172800: return "%dh" % (s // 3600)
    return "%dd" % (s // 86400)

def gap(a, b):  # a-b as human gap
    s = int((a - b).total_seconds())
    if s < 3600: return "%dm" % (s // 60)
    if s < 172800: return "%dh" % (s // 3600)
    return "%dd" % (s // 86400)

head = json.loads(os.environ["HEAD_JSON"] or "{}")
dep  = json.loads(os.environ["DEPLOY_JSON"] or "{}")
mode, repo = os.environ["MODE"], os.environ["REPO"]

push_sha = head.get("sha") or ""
push_t   = ts((head.get("commit") or {}).get("committer", {}).get("date"))

verdict, dep_t, note = "API-FAIL", None, "commits/HEAD unreadable"
if push_t:
    if mode == "workflow":
        runs = dep.get("workflow_runs") or []
        if not runs:
            verdict, note = "NO-DEPLOY", "no publish-pages.yml runs found"
        else:
            r = runs[0]
            dep_t = ts(r.get("updated_at") or r.get("created_at"))
            if r.get("status") != "completed":
                verdict, note = "DEPLOYING", r.get("html_url", "")
            elif r.get("conclusion") != "success":
                verdict = "DEPLOY-RED"
                note = "%s -> %s" % (r.get("conclusion"), r.get("html_url", ""))
            elif r.get("head_sha") == push_sha or (dep_t and dep_t >= push_t):
                verdict, note = "LIVE-CURRENT", ""
            else:
                verdict = "LIVE-BEHIND"
                note = "push %s newer than deploy (%s)" % (gap(push_t, dep_t), r.get("html_url", ""))
    else:
        status = dep.get("status")
        dep_t  = ts(dep.get("created_at"))
        if status is None:
            verdict, note = "NO-DEPLOY", "pages/builds/latest: not found"
        elif status == "errored":
            verdict = "DEPLOY-RED"
            msg = (dep.get("error") or {}).get("message") or "build errored"
            note = "%s -> https://github.com/kody-w/%s/actions" % (msg, repo)
        elif status != "built":
            verdict, note = "DEPLOYING", "pages build status: %s" % status
        elif dep.get("commit") == push_sha or (dep_t and dep_t >= push_t):
            verdict, note = "LIVE-CURRENT", ""
        else:
            verdict = "LIVE-BEHIND"
            note = "push %s newer than deploy" % gap(push_t, dep_t)

print("%s\t%s\t%s\t%s" % (verdict, rel(dep_t), rel(push_t), note))
PY
)
    verdict=$(printf '%s' "$line" | cut -f1)
    dep_rel=$(printf '%s' "$line" | cut -f2)
    push_rel=$(printf '%s' "$line" | cut -f3)
    note=$(printf '%s' "$line" | cut -f4)

    # install.sh liveness (rings + installer publish one; train does not)
    inst="-"
    if [ "$repo" != "rapp-train" ]; then
        inst=$(curl -sI -o /dev/null -m 15 -w '%{http_code}' "https://kody-w.github.io/$repo/install.sh" 2>/dev/null || echo "curl-fail")
    fi

    # train only: byte-parity of live vs local clean checkout (no identity rewrite)
    if [ "$repo" = "rapp-train" ]; then
        parity=""
        for f in llms.txt PLAYBOOK.md; do
            live=$(curl -fsSL -m 20 "https://kody-w.github.io/rapp-train/$f" 2>/dev/null | shasum -a 256 | cut -d' ' -f1)
            loc=$(shasum -a 256 "$HOME/Documents/GitHub/rapp-train/$f" 2>/dev/null | cut -d' ' -f1)
            if [ -z "$loc" ]; then parity="$parity $f=NO-LOCAL"
            elif [ "$live" = "$loc" ]; then parity="$parity $f=MATCH"
            else parity="$parity $f=${RED}DIFFER${RST}"
            fi
        done
        note="bytes:${parity}${note:+ · $note}"
    fi

    # colorize (pad before coloring so ANSI codes don't break columns)
    vp=$(printf '%-13s' "$verdict")
    case "$verdict" in
        LIVE-CURRENT) vp="${GRN}${vp}${RST}" ;;
        DEPLOY-RED|API-FAIL|NO-DEPLOY) vp="${RED}${vp}${RST}" ;;
        LIVE-BEHIND|DEPLOYING) vp="${YEL}${vp}${RST}" ;;
    esac
    ip=$(printf '%-11s' "$inst")
    case "$inst" in
        200|-) : ;;
        *) ip="${RED}${ip}${RST}" ;;
    esac

    printf "%-15s %s %-9s %-9s %s %s\n" "$repo" "$vp" "$dep_rel" "$push_rel" "$ip" "$note"
done

echo ""
echo "rings serve RENDERED identity (publish-pages.yml rewrites grail->ring): byte-compare valid for rapp-train only."
