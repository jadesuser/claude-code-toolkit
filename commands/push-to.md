Push current changes to a new branch, run all checks, and open a PR against master.

The target branch name is: $ARGUMENTS

## Steps

1. **Pull latest master** — fetch and merge the latest changes from master into the current branch:
   ```
   git fetch origin master
   git merge origin/master
   ```
   Resolve any merge conflicts before proceeding.

2. **Detect and run all linting/type checks** in the repo. Always run these if they exist:
   - `trunk check --fix` (if trunk is configured — look for `.trunk/` directory)
   - `npm run typecheck` (if it exists in package.json)
   - Any other lint scripts in `package.json` (look for keys like `lint`, `check`, `validate`)
   - If it's a Python project, look for `ruff`, `mypy`, or similar in `pyproject.toml`
   Fix any issues that come up. Do not skip or bypass checks.

3. **Stage and commit** all changes (including any lint fixes):
   - Stage only relevant files (not secrets or binaries)
   - Write a clear, descriptive commit message based on what was changed

4. **Push to the branch** `$ARGUMENTS` and create a PR against master:
   ```
   git checkout -b $ARGUMENTS   # or git push -u origin $ARGUMENTS if branch already exists
   gh pr create --base master ...
   ```

5. **Fill in the PR template**:
   - Look for a PR template in the repo: `.github/pull_request_template.md` or `.github/PULL_REQUEST_TEMPLATE.md`
   - If a template exists, fill in every section based on the changes made
   - Keep each section to **one paragraph or less** — be concise
   - For any section about testing (e.g. "How was this tested?", "Test plan", "Testing", "QA"): write **only** `Tested locally` — nothing else
   - If no template exists, write a short summary and a one-line test note

6. **Return the PR URL** when done.
