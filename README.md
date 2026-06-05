# Undrift

Undrift prevents Claude from repeating the same mistakes across sessions.
It mines your past Claude Code session history, detects recurring corrections,
and proposes durable CLAUDE.md rules — so you never have to correct the same
thing twice.

## Skills

| Skill | What it does |
|-------|-------------|
| `/undrift-check` | Quick dashboard — shows session counts across all projects, flags any approaching the 50-session window |
| `/undrift-full` | Deep analysis — mines the last 50 sessions of a project and writes proposed CLAUDE.md rules to `CLAUDE.md.undrift` |

A session-start hook also warns you automatically whenever any project gets
close to the 50-session window, so you never have to think about timing.

## Requirements

- [Claude Code](https://claude.ai/code) installed
- `jq` installed (`sudo apt install jq` or `brew install jq`)
- Bash (macOS and Linux)

## Installation

### 1. Clone and install

```bash
git clone https://github.com/larya-dot-eu/undrift.git
bash undrift/install.sh
```

The script handles everything: creating directories, copying skill files, and wiring the session-start hook.

### 2. Verify

Open a new Claude Code session. Run `/context` and confirm `undrift-check`
and `undrift-full` appear under User skills.

## Usage

**Check session counts across all projects:**
```
/undrift-check
```

**Run full pattern analysis on the current project:**
```
/undrift-full
```

**Run full analysis on a specific project:**
```
/undrift-full ~/path/to/project
```

After `/undrift-full` completes, review `CLAUDE.md.undrift` in your project
root, merge the rules you agree with into `CLAUDE.md`, then delete the file.

## How it works

Session files live in `~/.claude/projects/`. Each session is one `.jsonl`
file. Undrift counts these files per project and, during a full run, spawns
up to 5 parallel subagents to read and extract correction patterns from the
most recent 50 sessions.

Rules are never written directly to `CLAUDE.md` — always to `CLAUDE.md.undrift`
for manual review first.

## Session-start hook

The hook (`scripts/session-check.sh`) runs automatically on every Claude Code
`UserPromptSubmit` event. A 30-minute cooldown stamp prevents it from firing
more than once per session. When any project reaches 45 sessions, it prints:

```
⚠ undrift: my-project has 47 sessions — 3 left before the 50-session window. Run /undrift-full to capture patterns.
```

For projects already past 50 sessions:

```
⚠ undrift: my-project has 63 sessions — 13 past the 50-session window. Run /undrift-full to capture patterns.
```

## File layout

```
undrift/
├── scripts/
│   └── session-check.sh        # Session-start hook
├── skills/
│   ├── undrift-check/
│   │   └── SKILL.md            # /undrift-check skill
│   └── undrift-full/
│       └── SKILL.md            # /undrift-full skill
├── .gitignore
├── install.sh                  # One-command installer
├── LICENSE
└── README.md
```

## Changelog

### v1.0.3 — 2026-06-05

- Security hardening across installer and analysis skill
- Expanded sensitive data protection in `/undrift-full`
- Improved file counting reliability

### v1.0.2 — 2026-06-05

- Fix: `/undrift-check` now displays real filesystem paths (e.g. `~/my-project/sub-folder`) instead of the hyphen-encoded folder names Claude Code uses internally.

### v1.0.1 — 2026-06-05

- Fix: hook now shows `"N past the 50-session window"` for projects that already exceed 50 sessions, instead of the ambiguous `"0 left"` from v1.0.0.

### v1.0.0 — 2026-06-05

- Initial release: `/undrift-check`, `/undrift-full`, and session-start hook.

## License

MIT — see [LICENSE](LICENSE).
