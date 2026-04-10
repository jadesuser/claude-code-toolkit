Generate a structured session summary and save it as a markdown file so it can be picked up by another agent or a future session.

Steps:
1. Create the directory `~/.claude/sessions/` if it doesn't exist (use `mkdir -p`)
2. Determine the current date/time and working directory
3. Generate a comprehensive session summary using the template below
4. Write the file to `~/.claude/sessions/` with filename format: `YYYY-MM-DD-HH-MM$ARGUMENTS.md` (prepend a `-` before $ARGUMENTS if it is non-empty, e.g. `2026-02-26-14-30-my-label.md`)
5. Confirm the full path where the file was saved

## Summary Template

```
# Session: $ARGUMENTS or [auto-generated title based on work done]
Date: [current date and time]
Project: [current working directory]

## What was worked on
[Describe the main task(s) addressed this session]

## Key decisions and context
[Important choices made, rationale, constraints discovered]

## Files modified
[List each file changed and what was done to it]

## Current state
[What is working, what is in a partial state]

## Pending / next steps
[What still needs to be done, any blockers]

## How to continue
[Any setup steps, commands to run, or context the next agent needs to get started]
```

Be thorough — the goal is for a fresh agent with no prior context to be able to pick up exactly where this session left off.
