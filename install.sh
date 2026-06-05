#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Undrift..."

# Check dependencies
if ! command -v jq &>/dev/null; then
  echo ""
  echo "Error: jq is required but not installed."
  echo "  macOS:  brew install jq"
  echo "  Linux:  sudo apt install jq"
  exit 1
fi

# Create skill directories
mkdir -p ~/.claude/skills/undrift-check
mkdir -p ~/.claude/skills/undrift-full
mkdir -p ~/.claude/skills/undrift/scripts

# Copy skill files
cp "$REPO_DIR/skills/undrift-check/SKILL.md" ~/.claude/skills/undrift-check/SKILL.md
cp "$REPO_DIR/skills/undrift-full/SKILL.md"  ~/.claude/skills/undrift-full/SKILL.md
cp "$REPO_DIR/scripts/session-check.sh"      ~/.claude/skills/undrift/scripts/session-check.sh
chmod +x ~/.claude/skills/undrift/scripts/session-check.sh

# Create settings.json if it doesn't exist
[ -f ~/.claude/settings.json ] || echo '{}' > ~/.claude/settings.json

# Wire hook (skip if already present)
if grep -q "session-check.sh" ~/.claude/settings.json; then
  echo "Hook already present, skipping."
else
  jq '.hooks.UserPromptSubmit += [{"matcher": "", "hooks": [{"type": "command", "command": "bash ~/.claude/skills/undrift/scripts/session-check.sh"}]}]' \
    ~/.claude/settings.json > /tmp/undrift_settings_tmp.json \
    && mv /tmp/undrift_settings_tmp.json ~/.claude/settings.json
fi

echo ""
echo "✓ Undrift installed successfully."
echo ""
echo "  /undrift-check   — session count dashboard"
echo "  /undrift-full    — deep pattern analysis"
echo ""
echo "Open a new Claude Code session to activate."
