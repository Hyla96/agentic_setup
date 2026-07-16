---
name: pr-ship
metadata:
  version: 1.0.2
description: |
  Finalize work into a pull request: commit and push anything that isn't
  committed/pushed yet, then create or update the PR with a clear, human-readable
  body (What / Why / How) and a title prefixed with the Jira ticket number
  (e.g. "ST-1928 Hotfix payment retry loop"). Use whenever the user wants to
  "ship", "open a PR", "push this up", "finish the branch", "create/update the
  pull request", or asks to clean up a PR title or description — even if they
  don't mention Jira explicitly.
license: MIT
compatibility: any-agent
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - AskUserQuestion
---

# PR Ship: Commit, Push, and Write a Human-Readable PR

You finalize the user's work into a pull request. That means three things, in order: make sure everything is committed and pushed, make sure the PR title carries the Jira ticket, and make sure the PR body explains the change so a human reviewer understands it in under a minute.

Never ask questions you can answer yourself from the repository state. Only ask the user the questions listed in "When to ask the user". Never force-push, never rewrite history, never amend commits you didn't create in this session.

## Step 1: Inspect the state

Run these first and reason from the output before doing anything else:

```bash
git status --porcelain           # uncommitted changes?
git branch --show-current        # current branch
git log --oneline -10            # recent commits (also a Jira ticket source)
git rev-parse --abbrev-ref @{upstream} 2>/dev/null   # upstream set?
git cherry -v 2>/dev/null        # unpushed commits (if upstream exists)
gh pr view --json number,title,body,baseRefName 2>/dev/null  # existing PR?
```

From this you know: whether there is something to commit, whether there are unpushed commits, whether a PR already exists, and what the base branch would be.

## Step 2: Find the Jira ticket

Look for a ticket ID (pattern: `[A-Z][A-Z0-9]+-[0-9]+`, e.g. `ST-1928`) in this order:

1. The current branch name (`feature/ST-1928-fix-retry` → `ST-1928`)
2. The existing PR title, if a PR exists
3. Recent commit messages on this branch

## Step 3: Ask the user (hard gate — do this before touching git)

Based on Steps 1–2, determine which of these two questions apply:

1. **Branch question** — applies whenever `git status --porcelain` was non-empty. Ask: _"Commit on the current branch (`<name>`), or create a new branch?"_ This question is **mandatory** when there are uncommitted changes. Never skip it because the answer seems obvious — being on a feature branch already, having a "sensible" branch name, or the change looking small are NOT reasons to skip. The user decides, not you.
2. **Ticket question** — applies only when Step 2 found no ticket anywhere. Ask for the ticket number and offer a "no ticket" option in case the change genuinely has none; in that case skip the ticket prefix entirely rather than inventing one.

Ask each applicable question as its own separate question tool call (e.g. AskUserQuestion), branch question first. Do not bundle them into one call.

If a question tool call fails (invalid parameters, error, anything), fix the call and **retry that same question**. A failed call is not an answer. Do not proceed past this step while any applicable question is unanswered — committing with uncommitted changes present but no branch answer is a failure of this skill.

## Step 4: Commit — only if there is something to commit

If `git status --porcelain` was empty, skip to Step 5.

Otherwise act on the branch answer from Step 3:

- **Current branch**: stage and commit there.
- **New branch**: remember the current branch name first — it becomes the **base of the PR**. Then create the new branch (sensible name including the ticket, e.g. `st-1928-hotfix-payment-retry`), and commit there.

Write the commit message yourself from the diff (`git diff` / `git diff --staged`). Keep it conventional and short, ticket first, matching the title style: `ST-1928 Fix payment retry loop`. Always include the Claude Code attribution at the end of the commit message:

```
ST-1928 Fix payment retry loop

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

Stage intentionally (`git add <paths>`) — don't blindly `git add -A` if the status shows unrelated junk (build artifacts, local config); mention anything you left out.

## Step 5: Push

- If the branch has no upstream: `git push -u origin <branch>`.
- Otherwise, if `git cherry` shows unpushed commits: `git push`.
- If everything is already pushed, say so and move on.

If the push is rejected because the remote is ahead, stop and tell the user — do not force-push or auto-rebase without being asked.

## Step 6: Create or update the PR

Determine the base branch:

- If you created a new branch in Step 4, the base is the branch the user was on before.
- If a PR already exists, keep its existing base.
- Otherwise use the repo default branch (`gh repo view --json defaultBranchRef`).

Then:

- **No PR yet**: `gh pr create --base <base> --title "<title>" --body "<body>"`
- **PR exists**: `gh pr edit --title "<title>" --body "<body>"` — but if the existing body clearly contains hand-written content by the user, show your proposed body and confirm before overwriting.

### Title format

`<TICKET> <Short imperative summary>` — ticket first, then a plain description:

```
ST-1928 Hotfix payment retry loop
APP-204 Add CSV export to reports page
```

If the title already contains the ticket somewhere, normalize it to this format. Keep the summary under ~70 characters, no trailing period.

### Body format

The body is for humans, not machines. Plain language, no jargon walls, no bullet spam. A reviewer who knows nothing about this task should understand it. Use this template:

```markdown
## What

One to three sentences: what does this change, in plain words.

## Why

Why this change was needed — the problem, bug, or request behind it.
Link the Jira ticket here (e.g. ST-1928).

## How

Only include this section when the approach isn't obvious from the diff:
a tricky implementation choice, a migration, a workaround, a trade-off.
For a simple, self-explanatory change, leave the section out entirely.
```

Rules for the body:

- Write from the actual diff and commits — read them, don't guess.
- Short beats complete. Three clear sentences beat twelve vague ones.
- No filler ("This PR aims to…", "In order to…"), no restating the file list — reviewers can see the diff.
- Skip "How" when the change is trivial. A one-line config fix does not need an architecture section.
- Mention anything the reviewer must do or know (new env var, migration to run, follow-up ticket) — that's the most valuable content a body can have.
- End the body with the Claude Code attribution as the last line, separated by a blank line:
  `🤖 Generated with [Claude Code](https://claude.com/claude-code)`
  Keep it even when updating an existing PR body.

**Example (small fix):**

```markdown
## What

Retries failed payment webhooks up to 3 times with backoff instead of failing immediately.

## Why

Payments were marked failed during brief provider outages, forcing manual replays (ST-1928).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

**Example (bigger change, "How" earns its place):**

```markdown
## What

Adds CSV export to the reports page.

## Why

Finance exports report data monthly and currently copies it by hand from the UI (APP-204).

## How

Export runs as a background job and emails a download link, because large reports
were timing out when generated in the request. Needs the new `EXPORT_BUCKET` env var in staging.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Self-check before creating/updating the PR

Stop and verify, in order:

- [ ] Were there uncommitted changes at Step 1? Then the **branch question was asked and answered by the user** — not inferred, not skipped, not lost to a failed tool call.
- [ ] Is there a ticket in the title, or did the user explicitly say "no ticket"?
- [ ] Does the body follow What / Why (/ How only if needed) and read like it was written for a human?

If any box is unchecked, go back and fix it before running `gh pr create` / `gh pr edit`. Everything the user wasn't asked about — commit message, branch name, base branch, title, body — you decide and then report what you did.

## Finish

End with a short summary: branch, what was committed/pushed (or that nothing needed it), and the PR link with its final title.
