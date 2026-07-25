# Cleanup task — `microsoft/aibast-agents-library`

**Paste this whole file to Copilot on a branch of `microsoft/aibast-agents-library`.**

Goal: remove the deprecated Local-First Chat Animation Studio tooling and its
large captured asset, fix the links that pointed at it, and tidy tracked macOS
junk. No functional agent code changes.

Verified against `main` at clone time: 270 tracked files, 37 MB working tree.
Every step below was dry-run end to end before this doc was written; the
numbers in the verification section are measured, not estimated.

---

## 1. Remove the deprecated capture tooling

The **Local-First Chat Animation Studio** is a deprecated M365 Copilot screen
capture tool that no longer works. It ships with a 29.2 MB captured page
snapshot used only as a static backdrop.

Delete:

```
tools/localfirst_chat_animation_studio_tool.html
tools/tool_assets/snapshot-1760370929454.html
```

Then remove the now-empty directory:

```
tools/tool_assets/
```

**Why the asset goes too:** `tools/tool_assets/snapshot-1760370929454.html` is
**29.2 MB — roughly 79% of the entire repository's 37 MB**. It is a saved DOM
capture of a signed-in session, so it also carries stale account identifiers and
directory GUIDs that serve no purpose in a samples repo. Nothing loads it at
runtime; the only in-tool reference is a hardcoded status string.

**Do not** delete `tools/localfirst_project_tracker_tool.html` — that is a
separate, working tool (*Local Project Tracker Tool - AI Agent
Implementations*). Keep it.

## 2. Fix the four references that would become dead links

`docs/rapp-guide.html` links the removed tool in **four** places. Removing the
file without these edits leaves broken links in the published guide.

Remove or update each:

| Line (approx) | What is there |
|---|---|
| ~3765 | `<p><strong>Local Tool:</strong> <a href="../tools/localfirst_chat_animation_studio_tool.html" …>Open Local-First Chat Animation Studio</a></p>` |
| ~4094 | `<pre><code>1. Open ../tools/localfirst_chat_animation_studio_tool.html in your browser` |
| ~4778 | `<li>Local-First Chat Animation Studio (../tools/localfirst_chat_animation_studio_tool.html)</li>` |
| ~5401 | `onclick="window.open('../tools/localfirst_chat_animation_studio_tool.html', '_blank')"` |

Guidance: delete the surrounding list item / paragraph / button entirely rather
than leaving an empty element or a dangling label. If a numbered step list is
renumbered by the removal, renumber it. Search the file for
`localfirst_chat_animation_studio` afterwards and confirm zero matches.

## 3. Remove tracked macOS junk

Two `.DS_Store` files are tracked:

```
.DS_Store
tools/.DS_Store
```

Delete both (`git rm --cached` then delete on disk, or just `git rm`).

## 4. Extend `.gitignore`

The current `.gitignore` (12 lines) does not cover macOS junk or captured
assets. Append:

```gitignore

# macOS
.DS_Store

# Captured page/session snapshots — large, stale, and never loaded at runtime
tools/tool_assets/
snapshot-*.html
*.har
```

Leave every existing line as-is. In particular keep `rapp_brainstem/.env` —
and note `rapp_brainstem/.env.example` is a template that **should** stay
tracked.

---

## Verification (run before opening the PR)

These are the exact numbers from a dry run of this task against `main`.

```bash
# 1. no references remain
grep -rn "localfirst_chat_animation_studio" . --exclude-dir=.git    # expect: 0 lines
grep -rn "snapshot-1760370929454"           . --exclude-dir=.git    # expect: 0 lines
grep -rn "tool_assets" . --exclude-dir=.git --exclude=.gitignore    # expect: 0 lines
#   NOTE: exclude .gitignore — the new ignore rule legitimately contains
#   "tools/tool_assets/", so an unfiltered grep returns 1 and looks like a miss.

# 2. junk is gone
git ls-files | grep -c "\.DS_Store"                                 # expect: 0

# 3. the kept tool is untouched
test -f tools/localfirst_project_tracker_tool.html && echo "project tracker kept"

# 4. size dropped
du -sh .          # expect: 7.4 MB   (was 37 MB)
git ls-files | wc -l   # expect: 266  (was 270)

# 5. the guide has no empty leftovers from the link removals
grep -c '<a href=""' docs/rapp-guide.html                           # expect: 0
```

---

## Suggested PR description

> **Remove deprecated Chat Animation Studio tooling and its captured asset**
>
> The Local-First Chat Animation Studio is a deprecated M365 Copilot screen
> capture tool that no longer functions. Its only asset,
> `tools/tool_assets/snapshot-1760370929454.html`, is a 29.2 MB saved DOM
> capture — about 79% of the repository's total size — and is not loaded at
> runtime.
>
> - removes the tool and its asset
> - updates the four links in `docs/rapp-guide.html` that pointed at it
> - drops two tracked `.DS_Store` files and gitignores macOS junk and captured
>   snapshots
>
> `tools/localfirst_project_tracker_tool.html` is unaffected. No agent code
> changes. Repository working tree drops from 37 MB to 7.4 MB (270 -> 266 tracked files).

---

## Note on history (optional, separate decision)

Deleting the file removes it from `main`, but the 29.2 MB blob stays reachable
in git history, so **fresh clones will not get smaller** and the old content is
still retrievable by commit SHA. If the size reduction is the point, that needs
a history rewrite (`git filter-repo`), which is a force-push and a separate
conversation with the repo owners. The deletion above is worth doing either
way.
