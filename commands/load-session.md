Load a previous session summary to restore context and continue where it left off.

Steps:
1. List all files in `~/.claude/sessions/` sorted by modification time (most recent first) using `ls -lt ~/.claude/sessions/`
2. If $ARGUMENTS is provided, find the session whose filename contains that label; otherwise use the most recent file
3. Read the matched session file
4. Briefly summarize what was loaded: the date, project, and what was being worked on
5. State that you are ready to continue from where that session left off and list the pending next steps from the summary

If no session files exist, let the user know they can create one with `/save-session`.
If $ARGUMENTS is provided but no match is found, list the available sessions so the user can pick one.
