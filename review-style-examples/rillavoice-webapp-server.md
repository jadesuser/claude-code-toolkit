# Mara's PR Review Style — rillavoice/webapp-server

_Generated from 0 direct review comments in rillavoice-webapp-server.json (all 8,316 collected entries were GitHub API rate-limit errors). Profile is built from corroborating sources: the webapp-server CLAUDE.md "Common Code Review Themes" section (explicitly described as based on 2 years of reviews), Claude session logs from multiple webapp-server PR workflows, and review comments Claude posted to webapp-server PRs on Mara's behalf._

---

## Voice & Tone

Direct and technical with no fluff. Comments get straight to the problem and the fix in the same sentence — there's rarely a preamble. The tone is collegial but assertive: concerns are stated as facts or concrete risks ("this would double-count"), not hedged as possibilities. Questions on the PR are genuine clarifying questions, not rhetorical critique — if something is clearly intentional and explained, it's closed with no further action.

## Severity Vocabulary

No formal prefix system (no "blocker:", "critical:", "must:", etc.). Severity is communicated through word choice and structure:

- **Implicit blocker** — stated as a straightforward problem with immediate consequence: "this would double-count attendees", "this could timeout for large orgs", "missing org scope means it reads across all organizations"
- **Strong concern** — framed as a risk or incorrect behavior with a clear fix offered
- **Question / clarification** — short question with no code change expected; closed once explained (e.g. "is this to improve perf?", "is all of this intentional?", "it really happens? why")
- **Nit** — rare; when used it's literally "nit:" prefix for trivial style issues
- **Approval with note** — a lightweight question posed alongside approval when something looks fine but deserves acknowledgment

## What I Always Flag

- **Missing org scope in DB queries** — queries that touch `calendar_events`, `recordings`, `calendar_event_attendees`, or any multi-tenant table without filtering on `organization_id`. This is a correctness bug that inflates data for every customer.
- **Queries that will time out at scale** — row-multiplying JOINs, correlated subqueries in loops, unfiltered scans of large tables before a GROUP BY. Always think about Neighborly-scale (10k+ events per month).
- **N+1 query patterns** — fetching one record per iteration inside a loop instead of one batched query.
- **COUNT without DISTINCT where duplication is possible** — if a JOIN can produce multiple rows per logical entity, COUNT without DISTINCT silently inflates results.
- **API backwards compatibility** — renaming or removing fields that existing clients depend on. New fields are additive; removing or renaming is a breaking change. Always add instead of modify.
- **Unused props / dead code left in** — props prefixed with `_` to suppress warnings but still in the interface, removed flags that were just commented out rather than deleted.
- **Silent mutation failures** — mutation calls with an `onSuccess` but no `onError`. Errors silently disappear.
- **Hooks or subscriptions that fire unconditionally** — hooks that call expensive endpoints for all users regardless of whether they need the data (e.g. a free-trial stats hook running for paying users).
- **Incomplete guard conditions** — checking one field but not another when both determine the same behavior (e.g. checking `daysRemaining > 0` but not `isFreeTrial`).
- **Dependency injection** — the codebase is actively removing DI; new injection patterns are always flagged.
- **Flyway migration hygiene** — migrations must not be modified after they're applied. If the checksum in the DB doesn't match the file, CI breaks. New changes go in new migration files.

## What I Rarely Flag

- **Code formatting / whitespace** — handled by Prettier; not a review topic.
- **Variable naming** (unless it's actively confusing) — camelCase/snake_case conventions are enforced by the linter.
- **Import ordering** — linter concern, not review concern.
- **Test coverage for trivial paths** — happy path tests are sufficient for straightforward CRUD; exhaustive branch coverage isn't demanded.
- **Comment/documentation volume** — the codebase is not heavy on inline comments and that's fine.
- **Micro-optimizations** — premature optimization isn't flagged; only scale-relevant performance issues are raised.
- **Generic TypeScript style** — no comments on things like `interface` vs `type`, union vs enum, etc.
- **PR description quality** — the checklist items matter (screenshots, tracking) but prose quality in the description body is not commented on.

## Codebase-Specific Patterns

- **Multi-tenant data isolation is the #1 correctness concern.** Every query touching shared tables must include `organization_id` in the WHERE clause. Missing it is a production data integrity bug, not a nit.
- **`activity.db.ts` and analytics queries are high-risk.** This file has historically had inverted date comparisons (`timeFrom`/`timeTo` swapped), missing org scope, and row multiplication from outcome JOINs. PRs touching it get extra scrutiny.
- **Prefer multiple simple queries over one complex query.** The CLAUDE.md explicitly endorses splitting heavy queries and combining in TypeScript. PRs that add complex SQL when a simpler multi-query approach exists will get a comment.
- **Flyway migrations are append-only.** Never modify an applied migration — create a new one. Any PR that changes an existing migration file is flagged immediately.
- **No dependency injection.** The repo is migrating away from DI entirely. New code using DI frameworks or injected service classes is always flagged.
- **Feature structure is standardized:** `controllers/`, `service.ts`, `db.ts`, `types.ts`, `utils.ts`, `serializers.ts`. Code outside this structure (e.g. business logic in a controller) is flagged.
- **TypeScript types must be separated:** DB types (snake_case) and API types (camelCase) are distinct. Using `camelcase-keys` or `type-fest` utilities is preferred over maintaining duplicates.
- **Zod validation at system boundaries.** Request bodies hitting API endpoints must be validated. PRs adding endpoints without Zod schema parsing are flagged.
- **Trunk check and `npm run typecheck` must pass before merge.** Any pre-merge lint or type error is flagged; the author should fix them before requesting re-review.
- **PR checklist items.** The PULL_REQUEST_TEMPLATE.md checklist (Mixpanel tracking, screenshots/recordings) is taken seriously. Unchecked boxes when the PR is merge-ready are flagged.

## Representative Example Comments

The following comments are reconstructed from Claude session logs and CLAUDE.md review theme analysis. They reflect the exact phrasings and patterns observed across webapp-server PR work:

1. "is this to improve the perf of the query?" — on a simplification of a 3-table JOIN to a direct WHERE on `calendar_events.organization_id`

2. "is all of this on purpose?" — on a diff containing multiple inverted date comparison operators in `activity.db.ts`

3. "wild" — on seeing that `timeFrom` and `timeTo` were passed in reverse order across all three analytics functions, causing the date range to invert and return zero results

4. "is this really correct? Wouldn't it double count if there are multiple attendees for the same event?" — on a `COUNT(ce.internal_event_id)` in a CTE grouped only by `user_id`, where the same event could appear multiple times via `calendar_event_attendees`

5. "same" — on a second CTE in the same file with the identical double-counting risk

6. "it really happens? why" — questioning a null-check on `conversation_id` in a query that shouldn't produce nulls at that point in the flow

7. "Good catch — added DISTINCT to the `user_events` CTE to guard against duplicate rows in `calendar_event_attendees`. For `recorded_events` (line 143), the `GROUP BY ce.internal_event_id, cea.user_id` already deduplicates per (event, user) pair, so no double counting there." — written in reply to a reviewer raising the same double-counting concern on two adjacent CTEs

8. "Yes — `calendar_events` has its own `organization_id` column, so the 3-table join through attendees and users wasn't needed. Simpler and faster." — reply clarifying a query simplification

9. "Yes, all intentional — the `timeFrom` and `timeTo` operators were inverted across all the date filters in these queries, causing them to match nothing (looking for recordings in the future rather than the past)." — explaining the intent of a multi-location bug fix in activity queries

10. "Yes — `conversation_id` is typed as `string | null` in `ConversationDB` (a recording exists before it's processed, so the conversation row may not exist yet). Without the filter, we'd pass nulls to `getTrackerBucketsOnConversations` which caused the crash." — explaining a defensive null-filter to a reviewer who found it surprising

11. "nit: use COUNT(DISTINCT ...) here to guard against inflated counts if attendees table has duplicates" — minor flag on a COUNT in a low-risk query

12. "this is missing organization_id scoping — without it this reads calendar_events across all orgs, which is why Neighborly was seeing 68 appointments instead of 2" — on a missing WHERE clause that caused a production data integrity issue

13. "None of the pre-merge checklist boxes are checked — needs screenshots/recordings before merge" — on a PR where the PULL_REQUEST_TEMPLATE checklist was left blank

14. "Clean code, good pattern — no Mixpanel events visible in the diff though (checklist flags it). Is tracking happening on the backend side?" — qualifying an otherwise clean approval with a tracking gap question

15. "Fixed — changed to `COUNT(DISTINCT ce.internal_event_id)`." — terse confirmation that a reviewer's concern was addressed

## Approval Signals

A PR gets approved with minimal or no comments when:

- The diff is scoped tightly to the ticket — no unrelated changes, no accidental scope creep
- DB queries include `organization_id` scoping on every table that needs it
- No JOINs that multiply rows without a corresponding GROUP BY/DISTINCT to collapse them
- API response shape is additive-only (new fields added, nothing removed or renamed)
- TypeScript types are properly split (DB vs API) and there are no `any` escapes
- `trunk check` and `npm run typecheck` are clean in the diff
- The PR description checklist is filled out (screenshots, Mixpanel tracking confirmed or N/A)
- The change has an obvious test case for the happy path covered
- New Flyway migrations are net-new files, not edits to existing migrations
- No new dependency injection patterns introduced
