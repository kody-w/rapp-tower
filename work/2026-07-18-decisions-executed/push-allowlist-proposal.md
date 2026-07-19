# push-allowlist tightening — proposal (your confirmation needed)

You chose "Tighten it (derive list, I'll confirm)." Here's the derivation and my
honest recommendation.

## The finding restated
`~/.claude/hooks/push-allowlist.txt` line 4 is a bare `github.com/kody-w/`, which
(with the guard's fixed-string match) authorizes pushing to **every** kody-w repo.

## What the data says
In the last 14 days, autonomous + manual sessions pushed to **30+ distinct
kody-w repos** — canary, RAR, the second-brain pair, rapp-train, rapp-roadmap,
rapp-tower, sim-art-collective (the sim loop), rappterverse/rappterbook/openrappter,
and the whole landgrab set (rapp-body/cli/sdk/cortex/spinal-cord/nervous-system…).
The set is large and grows.

## Recommendation: DON'T tighten the repo-allowlist — wire the content gate instead
- The push-allowlist's real job is to stop pushes to **repos that aren't yours**
  (microsoft/*, others) — and the explicit non-kody entries already do that.
- Allowing all `kody-w/*` is defensible: it's a **single-owner namespace**. The
  risk isn't *which* of your repos — it's *what* gets pushed (a secret, a
  customer name). That's a **content** problem, not a location one.
- An explicit repo list would be 30+ entries, need constant maintenance, and a
  single omission **blocks a live autonomous wave** — exactly the failure you
  flagged when you deferred this.
- **The higher-leverage fix (finding #5):** wire `tools/guard.sh` into the push
  path (git-push-guard.sh + the sim loop's push_canvas.sh) so any push carrying a
  secret or denylisted name is blocked *regardless of repo*. That closes the real
  risk without the fragility.

## If you still want the repo-allowlist tightened
Say so and I'll replace line 4 with the explicit ~30-repo set (and you accept the
maintenance + wave-break risk). Otherwise I'll leave the prefix and wire the
content gate — tell me which.
