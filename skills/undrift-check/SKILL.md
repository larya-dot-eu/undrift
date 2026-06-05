---
name: undrift-check
description: >
  Quick cross-project session dashboard. Shows how many Claude Code sessions
  exist for every project and flags ones approaching the 50-session analysis
  window. Run this for an at-a-glance view before deciding whether to run
  /undrift-full. No file writes, no subagents, minimal tokens.
---

# Undrift Check — Session Count Dashboard

Run this for a quick overview of session counts across all your Claude Code projects.

## Steps

### 1. Count sessions

Run:

```bash
resolve_path() {
  local encoded="$1"
  local base="$HOME"
  local result="~"
  local rest="$encoded"
  while [ -n "$rest" ]; do
    local matched=0
    local i=${#rest}
    while [ $i -ge 1 ]; do
      local seg="${rest:0:$i}"
      if [ -d "$base/$seg" ]; then
        result="$result/$seg"
        base="$base/$seg"
        rest="${rest:$i}"
        [ "${rest:0:1}" = "-" ] && rest="${rest:1}"
        matched=1
        break
      fi
      i=$((i - 1))
    done
    [ $matched -eq 0 ] && { result="$result/${rest#-}"; break; }
  done
  echo "$result"
}

home_slug=$(echo "$HOME" | tr '/' '-')
home_slug_escaped=$(echo "$home_slug" | sed 's/[.\\[*^$]/\\&/g')
for dir in ~/.claude/projects/*/; do
  [ -d "$dir" ] || continue
  count=$(find "$dir" -maxdepth 1 -name "*.jsonl" 2>/dev/null | wc -l | tr -d ' ')
  encoded=$(basename "$dir" | sed "s/^${home_slug_escaped}-//")
  name=$(resolve_path "$encoded")
  echo "$count $name"
done | sort -rn
```

### 2. Format and display

Present the results as a table sorted by session count descending. Compute
the status tier for each row:

- `✓ fine` — fewer than 40 sessions
- `⚠ getting close` — 40–44 sessions
- `🔴 run now` — 45 or more sessions (append remaining count)

Example:

```
Project                    Sessions   Status
─────────────────────────────────────────────
GitHubReps/pmcontext       47         🔴 run now  (3 remaining)
GitHubReps/seo-dash        44         ⚠ getting close
GitHubReps/linkedin        12         ✓ fine
GitHubReps/undrift          1         ✓ fine
```

### 3. Closing prompt

If any projects are 🔴, end with one line per flagged project:

```
→ Run /undrift-full on [project-name] to capture patterns.
```

If no projects exist yet, say: "No Claude Code project sessions found."

## Hard Constraints

- No file writes of any kind
- No subagents
- No CLAUDE.md modifications
- Read-only operation
