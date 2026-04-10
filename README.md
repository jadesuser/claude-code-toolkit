# Claude Code Toolkit

A collection of [Claude Code](https://docs.anthropic.com/en/docs/claude-code) slash commands, scripts, and review style profiles for automated code review workflows.

## What's in here

### `/commands/` — Claude Code slash commands

Drop these into `~/.claude/commands/` to use them as `/command-name` in Claude Code.

| Command | What it does |
|---|---|
| **`review-pr`** | Reviews any PR using your personal review style profile — matches your voice, flags what you'd flag, ignores what you'd ignore |
| **`build-review-style`** | Analyzes your collected PR comments and generates a style profile |
| **`address-pr-comments`** | Finds unresolved review comments on your PRs, drafts replies, and posts them after approval |
| **`push-to`** | Pushes current changes to a new branch, runs all checks, and opens a PR |
| **`save-session`** | Saves a structured session summary so a future session can pick up where you left off |
| **`load-session`** | Loads a previous session summary to restore context |
| **`support`** | Support agent with access to common DB queries and troubleshooting (requires PostgreSQL MCP) |

### `/scripts/` — Shell scripts

| Script | What it does |
|---|---|
| **`collect-pr-comments.sh`** | Scrapes all your past PR review comments from any GitHub repo. Resumable with checkpoints. |

### `/review-style-examples/` — Example style profiles

Two real generated profiles showing what the output of the review pipeline looks like:
- `rillavoice-webapp-server.md` — backend/API review style (multi-tenant, SQL, migrations)
- `jade-eaas.md` — CLI/engine review style (architecture boundaries, security, event systems)

## How the review pipeline works

```
1. Collect history        2. Build profile         3. Review PRs
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ collect-pr-      │───>│ /build-review-   │───>│ /review-pr      │
│ comments.sh      │    │ style            │    │                 │
│                  │    │                  │    │ Uses your style │
│ Scrapes all your │    │ Reads history,   │    │ profile to      │
│ past PR comments │    │ identifies your  │    │ review any PR   │
│ from GitHub      │    │ patterns, writes │    │ in your voice   │
│                  │    │ a style profile  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
        │                       │                       │
   ~/.claude/              ~/.claude/              Reads profile +
   review-history/         review-style/           PR diff, writes
   {slug}.json             {slug}.md               review as you
```

### Step 1: Collect your review history

```bash
# Make the script executable
chmod +x scripts/collect-pr-comments.sh

# Run it for any repo you review
./scripts/collect-pr-comments.sh owner/repo

# Output: ~/.claude/review-history/owner-repo.json
```

The script pages through every PR in the repo and extracts your inline review comments and review-level comments. It saves progress after each PR, so you can interrupt and resume.

### Step 2: Build your style profile

```
/build-review-style owner/repo
```

This reads the collected JSON and generates a markdown profile at `~/.claude/review-style/owner-repo.md` capturing:
- Your voice and tone
- How you signal severity (blocker vs nit)
- What you always flag
- What you rarely flag
- Codebase-specific patterns
- 10-15 representative example comments
- What makes you approve without comments

### Step 3: Review PRs in your voice

```
/review-pr https://github.com/owner/repo/pull/123
/review-pr owner/repo#123
/review-pr 123    # resolves repo from git remote
```

Claude reads the style profile, fetches the PR diff, and writes a review that matches your patterns. It presents the draft for your approval before posting.

## Setup

1. Copy the commands you want into `~/.claude/commands/`:
   ```bash
   cp commands/* ~/.claude/commands/
   ```

2. Copy the script:
   ```bash
   mkdir -p ~/.claude/scripts
   cp scripts/collect-pr-comments.sh ~/.claude/scripts/
   chmod +x ~/.claude/scripts/collect-pr-comments.sh
   ```

3. Create the directories for generated files:
   ```bash
   mkdir -p ~/.claude/review-history ~/.claude/review-style ~/.claude/sessions
   ```

4. Edit `collect-pr-comments.sh` and change `GITHUB_USER` to your GitHub username.

5. Collect your history and build your first profile:
   ```bash
   ~/.claude/scripts/collect-pr-comments.sh your-org/your-repo
   # Then in Claude Code:
   /build-review-style your-org/your-repo
   ```

## Customization

- **`review-pr.md`**: Update the local checkout paths in Step 4 to match where you keep your repos
- **`address-pr-comments.md`**: Change the GitHub username from `dimmara` to yours in Step 2's filter
- **`support.md`**: Replace the example SQL queries with ones relevant to your data model
- **`collect-pr-comments.sh`**: Change `GITHUB_USER` on line 14

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- [GitHub CLI](https://cli.github.com/) (`gh`) authenticated
- `jq` for JSON processing (used by the collection script)
