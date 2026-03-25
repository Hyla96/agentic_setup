# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

This is a Claude Code customization repository containing **agent definitions** and **skill definitions** that extend Claude Code's capabilities. It is not a traditional software project — there is no build system, no tests, and no application code. The repo consists entirely of markdown configuration files.

## Structure

- `agents/` — Subagent definitions (markdown files with YAML frontmatter). Each file defines a specialized agent that can be spawned via the `Agent` tool with `subagent_type` matching the file's `name` field.
- `skills/` — Skill definitions (each skill is a directory containing a `SKILL.md` file). User-invocable skills are triggered via `/skill-name` slash commands.

## Agent Definition Format

Each agent `.md` file uses this frontmatter schema:

```yaml
---
name: agent-name          # Used as subagent_type when spawning
description: "..."        # Shown in agent picker; describes when to use
model: opus|sonnet|haiku  # Which Claude model to use
color: blue               # Optional: color tag
tools: Read, Edit, ...    # Comma-separated tool access list
---
```

The body contains the agent's system prompt and behavioral instructions.

## Skill Definition Format

Each skill lives in `skills/<name>/SKILL.md` with frontmatter:

```yaml
---
name: skill-name
description: "..."
user-invocable: true|false  # Whether users can trigger via /skill-name
---
```

## Key Workflows

### Ralph Autonomous Agent System

Ralph (`agents/ralph.md`) is the core autonomous coding agent. It works with:
- `workflows.json` — Task definitions produced by `spec-synth` or `prd-synth` agents
- `progress.txt` — Tracks completion state
- A shared feature branch (one branch per workflow, not per task)

### Spec Pipeline

The spec creation flow is a multi-step pipeline:
1. `/spec` — User-invocable skill that interviews the user and generates a draft spec at `.ralph/specs/<feature>/spec-source.md`
2. `spec-researcher` agent — Enriches the draft with web research and codebase analysis
3. `/spec-clarify` or `/spec-finalize` — Resolves open questions and produces a finalized spec
4. `spec-synth` agent — Converts finalized spec into `workflows.json` for Ralph

A parallel PRD pipeline exists (`prd-researcher` → `/spec-finalize` → `prd-synth` → `prd.json`).

### Grill Me

`/grill-me` is a design stress-testing skill. It interviews the user about a spec/plan, spawns researchers for questions needing data, and records decisions back into the source document.

## Editing Conventions

- Agent and skill files are pure markdown with YAML frontmatter — no code execution
- The `tools` frontmatter field uses comma-separated tool names; `Bash(*)` means unrestricted shell, `Bash(cat:*)` means only cat commands
- Model values can be short names (`opus`, `sonnet`, `haiku`) or full model IDs
- The `$ARGUMENTS` placeholder in skills is replaced with user-provided arguments at invocation time
