Address unresolved PR review comments on my behalf. Fetches comments from my open PRs or PRs where I'm mentioned, drafts responses, and posts them after my approval.

The optional argument is a specific PR to target: $ARGUMENTS (a full GitHub URL like `https://github.com/owner/repo/pull/123`, or `owner/repo#number`)

---

## Steps

### 1. Discover PRs to address

**If $ARGUMENTS is provided**, parse it as a specific PR:
- If it's a GitHub URL: extract owner, repo, and number
- If it's `owner/repo#number` format: parse accordingly
- Only process that one PR

**If $ARGUMENTS is empty**, find all relevant PRs across three sources:

a) My open PRs:
```
gh search prs --author @me --state open --json number,title,repository,url --limit 20
```

b) PRs where I'm mentioned:
```
gh api "search/issues?q=is:pr+is:open+mentions:@me" --jq '[.items[] | {number, title, html_url, repository_url}]'
```

c) Unread notifications involving PRs (no --paginate to avoid rate limit exhaustion — first page only):
```
gh api notifications --jq '[.[] | select(.subject.type == "PullRequest") | select(.reason == "mention" or .reason == "comment") | {reason, title: .subject.title, url: .subject.url, thread_id: .id}]'
```

Deduplicate across all three sources. If nothing is found, report "No open PRs with pending comments found" and stop.

---

### 2. For each PR, gather context

Parse the repo owner and name from the PR URL or repository field. Then fetch:

**PR metadata:**
```
gh pr view <number> -R <owner/repo> --json title,body,state,headRefName,baseRefName,author
```

**Inline review comments (on specific lines of code):**
```
gh api repos/<owner>/<repo>/pulls/<number>/comments --paginate
```

**General PR-level comments:**
```
gh api repos/<owner>/<repo>/issues/<number>/comments --paginate
```

**The PR diff (for context when reading code comments):**
```
gh pr diff <number> -R <owner/repo>
```

Filter out comments I've already replied to. A comment is "already replied" if there's a reply in the thread from me (`dimmara`). Only work on comments that are still awaiting a response.

If there are no unresolved comments on this PR, skip it and note it in the final summary.

---

### 3. Draft a response for each unresolved comment

For each comment, read it carefully in the context of:
- The surrounding diff/code
- The PR's overall purpose
- The conversation thread so far

Then draft a reply based on the type of comment:

- **Code change request** → Make the change in the actual file first, then draft a reply like: "Done — [brief description of what was changed]."
- **Question** → Draft a clear, direct answer.
- **Style/nit suggestion** → Either agree ("Good call, updated") or politely explain the reasoning ("Keeping it as-is because [reason] — happy to discuss").
- **Bug report in review** → Acknowledge, fix the code, draft a reply explaining the fix.

Keep replies concise and professional. Don't be overly formal or add unnecessary filler.

---

### 4. Present each draft for my approval

Show drafts one at a time in this format:

```
─────────────────────────────────────────────────
PR: [owner/repo#number] — [PR title]
Comment by @[author] on [file:line if inline, or "general comment"]

Their comment:
"[exact comment text]"

My proposed reply:
"[drafted reply]"

[If code was changed: "Code change: [file] — [brief description of change]"]
─────────────────────────────────────────────────
Post this? (yes / skip / edit)
```

Wait for my response before proceeding to the next comment.
- **yes** → post it
- **skip** → move on without posting
- **edit** → I'll type the revised reply, then post my version

---

### 5. Post approved replies

**For inline review comments** (replies to a specific comment thread):
```
gh api repos/<owner>/<repo>/pulls/comments/<comment_id>/replies \
  -X POST \
  -f body="<approved reply text>"
```

**For general PR comments:**
```
gh api repos/<owner>/<repo>/issues/<number>/comments \
  -X POST \
  -f body="<approved reply text>"
```

---

### 6. Push code changes (if any were made)

If I approved a response that included code changes, commit and push them to the PR branch:

```
cd <repo local path>   # navigate to the correct repo
git add <changed files>
git commit -m "Address PR review: <brief one-line summary of what was fixed>"
git push
```

If the repo isn't checked out locally at the right branch, note this and ask me how to proceed.

---

### 7. Final summary

Print a clean summary:

```
✓ Addressed X comment(s) across Y PR(s)
  - owner/repo#123: 2 replies posted, 1 code change pushed
  - owner/repo#456: 1 reply posted

Skipped: Z comment(s)
```

Include links to each PR.

---

## Notes

- Never post a reply without my explicit "yes"
- If a comment is from a bot (e.g. Trunk, Codecov, GitHub Actions) — skip it unless I specifically ask to address it
- If a PR has a large number of comments (10+), ask me if I want to go through them all or just the most recent ones
- Stay in the context of what the reviewer actually asked — don't over-explain or pad replies
