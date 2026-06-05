---
name: undrift-full
description: >
  Deep-mines the last 50 sessions of a project to find recurring corrections,
  repeated instructions, and reverted changes. Writes proposed CLAUDE.md rules
  to CLAUDE.md.undrift — review and merge manually. Run when patterns keep
  repeating or after /undrift-check flags a project as needing attention.
agents: [main_agent]
---

# Undrift Full — Session Pattern Mining → CLAUDE.md Rules

You are acting as a **meta-learning agent** for this project. Your mission is
to scan past sessions, extract recurring corrections, and distil them into
durable CLAUDE.md rules — so the same mistakes never have to be corrected twice.

---

## Step 0 — Locate & Scope Sessions

1. Run `pwd` to identify the current project directory
2. If `$ARGUMENTS` is provided, treat it as a path override for the target project
3. **Validate the path:** resolve it to an absolute path and confirm it exists
   inside `~/.claude/projects/`. If it does not match any known project
   directory, stop immediately and tell the user — do not proceed.
4. Locate the matching session directory under `~/.claude/projects/`
5. List all available sessions, sorted by modification date (newest first)
6. Cap scope at the **last 50 sessions**. If fewer than 10 exist, proceed and
   note the limited sample size.
7. Report: *"Found N sessions for [project]. Analysing the most recent 50."*

---

## Step 1 — Parallel Extraction

Spawn **max. 5 parallel subagents**, each processing a batch of ~10 sessions.

Each subagent must extract every instance of the following:

| Signal Type | What to Look For |
|---|---|
| **Explicit corrections** | User said "no", "don't do that", "instead do X", "stop doing Y", "I always have to tell you..." |
| **Reverted changes** | Code or content Claude produced that was immediately undone, rewritten, or replaced |
| **Repeated instructions** | The same instruction or constraint given in 2 or more separate sessions |
| **Re-explained context** | Concepts, project conventions, or constraints the user had to re-state (should have been remembered) |
| **Tone/format corrections** | User adjusted output format, verbosity, language, or structure repeatedly |

For each extracted item, record:
- **Pattern**: A brief description of the recurring behaviour
- **Evidence**: A verbatim or near-verbatim quote from the session
- **Session reference**: Session ID or approximate date
- **Signal type**: Which category above it belongs to

**Credential safety:** before recording any verbatim quote, check it against
common credential patterns (`sk-`, `Bearer `, `ghp_`, `password=`, `key=`,
`token=`, `secret=`). If a match is found, replace the sensitive value with
`[REDACTED]` in the quote. Never write raw credentials into any output file.

---

## Step 2 — Aggregation

1. Merge all subagent findings into a single flat list
2. Deduplicate near-identical patterns — treat variants of the same correction as one pattern
3. Assign a **frequency count** to each pattern (number of distinct sessions it appeared in)
4. Tag each pattern with its dominant theme:
   - `code-structure` | `logic` | `intention` | `output-format` | `file-naming` | `api-usage` | `context` | `tone` | `workflow` | `other`

---

## Step 3 — Filter & Prioritise

Apply the following thresholds:

- ✅ **Include** → patterns appearing in **3 or more** sessions → candidate rules
- ⚠️ **Borderline** → patterns in **exactly 2** sessions → log to REJECTED section, do not propose as rules
- ❌ **Exclude** → one-offs or highly context-specific corrections unlikely to recur

Sort all candidates by frequency descending. Within the same frequency, prioritise patterns that caused significant rework when violated.

---

## Step 4 — Reconcile with Existing Rules

1. Read all `CLAUDE.md` files in the project (root and subfolders)
2. For each candidate rule, determine one of three outcomes:

   - **SKIP** — the rule is already covered by an existing CLAUDE.md entry
   - **NEW** — the rule is genuinely new, no overlap with existing rules
   - **CONFLICT** — the candidate contradicts or partially overlaps an existing rule → flag both for manual review

If no `CLAUDE.md` exists yet, skip this step and note it in the output.

---

## Step 5 — Write Output Files

### File 1: `CLAUDE.md.undrift`

Save to the **project root**. Never write directly to `CLAUDE.md`.

```markdown
## Undrift Proposed Rules — [date] — based on last N sessions

> Review each rule below. When satisfied, manually merge into CLAUDE.md.
> Delete this file after merging.

---

### [Theme Label]

- IMPORTANT: [Rule text]. *(seen N times — e.g. "[verbatim quote]")*
- [Rule text]. *(seen N times — e.g. "[verbatim quote]")*

### [Next Theme Label]

- [Rule text]. *(seen N times — e.g. "[verbatim quote]")*

---

### ⚠️ Conflicts With Existing Rules — Review Manually

- **Candidate:** [proposed rule]
  **Conflicts with:** [existing CLAUDE.md rule]
  **Recommendation:** [brief note on how to reconcile]

---

### ❌ Rejected Patterns (< 3 sessions — not yet rules)

- [Pattern description] *(seen 2 times)*
```

**Formatting rules:**
- Use `IMPORTANT:` prefix for any rule seen **6 or more times**, or that caused significant rework
- One rule per line — a single clear imperative sentence
- Always include the frequency count and one example quote per rule
- Group rules by theme using `###` subheadings

---

### File 2: `CORRECTIONS.log.md`

Append to this file in the project root. Never overwrite it.

```markdown
## Undrift Run — [date]

- Sessions analysed: N
- Candidate patterns found: N
- Rules proposed: N (across N themes)
- Conflicts flagged: N
- Rejected (< 3 sessions): N patterns — [brief list]
```

> `CORRECTIONS.log.md` grows with every run and has no automatic limit.
> It can be safely archived or truncated manually — the skill never reads
> it back, so past entries are for human reference only.

---

## Step 6 — Terminal Summary

```
╔══════════════════════════════════════════╗
║           UNDRIFT — Run Complete         ║
╠══════════════════════════════════════════╣
║  Sessions scanned:     N                 ║
║  Patterns extracted:   N                 ║
║  Rules proposed:       N                 ║
║    └─ by theme:        [theme: N, ...]   ║
║  Conflicts flagged:    N                 ║
║  Patterns rejected:    N                 ║
╠══════════════════════════════════════════╣
║  → Review: CLAUDE.md.undrift             ║
║  → Log:    CORRECTIONS.log.md            ║
║  Merge approved rules into CLAUDE.md,    ║
║  then delete CLAUDE.md.undrift.          ║
╚══════════════════════════════════════════╝
```

---

## Hard Constraints

- **NEVER write directly to `CLAUDE.md`** — always use `CLAUDE.md.undrift`
- **NEVER overwrite `CORRECTIONS.log.md`** — always append
- **NEVER fabricate session content** — only report what is actually in the sessions
- **NEVER write raw credentials into output files** — always redact with `[REDACTED]`
- If a session file is unreadable or corrupted, skip it and note it in the log
- Keep all rule text concise: **one clear imperative sentence per rule**
- Always include exactly **one example quote** per proposed rule so the user can verify Claude's interpretation is correct
