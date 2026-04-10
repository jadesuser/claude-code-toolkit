#!/usr/bin/env bash
# collect-pr-comments.sh
# Collects all PR review comments and reviews by maradimofte for a given repo.
# Usage: collect-pr-comments.sh OWNER/REPO
# Output: ~/.claude/review-history/{owner}-{repo}.json
#
# Progress is saved after every PR so a crash/interrupt can be resumed.
# Re-running will skip already-processed PRs and continue from where it left off.
# Use --reset to start fresh and discard prior progress.

set -euo pipefail

GITHUB_USER="maradimofte"
OUTPUT_DIR="$HOME/.claude/review-history"
mkdir -p "$OUTPUT_DIR"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 OWNER/REPO [--reset]"
  exit 1
fi

REPO="$1"
RESET=false
if [[ "${2:-}" == "--reset" ]]; then
  RESET=true
fi

OWNER="${REPO%%/*}"
REPO_NAME="${REPO##*/}"
SLUG="${OWNER}-${REPO_NAME}"

OUTPUT_FILE="$OUTPUT_DIR/${SLUG}.json"
CHECKPOINT_FILE="$OUTPUT_DIR/${SLUG}.checkpoint"
COMMENTS_TMP="$OUTPUT_DIR/${SLUG}.comments.jsonl"  # one JSON object per line

# --reset: wipe prior progress
if $RESET; then
  echo "Resetting prior progress for $REPO..."
  rm -f "$CHECKPOINT_FILE" "$COMMENTS_TMP" "$OUTPUT_FILE"
fi

echo "Collecting PR review comments for $REPO (user: $GITHUB_USER)..."

# ── 1. Fetch all PR numbers (fast, no per-PR API calls yet) ─────────────────

echo "Fetching PR list..."
ALL_PR_NUMBERS_FILE="$OUTPUT_DIR/${SLUG}.prs"

if [[ ! -f "$ALL_PR_NUMBERS_FILE" ]]; then
  PAGE=1
  > "$ALL_PR_NUMBERS_FILE"
  while true; do
    BATCH=$(gh api "/repos/$REPO/pulls?state=all&per_page=100&page=$PAGE" --jq '.[].number' 2>/dev/null)
    if [[ -z "$BATCH" ]]; then
      break
    fi
    echo "$BATCH" >> "$ALL_PR_NUMBERS_FILE"
    PAGE=$((PAGE + 1))
  done
  echo "PR list saved."
fi

TOTAL=$(wc -l < "$ALL_PR_NUMBERS_FILE" | tr -d ' ')
echo "Found $TOTAL PRs total."

# ── 2. Load checkpoint (set of already-processed PR numbers) ────────────────

if [[ -f "$CHECKPOINT_FILE" ]]; then
  DONE_COUNT=$(wc -l < "$CHECKPOINT_FILE" | tr -d ' ')
  echo "Resuming — $DONE_COUNT / $TOTAL PRs already processed."
else
  echo "Starting fresh."
  > "$COMMENTS_TMP"
  > "$CHECKPOINT_FILE"
fi

# ── 3. Process each PR, skip if already done ────────────────────────────────

PROCESSED=$(wc -l < "$CHECKPOINT_FILE" | tr -d ' ')

while IFS= read -r PR_NUM; do
  if grep -q "^${PR_NUM}$" "$CHECKPOINT_FILE" 2>/dev/null; then
    continue
  fi

  PROCESSED=$((PROCESSED + 1))

  # Inline review comments (on specific lines)
  INLINE=$(gh api "/repos/$REPO/pulls/$PR_NUM/comments" \
    --jq "[.[] | select(.user.login == \"$GITHUB_USER\") | {
      type: \"inline\",
      pr: $PR_NUM,
      file: .path,
      line: .line,
      body: .body,
      created_at: .created_at
    }]" 2>/dev/null || echo "[]")

  # Review-level comments (the overall review body)
  REVIEWS=$(gh api "/repos/$REPO/pulls/$PR_NUM/reviews" \
    --jq "[.[] | select(.user.login == \"$GITHUB_USER\" and (.body | length > 0)) | {
      type: \"review\",
      pr: $PR_NUM,
      state: .state,
      body: .body,
      created_at: .submitted_at
    }]" 2>/dev/null || echo "[]")

  # Append any found comments to the JSONL file (one comment per line)
  echo "$INLINE $REVIEWS" | jq -c '.[]' 2>/dev/null >> "$COMMENTS_TMP" || true

  # Mark this PR as done in the checkpoint
  echo "$PR_NUM" >> "$CHECKPOINT_FILE"

  if (( PROCESSED % 10 == 0 )); then
    COMMENT_COUNT=$(wc -l < "$COMMENTS_TMP" | tr -d ' ')
    echo "  Progress: $PROCESSED / $TOTAL PRs  |  $COMMENT_COUNT comments so far"
  fi

done < "$ALL_PR_NUMBERS_FILE"

# ── 4. Assemble final output JSON ────────────────────────────────────────────

echo ""
echo "Assembling final output..."

jq -n \
  --arg repo "$REPO" \
  --slurpfile comments <(jq -s '.' "$COMMENTS_TMP") \
  '{
    repo: $repo,
    collected_at: (now | todate),
    total_comments: ($comments[0] | length),
    comments: $comments[0]
  }' > "$OUTPUT_FILE"

TOTAL_COMMENTS=$(jq '.total_comments' "$OUTPUT_FILE")

# Clean up temp files
rm -f "$CHECKPOINT_FILE" "$COMMENTS_TMP" "$ALL_PR_NUMBERS_FILE"

echo "Done. $TOTAL_COMMENTS comments saved to $OUTPUT_FILE"
