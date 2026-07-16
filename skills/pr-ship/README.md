# PR Ship

A portable agent skill that finalizes your work into a pull request. It is plain Markdown, so it runs in any harness that supports skill-style instructions (Claude Code, Claude.ai skills, etc.), modeled on the structure of [blader/humanizer](https://github.com/blader/humanizer).

## What it does

1. **Commits and pushes** anything that isn't committed or pushed yet.
2. **Creates or updates the PR** using the GitHub CLI (`gh`).
3. **Writes a human-readable PR body** — What / Why / How ("How" only when the change actually needs explaining).
4. **Puts the Jira ticket in the PR title**, e.g. `ST-1928 Hotfix payment retry loop`. It finds the ticket in your branch name, PR title, or commits — and only asks you if it can't.

## What it asks you

Only two things, and only when needed:

- **The ticket number**, if it can't find one anywhere.
- **New branch or current branch**, if there are uncommitted changes. If you pick a new branch, the branch you were on becomes the base of the PR.

Everything else (commit message, branch name, base branch, title, body) it decides from the actual diff and reports back.

## Requirements

- `git`
- [GitHub CLI](https://cli.github.com/) (`gh`), authenticated (`gh auth login`)

## Installation

### Claude Code plugin

```
/plugin marketplace add <your-org>/pr-ship
/plugin install pr-ship@pr-ship
```

### Manual

Copy the folder into wherever your harness expects skill directories:

```
git clone https://github.com/<your-org>/pr-ship.git /path/to/your/skills/pr-ship
```

## Usage

```
Ship this / open a PR for my changes / finish this branch
```

or explicitly:

```
/pr-ship
```

## Safety

The skill never force-pushes, never rewrites history, and won't overwrite a hand-written PR description without showing you the replacement first.

## License

MIT
