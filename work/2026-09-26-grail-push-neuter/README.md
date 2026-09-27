# 2026-09-26 — Re-neuter the production Brainstem checkout

- **Decision**: Keep `/Users/kodywildfeuer/.brainstem/src` unable to push by setting its `origin` push URL to `DISABLED-push-to-grail-is-a-conscious-release-act-see-rapp-canary-.ring-RUNBOOK`.
- **Why**: During Codex Brainstem setup, `tools/checkouts.sh` raised `GRAIL PUSH ENABLED`. The checkout's fetch and push URLs both pointed at `https://github.com/microsoft/aibast-agents-library.git`, which violates FR-2 and the standing prohibition on pushes to `microsoft/*`.
- **Reversal condition**: Do not reverse this in the production checkout. Any conscious release must use the train's isolated, human-gated release path.
- **Evidence**: At 2026-09-26 20:33 EDT, `git remote -v` showed the Microsoft URL for fetch and push. `git log origin/main..HEAD` returned no commits, and this session executed no push. After `git remote set-url --push`, `tools/checkouts.sh` reported `grail push: neutered`.

The checkout already contained unrelated tracked and untracked runtime changes; none were modified or committed as part of this response.
