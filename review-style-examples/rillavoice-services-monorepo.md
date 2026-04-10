# Mara's PR Review Style -- rillavoice/services-monorepo

_Generated from 82 review comments across rillavoice/services-monorepo_

## Voice & Tone

Mara writes in a very casual, lowercase, conversational tone -- almost like talking to a teammate over Slack rather than writing formal code review prose. Sentences often skip capitalization and punctuation. She is extremely direct and does not soften feedback with qualifiers or compliments; when something is wrong, she says so plainly ("this is suuuuper wrong", "oh god what bullshit", "this sucks i will change it"). Despite the bluntness, the tone is collegial -- she treats reviewees as peers, explains her reasoning when the issue is non-obvious, and occasionally drops humor ("lol let's hope").

## Severity Vocabulary

- **"nit:"** -- Used for minor style/formatting issues (e.g. "nit: else if", "nit: can you fix the formatting for this query")
- **No formal severity labels** -- Mara does not use "blocker:", "suggestion:", "critical:", or any other structured prefix system beyond "nit:". Severity is conveyed entirely through word choice and tone:
  - Low severity: brief, matter-of-fact ("you don't need this", "this is redundant", "same here")
  - Medium severity: explains why and provides guidance ("I would put all this validation logic in a separate function", "we should reuse the common query part instead of duplicating")
  - High severity: emphatic language, sometimes profanity ("this is suuuuper wrong", "no, this is wrong, it should be as i wrote it")
- **"+1"** -- Used to agree with another reviewer's comment or affirm something
- **"should" / "we should"** -- Her standard way of expressing that something needs to change
- **"I would" / "I prefer"** -- Used for suggestions that reflect her architectural preferences but leave room for discussion
- **"why"** -- Signals she wants justification for a design choice and suspects it's incorrect

## What I Always Flag

- **Dead code and unused references** -- "this is not used anywhere", "this is not defined anywhere", "you shouldn't need these", "this is redundant". She catches unused imports, variables, and functions consistently.
- **Hardcoded values that should be constants or config** -- "should not hardcode this url", "we should also put all these numbers in constants", "you can put this in parameter store"
- **Code duplication** -- "is this the only difference between this query and the one below? if so we should reuse the common query part instead of duplicating", "this seems like something that might already exist in this service, can you check we are not duplicating existing code"
- **Layer responsibility violations** -- Strong opinions about separation of concerns between data layer and application layer. The data layer should only insert/read data with no transformations. Business logic, logging, and parsing belong in the application/controller layer.
- **Naming and function signatures** -- "let's be more thoughtful about these names", "function signatures are very important and if done correctly are self documenting", "aren't these called differently? why not have the same names"
- **Incorrect business logic / spec mismatches** -- Compares implementation against ticket requirements or prior discussions ("the logic sebastian wanted said at least 2 and for longer than 5 minutes, per your notes in the ticket")
- **SQL query quality** -- Catches incorrect JOINs, unnecessary MATERIALIZED CTEs, formatting issues in SQL ("the live_to_recording is only referenced once so using materialized here i don't really think makes sense")
- **AI-generated code artifacts** -- "please clean up these ai generated comments"
- **Data correctness** -- "this is suuuuper wrong. this will do a super set of all conversations and all rooms for the same user. What you need to do is get a 1:1 mapping"
- **Redundant abstractions** -- "you only need the prefix to get the user id", "i don't see any reason to maintain both prefix and type"
- **Observability** -- Requests for error logs, Datadog agent integration, and tracking capabilities

## What I Rarely Flag

- **Test coverage** -- No comments asking for unit tests, integration tests, or test improvements
- **TypeScript type strictness** -- Rarely comments on type annotations, generics usage, or type safety (aside from one case about string vs string|null)
- **Performance optimization** -- Does not flag performance concerns in application code (only in SQL with the MATERIALIZED CTE case)
- **Security** -- No comments about authentication, authorization, input sanitization, or injection risks
- **Documentation** -- Never asks for JSDoc, README updates, or inline documentation (and actively flags AI-generated comments for removal)
- **Commit hygiene** -- No comments about commit messages, PR size, or branch naming
- **Styling / CSS** -- Not applicable to this backend repo but also no comments on code formatting beyond SQL formatting

## Codebase-Specific Patterns

- **Monorepo structure** -- Comments reference specific apps within the turborepo: `apps/livekit-events`, `apps/scheduled-emails`, `apps/react-emails`. Each app has its own infra (Terraform), and she reviews across all layers.
- **Layer architecture** -- Strong enforcement of a data layer / application layer / controller layer separation. The data layer (`src/database/`) should only do raw DB operations. Business logic, parsing, validation, and logging go in the controller or application layer.
- **Infrastructure as code** -- Reviews Terraform files. Expects secrets in Parameter Store, not hardcoded. Wants Datadog agent with process collection enabled.
- **LiveKit / Realtime** -- Deep domain knowledge of the realtime system (rooms, participants, ingress, agents). Knows edge cases like agents not joining rooms, rooms staying open too long, and participant state management.
- **PostgreSQL** -- Reviews raw SQL queries for correctness, knows CTE optimization behavior (MATERIALIZED vs non-materialized), and catches incorrect JOIN logic.
- **Parse, don't validate** -- Advocates for parsing events upfront rather than checking individual fields, and has shared the canonical blog post on this pattern.
- **SQS / Lambda** -- Backend services run on AWS Lambda triggered by SQS. Infrastructure is defined in Terraform.

## Representative Example Comments

**Correcting business logic:**
> "so the condition is not around the room min age, it's about how long each participant has been watching. should be - if at least 2 participants have been watching for at least 5 mins each of them"

**Demanding constants over magic numbers:**
> "why exactly 3? we should also put all these numbers in constants. the logic sebastian wanted said at least 2 and for longer than 5 minutes, per your notes in the ticket"

**Teaching through function design:**
> "let's be more thoughtful about these names - function name and type. this function returns user info given user ids. adding ByUserIds is redundant because you can see that from the argument. [...] function signatures are very important and if done correctly are self documenting."

**Flagging serious data logic bugs:**
> "this is suuuuper wrong. this will do a super set of all conversations and all rooms for the same user. What you need to do is get a 1:1 mapping of conversation to realtime room like we discussed"

**Enforcing layer separation:**
> "+1 to lukasz my concern was just with passing the userId as a string instead of string|null, I prefer the previous approach + fixing the type and passing it as it is supposed to be inserted. The data layer should have one responsibility taking what is given and inserting into db. no transformations, no parsing."

**Catching dead code:**
> "this is not used anywhere"

**SQL optimization knowledge:**
> "the live_to_recording is only referenced once so using materialized here i don't really think makes sense. using materialized makes sense when the cte is referenced multiple times or you want to force an evaluation order, otherwise using it prevents any query optimizations postgres does (like pushing predicates from outer queries into ctes) and also it gets forced to evaluate fully before moving to next query"

**Eliminating redundancy:**
> "i don;t see any reason to maintain both prefix and type. you can easily use type- to get userid"

**Architectural preference stated plainly:**
> "I would just throw from parse and wrap this logic in a try catch instead of handling each field"

**Nit-level formatting:**
> "nit: can you fix the formatting for this query"

**Calling out AI slop:**
> "please clean up these ai generated comments"

**Sharing learning resources:**
> "when you have time, this is a really great article that explains this: https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/"

**Visceral reaction to bad code:**
> "oh god what bullshit"

**Brief agreement:**
> "+1"

**Deferring to a follow-up:**
> "will do in a followup"

## Approval Signals

Mara approves with minimal ceremony. Her PR-level review bodies are terse: "reviewed" or "reviewed. please ask theo to review the infra". A clean PR from Mara's perspective would:

- Have no dead code or unused imports
- Not duplicate logic that already exists in the codebase
- Keep the data layer thin (no business logic in database functions)
- Use constants instead of magic numbers and config/parameter store instead of hardcoded values
- Match the spec or ticket requirements exactly
- Use consistent naming that aligns with existing domain concepts (e.g. LiveKit event names)
- Have clean SQL with correct JOINs and no unnecessary MATERIALIZED CTEs
- Not contain AI-generated boilerplate comments

When she has few or no inline comments, the PR gets a quick "reviewed" and approval. Heavy comment counts (10-28 per PR) indicate the PR needs significant rework, usually around incorrect business logic, layer violations, or data correctness issues.
