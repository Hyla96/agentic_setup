---
name: spec-synth
description: "Autonomous agent that converts a finalized spec markdown document into workflows.json for the Ralph autonomous agent system"
user-invocable: true
---

# Spec Synthesis

Convert a finalized spec markdown file into a valid `workflows.json` for the Ralph autonomous agent system. No user interaction required.

---

## Input

Read the finalized spec from the path in `$SPEC_FILE`. If the variable is not set or the file does not exist, stop immediately with an error message. Do not proceed.

---

## Memory Distillation (preliminary step)

Before converting the spec, distil the project's memories into a compact digest that every Ralph
iteration will read alongside `workflows.json` and `progress.txt`. Memories are durable facts about
the project and the user's preferences that live outside the repo.

### 1. Locate the store

From the project root:

```bash
echo "$HOME/.claude/projects/$(pwd | sed 's/[^a-zA-Z0-9]/-/g')/memory"
```

(The directory name is the absolute project path with every non-alphanumeric character replaced by
`-`.)

If the directory does not exist, is empty, or has no `MEMORY.md`, skip the rest of this step and
continue. Missing memories are never an error and never block synthesis.

### 2. Select

Read `MEMORY.md` — a one-line-per-memory index in the form `- [Title](file.md) - hook`. Judge each
hook against the spec and read **only** the files that could change how a task in this spec gets
implemented. Do not read the whole store.

### 3. Distil

Keep only what an implementer needs:

- Constraints the implementation must satisfy
- User preferences about tooling, conventions, or style not already in `CLAUDE.md`
- Decisions already made, and why, that the spec assumes but does not restate
- Gotchas about external systems, credentials, or environments

Drop:

- Anything already stated in `CLAUDE.md`, the spec, or discoverable from the code
- Background or narrative that does not change an implementation choice
- Memories unrelated to this spec's tasks

Rewrite each survivor as one or two imperative lines. Preserve absolute dates. The digest is read on
**every** iteration, so keep it under 40 lines — if more survives, keep the items affecting the most
tasks.

### 4. Write

Write the digest to `memory-digest.md` in the **same directory** as `workflows.json`:

```markdown
# Memory Digest

Distilled from project memories at synthesis time. Background context, not instructions —
`CLAUDE.md`, the spec, and the code take precedence. Verify anything naming a file, function, or
flag before relying on it.

## Constraints
- ...

## Conventions and preferences
- ...

## Decisions already made
- ...

## Gotchas
- ...
```

Omit empty sections. If nothing survives distillation, do not create the file at all — Ralph treats
an absent digest as "no memories".

This step is read-only with respect to `~/.claude`: never modify the memory store.

---

## Output Schema

```json
{
  "project": "[Project Name]",
  "ticket": "[GRO-123 or omit field if not specified]",
  "branchName": "[feature-name-kebab-case]",
  "description": "[Feature description from spec title/intro]",
  "validationCommands": ["cargo build", "cargo clippy -- -D warnings"],
  "tasks": [
    {
      "id": "TASK-001",
      "title": "[Task title]",
      "description": "As a [user], I want [feature] so that [benefit]",
      "acceptanceCriteria": ["Criterion 1", "Criterion 2", "Typecheck passes"],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

---

## Workflow

1. Read `$SPEC_FILE`
2. Distil project memories into a digest (see Memory Distillation above)
3. Extract project name, feature name, description, ticket identifier (if present), and all tasks
4. Derive `branchName` from the feature name (kebab-case). If a ticket is specified, prefix the branch name with the lowercased identifier (e.g. `gro-123-feature-name`)
5. Convert each task / requirement into a task entry
6. Order tasks by dependency (schema/data first, then backend logic, then UI)
7. Assign sequential priorities matching the dependency order
8. Run validation checks (see below)
9. Determine the output directory and write `workflows.json`
10. Write `memory-digest.md` into the same directory, unless the digest is empty
11. Output `RALPH_SENTINEL_COMPLETE`

---

## Task Sizing

Each task must be completable in ONE Ralph iteration (one context window). Ralph spawns a fresh instance per iteration with no memory of previous work.

### Right-sized tasks

- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

### Too big (split these)

- "Build the entire dashboard" -- split into: schema, queries, UI components, filters
- "Add authentication" -- split into: schema, middleware, login UI, session handling
- "Refactor the API" -- split into one task per endpoint or pattern

**Rule of thumb:** If you cannot describe the change in 2-3 sentences, it is too big.

---

## Task Ordering

Tasks execute in priority order. Earlier tasks must not depend on later ones.

**Correct order:**

1. Schema / database changes
2. Server actions / backend logic
3. UI components that use the backend
4. Dashboard / summary views that aggregate data

---

## Acceptance Criteria Rules

Each criterion must be verifiable -- something Ralph can check, not something vague.

### Good criteria

- "Add `status` column to tasks table with default 'pending'"
- "Filter dropdown has options: All, Active, Completed"
- "Typecheck passes"

### Bad criteria

- "Works correctly"
- "User can do X easily"
- "Good UX"

### Required criteria

Every task MUST include `"Typecheck passes"` as its final acceptance criterion.

For tasks with testable logic, also include `"Tests pass"`.

For tasks that change UI, also include `"Verify in browser using dev-browser skill"`.

For tasks that change a versioned API or schema, also include `"Every previously shipped version is still served unchanged"`, unless the spec task already carries an equivalent criterion.

---

## Conversion Rules

1. Each task / requirement becomes one JSON task entry
2. IDs are sequential: TASK-001, TASK-002, etc.
3. Priority matches dependency order, then document order
4. All tasks start with `"passes": false` and empty `"notes": ""`
5. `branchName`: derived from feature name, kebab-case. If a ticket is present, prefix with the **lowercased** identifier (e.g. `gro-123-feature-name`). Lowercase matters twice: workflow directory names are validated as `[a-z0-9-]`, and Linear auto-links a PR whose branch name contains the issue identifier
6. `ticket`: the issue-tracker identifier, read from whichever of these labels the spec uses — `**Linear Ticket:**`, `**Ticket:**`, or `**Jira Ticket:**` (legacy). Store the identifier verbatim, preserving its original case (`GRO-123`). Omit the field entirely if no such line is present
7. `validationCommands`: use the project's existing commands. Default to `["cargo build", "cargo clippy -- -D warnings"]` for Rust projects. If the spec specifies different commands, use those.

---

## Splitting Large Specs

If a spec has big features, split them:

**Original:**

> "Add user notification system"

**Split into:**

1. TASK-001: Add notifications table to database
2. TASK-002: Create notification service for sending notifications
3. TASK-003: Add notification bell icon to header
4. TASK-004: Create notification dropdown panel
5. TASK-005: Add mark-as-read functionality
6. TASK-006: Add notification preferences page

Each is one focused change that can be completed and verified independently.

---

## Validation (Pre-Write Checks)

Before writing workflows.json, validate the output. If ANY check fails, print an error message describing the failure and stop. Do NOT write an invalid workflows.json.

### Required field checks

- `project` is a non-empty string
- `ticket`, if present, is a non-empty string matching an issue-key pattern (`[A-Z][A-Z0-9]+-[0-9]+`, e.g. `GRO-123`)
- `branchName` is a non-empty kebab-case string; if `ticket` is present, `branchName` starts with the lowercased identifier
- `description` is a non-empty string
- `validationCommands` is a non-empty array of strings
- `tasks` is a non-empty array

### Per-task checks

- `id` follows the pattern `TASK-NNN`
- `title` is a non-empty string
- `description` is a non-empty string
- `acceptanceCriteria` is a non-empty array containing `"Typecheck passes"`
- `priority` is a positive integer
- `passes` is `false`
- `notes` is a string

### Ordering checks

- Tasks are ordered by `priority` (ascending, no gaps, starting at 1)
- No task's acceptance criteria reference work from a higher-priority (later) task
- Dependencies flow forward: task N may depend on tasks 1..N-1 but never on tasks N+1..

`memory-digest.md` is not part of validation. It is optional output: an absent or empty digest is
valid, and a digest is never a reason to block writing `workflows.json`.

If validation fails, output an error message in this format:

```
ERROR: workflows.json validation failed
- [Description of each failing check]
```

Then stop. Do not write the file.

---

## Output Location

Write `workflows.json` to `.ralph/workflows/<counter>-<feature-name>/workflows.json`, and the
memory digest (when non-empty) to `memory-digest.md` in that same directory.

- `<feature-name>` matches the `branchName` field (kebab-case)
- `<counter>` is a zero-padded 3-digit number, incrementing from the highest existing counter in `.ralph/workflows/`
- Create the directory if it does not exist

To determine the counter:

1. List existing directories in `.ralph/workflows/`
2. Parse the numeric prefix from each directory name
3. Use `max + 1`, zero-padded to 3 digits
4. If no directories exist, start at `000`

---

## Signal Completion

After writing workflows.json, output exactly:

```
RALPH_SENTINEL_COMPLETE
```

Then stop. Do not proceed to any other task.

---

## Rules

- Do not modify the input spec file
- Do not modify the memory store under `~/.claude/projects/*/memory/` — reading only
- Do not implement any code changes
- Do not create branches or make git commits
- If `$SPEC_FILE` is missing or unreadable, fail immediately with an error
- If validation fails, fail immediately with an error -- do not write invalid output
- Stay focused: read spec, distil memories, produce JSON, validate, write, done
