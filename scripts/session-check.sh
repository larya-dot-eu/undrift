#!/bin/bash
# Undrift session-start hook.
# Warns when any Claude Code project is approaching the 50-session analysis window.
# Wired into ~/.claude/settings.json under hooks.UserPromptSubmit.

CACHE_DIR="$HOME/.cache/undrift"
mkdir -p "$CACHE_DIR"
STAMP_FILE="$CACHE_DIR/last_check"

# Suppress if already ran in the last 30 minutes (handles UserPromptSubmit
# firing on every message, not just session start).
if [ -f "$STAMP_FILE" ]; then
  last=$(stat -c %Y "$STAMP_FILE" 2>/dev/null || stat -f %m "$STAMP_FILE" 2>/dev/null)
  now=$(date +%s)
  [ $((now - last)) -lt 1800 ] && exit 0
fi
touch "$STAMP_FILE"

THRESHOLD=45
home_slug=$(echo "$HOME" | tr '/' '-')
home_slug_escaped=$(echo "$home_slug" | sed 's/[.\\[*^$]/\\&/g')

for dir in ~/.claude/projects/*/; do
  [ -d "$dir" ] || continue
  count=$(ls "$dir"*.jsonl 2>/dev/null | wc -l | tr -d ' ')
  if [ "$count" -ge "$THRESHOLD" ]; then
    remaining=$((50 - count))
    name=$(basename "$dir" | sed "s/^${home_slug_escaped}-//")
    if [ "$remaining" -le 0 ]; then
      over=$((-remaining))
      echo "⚠ undrift: $name has $count sessions — $over past the 50-session window. Run /undrift-full to capture patterns."
    else
      echo "⚠ undrift: $name has $count sessions — $remaining left before the 50-session window. Run /undrift-full to capture patterns."
    fi
  fi
done
