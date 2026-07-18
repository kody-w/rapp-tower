#!/bin/bash
# backup-memory.sh — archive the SOLE-COPY brainstem production state that no
# reinstall can regenerate (memories, twins, cubbies, soul, secrets) into
# ~/Backups/rapp-brainstem/. Run before any risky brainstem work, or daily.
set -uo pipefail

DEST_DIR="$HOME/Backups/rapp-brainstem"
STAMP=$(date +%Y%m%d-%H%M%S)
ARCHIVE="$DEST_DIR/brainstem-state-${STAMP}.tar.gz"
KEEP=14

if [ -t 1 ]; then RED=$'\033[31m'; GRN=$'\033[32m'; RST=$'\033[0m'; else RED=""; GRN=""; RST=""; fi

# --- age of previous newest archive (before we add a new one) -------------
prev=$(ls -t "$DEST_DIR"/brainstem-state-*.tar.gz 2>/dev/null | head -1 || true)
if [ -n "$prev" ]; then
    prev_age_s=$(( $(date +%s) - $(stat -f %m "$prev") ))
    prev_age="$(( prev_age_s / 3600 ))h $(( (prev_age_s % 3600) / 60 ))m ago ($(basename "$prev"))"
else
    prev_age="none — this is the first backup"
fi

# --- collect sources (relative to $HOME so the archive is portable) -------
SOURCES=""
missing=""
for rel in \
    ".brainstem/src/rapp_brainstem/.brainstem_data" \
    ".brainstem/twins" \
    ".brainstem/cubbies" \
    ".brainstem/src/rapp_brainstem/soul.md" \
    ".brainstem/src/rapp_brainstem/.env" \
    ".brainstem/src/rapp_brainstem/.copilot_token"
do
    if [ -e "$HOME/$rel" ]; then
        SOURCES="$SOURCES $rel"
    else
        missing="$missing $rel"
    fi
done

if [ -z "$SOURCES" ]; then
    echo "${RED}REFUSE${RST}: no brainstem state found under ~/.brainstem — nothing to back up."
    exit 1
fi

mkdir -p "$DEST_DIR"
chmod 700 "$HOME/Backups" "$DEST_DIR"

# tar reads sources only; never writes into them. shellcheck-style: SOURCES is
# space-safe here (registry paths contain no spaces by construction).
# shellcheck disable=SC2086
if ! tar czf "$ARCHIVE" -C "$HOME" $SOURCES 2>/dev/null; then
    # tar exits nonzero on unreadable files too — keep the archive only if valid
    if ! tar tzf "$ARCHIVE" >/dev/null 2>&1; then
        echo "${RED}FAIL${RST}: tar could not produce a valid archive; removed partial file."
        rm -f "$ARCHIVE"
        exit 1
    fi
fi
chmod 600 "$ARCHIVE"

size=$(du -h "$ARCHIVE" | awk '{print $1}')
files=$(tar tzf "$ARCHIVE" | grep -cv '/$')

# --- prune to the newest $KEEP archives -----------------------------------
pruned=0
for old in $(ls -t "$DEST_DIR"/brainstem-state-*.tar.gz 2>/dev/null | tail -n +$((KEEP + 1))); do
    rm -f "$old" && pruned=$((pruned + 1))
done

printf "%-16s %s\n" "archive"  "$ARCHIVE"
printf "%-16s %s\n" "size"     "$size"
printf "%-16s %s\n" "files"    "$files"
printf "%-16s %s\n" "prev newest" "$prev_age"
[ -n "$missing" ] && printf "%-16s %s\n" "skipped" "(absent)$missing"
[ "$pruned" -gt 0 ] && printf "%-16s %s\n" "pruned" "$pruned old archive(s), keeping newest $KEEP"
echo "${GRN}OK${RST}: sole-copy brainstem state secured."
