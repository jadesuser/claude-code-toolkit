Review a pull request on behalf of Mara (GitHub: maradimofte), using her codebase-specific review style profile.

The PR to review is: $ARGUMENTS

Accepted formats for $ARGUMENTS:
- Full URL: `https://github.com/rillavoice/webapp/pull/456`
- `owner/repo#number`: `rillavoice/webapp#456`
- Just `#number` or `456` (resolves repo from `git remote get-url origin` in current directory)

## Steps

### 1. Resolve the PR

Parse $ARGUMENTS to determine `owner`, `repo`, and `pr_number`:
- If it's a GitHub URL, extract owner/repo/number from the path
- If it's `owner/repo#number`, split on `#`
- If it's just a number (or `#number`), run `git remote get-url origin` and parse the owner/repo from the remote URL

### 2. Load the style profile

- Derive the slug: replace `/` with `-` in `owner/repo` (e.g. `rillavoice-webapp`)
- Read `~/.claude/review-style/{slug}.md`
- If the file doesn't exist, stop and tell the user:
  ```
  No style profile found for {owner/repo}.
  Run these commands first:
    ~/.claude/scripts/collect-pr-comments.sh {owner/repo}
    /build-review-style {owner/repo}
  ```

### 3. Fetch PR context

Run these commands to gather full PR context:

```bash
gh pr view {pr_number} --repo {owner/repo} \
  --json title,body,author,baseRefName,headRefName,additions,deletions,changedFiles,files,reviews,comments,labels,state

gh pr diff {pr_number} --repo {owner/repo}
```

### 4. Read codebase standards (if available)

Look for any of these files in the repo's local checkout (check common locations):
- `AGENTS.md`
- `STANDARDS.md`
- `standards/` directory
- `.github/PULL_REQUEST_TEMPLATE.md`

If the local checkout exists (e.g. `~/dev/webapp/` for `rillavoice/webapp`, `~/services-monorepo/` for `rillavoice/services-monorepo`), read them. These inform what to flag beyond Mara's personal patterns.

### 5. Generate the review

Using the style profile, PR diff, and codebase standards, write the review as Mara would. The review must:

- **Match her voice exactly** — use her phrasing, severity vocabulary, and tone from the style profile
- **Flag what she always flags** — apply her patterns from the style profile
- **Ignore what she rarely flags** — don't invent concerns she wouldn't raise
- **Be structured as**:
  1. **Overall verdict**: One line — approve / request changes / comment, with a brief reason
  2. **File-by-file inline comments**: For each file with issues, quote the relevant code excerpt and write the comment beneath it
  3. **Closing summary**: 2–3 sentences wrapping up overall impression

Format example:
```
**Overall**: Request changes — a few architectural issues to address before merging.

---

**src/features/leads/api/useLeads.ts**
> ```ts
> const data = await fetch('/api/leads').then(r => r.json())
> ```
nit: This should use TanStack Query instead of a raw fetch — see `useRidealongs.ts` for the pattern.

---

**src/features/leads/components/LeadCard.tsx**
> ```ts
> <div style={{ color: '#FF5500' }}>
> ```
Use a semantic token here (`text-accent-primary` or similar) rather than a hardcoded hex — it won't adapt to dark mode.

---

Overall looks solid, just the query pattern and token usage need fixing. Happy to re-review once those are addressed.
```

### 6. Present the draft

Print the full review to the terminal inside a markdown code block so it's easy to read and copy.

Then ask the user:
```
Post this review as a comment on {owner/repo}#{pr_number}? [y/N]
```

### 7. Post if confirmed

If the user confirms (types `y` or `yes`):

```bash
gh pr review {pr_number} --repo {owner/repo} --comment --body "{review_body}"
```

Confirm with the PR URL once posted.
