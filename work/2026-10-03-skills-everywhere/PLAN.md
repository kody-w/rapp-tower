# Skills everywhere: share a skill, run an agent

Status: plan, not built. 2026-10-03. Grail untouched throughout.

## The one idea

- **agent.py is what runs.** Brainstem → basic_agent.py → agent.py. That story doesn't change, and no new base class is added.
- **SKILL.md is how it travels.** It's a document anyone can read and any AI tool understands. It carries the agent.py inside it,
  in plain view with its sha256. Nothing runs until someone says yes.
- `rapp-skills` already makes and reverses this wrapper losslessly (`to-skill`, `to-agent`, `prove`).
  The `.txt` idea, done with a standard every tool already reads.

The whole thing rests on one rule: **read live, run pinned.** Instructions are read from wherever they live,
always current. Code runs only from the exact bytes you approved.

## What already exists (verified on disk)

| Piece | Where | Does |
|---|---|---|
| Wrapper format + converter | `kody-w/rapp-skills` | agent.py ⇄ SKILL.md, byte-lossless, `prove` |
| Where each AI tool keeps skills | `rapp-skills/hosts/*.json` | Claude Code, Copilot CLI paths, agents dirs, manifests |
| Skills library | `rapp-brainstem-skills` `agents/optional/skills_agent.py` | instruction skills, loaded only when used, `/name` |
| One-time import | `agent_config_import_agent.py` | copies `~/.claude`, `~/.codex` skills, commands, CLAUDE.md |
| Slash commands | `chat_shortcuts_agent.py` | `/name` → prompt with `{args}` |
| Child agents | `delegate_agent.py` | one focused task, fresh context |
| Brainstem inside Claude Code | `kody-w/brainstem-mcp` | Claude Code → brainstem over MCP |
| RAR in Claude Code | `rar` marketplace (`rapp@rar` 1.3.0) | ships the rapp-skills skill |

The gaps are reading skills **live** instead of copying once, running **skills that carry code**,
**plugins** as a whole, and **MCP servers** from plugins.

## How each part of the ecosystem maps (the plugins question)

A Claude Code plugin is a folder of parts. Each part has a home in the brainstem, and none needs the kernel.

| Plugin part | Seen in | Brainstem home | Phase |
|---|---|---|---|
| `skills/*/SKILL.md` (instructions) | chatcut, skill-creator, codex | Skills library, read live | 1 |
| `skills/*/SKILL.md` carrying agent.py | rapp-skills, RAR | installed on your yes, pinned | 2 |
| `commands/*.md` | ralph-wiggum, codex, brainstem-mcp | chat shortcuts, read live | 3 |
| `agents/*.md` (subagents: prompt, tools, model) | codex, copilot-studio | Delegate runs it as a child with that prompt | 3 |
| `.mcp.json` (MCP servers) | brainstem-mcp | MCP sidecar: holds the servers, brainstem calls their tools | 4 |
| `hooks/hooks.json` | ralph-wiggum, codex, copilot-studio | **not carried**; the kernel has no events to hook. Listed honestly per plugin | later sidecar |
| LSP servers | clangd, swift | not applicable (code editors) | never |
| marketplace.json | every marketplace | RAR *is* RAPP's marketplace; it serves one | 5 |

Every plugin gets one plain report: *what came with it, what works here, what doesn't and why.*

Other tools come in through the same door: Copilot CLI, Codex and OpenClaw paths come from `hosts/*.json`.
Supporting a new AI tool means adding one file there, not code.

## Phases

### 1. Your skills, live, in the brainstem
- Extend the **Skills organ** (no new organ, no new word) with *sources*: the folders in `hosts/*.json`,
  plus the skills dirs of installed Claude Code plugins (`~/.claude/plugins/installed_plugins.json` → `installPath/skills`).
- Read in place on each turn, cached by mtime like ProjectContext. Only names and descriptions go into the prompt.
- Each skill gets a fit label:
  - **works here**
  - **instructions only** (it expects a tool the brainstem lacks, e.g. Bash in `allowed-tools`)
  - **carries code: install to use**
- Duplicates resolve by precedence: brainstem's own, then project, then user, then plugin. Shadowed ones are reported, never silently dropped.
- **Decision for you:** the Skills organ is on the shelf (off by default). The demo is "zero steps", so it
  has to be on. I'll measure its per-request cost against the ≤5s gate and turn it on only if it passes.

### 2. Skills that carry code
- A SKILL.md with an embedded agent.py shows in chat: *"deal-review contains code that does X. Install it?"*
- On your yes it checks the sha, then writes the agent.py to `.brainstem_data/skills/<name>/agent.py`.
  That copy is pinned: if the source changes, it asks again.
- The organ host presents installed code skills **lazily** (catalog schema, module loaded only when used),
  so ten installed skills don't cost ten tool schemas up front.
- On a stock grail brainstem (not this distro), the same file still works the plain way:
  `rapp_skills to-agent` → drop agent.py into `agents/`.

### 3. Plugins as a whole
- Commands are read live as shortcuts, and `$ARGUMENTS` maps to `{args}`.
- Subagents are run by Delegate as a child with the subagent's prompt. `model` maps to the closest brainstem model.
  `tools` the brainstem lacks are reported.
- A "plugins" view in chat: each installed plugin and its report card (see the mapping table).

### 4. MCP servers (route 2, sidecar)
- The kernel re-runs agent files each request and is stateless, so it can't hold MCP connections.
  A sidecar like `brainstem-mcp` (the other direction) starts the servers a plugin declares. It starts them only after your yes,
  and one agent file exposes their tools through it.
- This is the largest ecosystem surface, so it gets its own plan before building.

### 5. Outward: RAR is a marketplace
- Every RAR agent is published as a SKILL.md alongside its agent.py, and RAR serves a marketplace any
  tool can add. Start from the existing `rar` marketplace and check what it already serves before adding.

## Not doing
- No `basic_skill.py` and no new base class. A skill is packaging, not a kind of agent.
- No kernel edits, and nothing routed through the grail's release train.
- No auto-running code, ever. Instructions are read live; code waits for your yes.
- No copying `~/.claude` wholesale. The existing one-time import stays for people who want a snapshot.

## Proof that decides it (done = these pass live, pushed, on a port checked free first)
1. **Share:** email yourself a RAR agent as SKILL.md, read it in the mail client, drop it in, say yes, use it.
2. **Ecosystem:** install a public Claude Code plugin, and use its skill in the very next brainstem chat with zero steps.
3. **Round trip:** the installed agent.py is byte-identical to the source (`prove` PASS).
4. **Honesty:** the plugin report says correctly what didn't come along (hooks, LSP).
5. **Speed:** first answered message ≤5s with every source mounted.

Sol REFUTE-reviews each phase's diff before it ships.

## Session note (2026-10-03): FR-6 slip
While prototyping (since discarded), a test brainstem was started on :7099 without checking the port first.
That port was already held by a launchd-managed brainstem from `~/.brainstem/src`. The test server failed to bind,
and cleanup then killed the existing one (pid 26899). launchd restarted it within seconds (pid 66883, `/health` ok,
v0.6.16). No state touched. Rule reaffirmed: check that a port is free before starting a test server, and never
kill a listener you didn't start.
