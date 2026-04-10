Analyze my past PR review comments for a specific codebase and build a style profile that captures how I review code.

The target repo is: $ARGUMENTS (format: owner/repo, e.g. rillavoice/webapp)

## Steps

1. **Validate input**: If $ARGUMENTS is empty, tell the user to provide a repo in the format `owner/repo` and stop.

2. **Derive file paths**:
   - Replace `/` with `-` in $ARGUMENTS to get the slug (e.g. `rillavoice/webapp` → `rillavoice-webapp`)
   - History file: `~/.claude/review-history/{slug}.json`
   - Output file: `~/.claude/review-style/{slug}.md`

3. **Read the history file** at the derived path. If it doesn't exist, tell the user to run:
   ```
   ~/.claude/scripts/collect-pr-comments.sh $ARGUMENTS
   ```
   then run `/build-review-style $ARGUMENTS` again. Stop.

4. **Analyze the comments deeply**. Read every comment in the history and identify:
   - **Tone**: How formal/casual, how direct, how diplomatic
   - **Phrasing patterns**: Recurring sentence structures, opener words, how feedback is framed
   - **What I always flag**: Patterns that appear repeatedly (e.g. naming conventions, missing error handling, architectural violations, test coverage)
   - **Severity vocabulary**: How I signal criticality — do I use "nit:", "blocker:", "suggestion:", or something else?
   - **What I let slide**: Topics that rarely or never appear in my comments (things I don't care about)
   - **Codebase-specific concerns**: Things unique to this repo's architecture or standards
   - **Approval patterns**: What signals in a PR make me approve without many comments

5. **Write the style profile** to `~/.claude/review-style/{slug}.md` using this structure:

```markdown
# Mara's PR Review Style — {repo}

_Generated from {N} review comments across {repo}_

## Voice & Tone
[2–3 sentences describing communication style, directness level, formality]

## Severity Vocabulary
[How criticality is communicated — exact phrases/prefixes used]

## What I Always Flag
[Bulleted list of patterns that consistently appear in reviews]

## What I Rarely Flag
[Bulleted list of things that don't appear — indicates lower priority]

## Codebase-Specific Patterns
[Things unique to this repo's architecture, conventions, or standards]

## Representative Example Comments
[10–15 verbatim comments from the history, lightly formatted, covering different types]

## Approval Signals
[What a PR looks like when I approve without many comments]
```

6. **Confirm** to the user:
   - Where the file was written
   - How many comments were analyzed
   - Suggest they read and edit the profile to fine-tune it before using `/review-pr`
