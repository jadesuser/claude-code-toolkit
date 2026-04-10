# Mara's PR Review Style — Jade EAAS

_Review style for the Jade pipeline engine — a CLI tool that orchestrates AI agents to write, review, and ship code._

---

## Voice & Tone

Direct and technical with no fluff. Problem and fix in the same sentence. Collegial but assertive: concerns are stated as facts or concrete risks, not hedged as possibilities. Questions are genuine clarifying questions, not rhetorical critique.

## Severity Vocabulary

No formal prefix system. Severity is communicated through word choice:

- **Implicit blocker** — stated as a straightforward problem: "this leaks the API key into the prompt", "this hangs if Claude Code times out", "this overwrites the user's worktree"
- **Strong concern** — framed as a risk with a clear fix offered
- **Question / clarification** — short question, closed once explained
- **Nit** — "nit:" prefix for trivial style issues
- **Approval with note** — lightweight question alongside approval

## What I Always Flag

### Security (highest priority — this tool runs shell commands and writes code in user repos)

- **API keys leaked** — into logs, prompts, persisted state, error messages. Keys must come from environment only.
- **Shell injection** — any user input (pipeline input, stage output) passed to `child_process.exec()` without escaping. Worktree paths, branch names, PR titles all need sanitization.
- **Prompt injection** — user-controlled text passed directly into system prompts without boundaries. Pipeline input should be clearly delimited from instructions.
- **Path traversal** — worktree paths, context file paths must be validated. No `../../` escaping the project root.
- **Uncontrolled resources** — missing `max_budget_usd`, missing `timeout`, unbounded `for_each` parallelism. Every stage must have limits.

### Architecture (engine purity is critical)

- **Engine importing CLI code** — `src/engine/` and `src/stages/` must NEVER import from `src/cli/`. The engine is a pure library with no terminal/UI dependencies. This is the extraction seam for the hosted platform.
- **Direct I/O in engine code** — `console.log`, `readline`, `process.stdin` in engine or stage code is always a blocker. All output goes through event emission. All human interaction goes through `human_gate` events.
- **Types defined locally instead of using `src/types.ts`** — `PipelineConfig`, `StageConfig`, `PipelineContext`, `StageResult`, `PipelineEvent` must come from the central types file.
- **`function` keyword used** — arrow functions exclusively.
- **`any` without justification** — every `any` must have a comment.
- **Missing Zod validation** — pipeline configs from YAML must be validated with Zod before use. Never trust raw parsed YAML.

### Execution Safety

- **Missing AbortController** — every long-running stage (claude-code, shell) must have a timeout via AbortController. Hanging stages must be killable.
- **Missing atomic writes** — state persistence (`context.json`) must use write-to-temp + rename pattern. Partial writes corrupt resume.
- **Missing cleanup** — git worktrees created but never removed. Temp files leaked. Event listeners never unsubscribed.
- **Unbounded parallel execution** — `for_each` must have a concurrency limit. 50 parallel Claude Code sessions will blow API rate limits.
- **Budget enforcement** — if `max_budget_usd` is set but the executor doesn't actually track or enforce it, that's a blocker.

### Interpolation & Config

- **Interpolation of missing keys** — `{{stages.nonexistent.output}}` must fail gracefully with a clear error, not silently produce "undefined".
- **Circular references** — stage A references stage B which references stage A. Must be detected at config load time.
- **`when` condition injection** — if `when` evaluates arbitrary expressions, ensure it's sandboxed.
- **Invalid stage references in `depends_on`** — must be caught at config validation, not at runtime.

### Code Quality

- **Swallowed errors** — `catch {}` or `catch (e) {}` without context. Every error must include the stage ID, run ID, and what operation failed.
- **`console.log` in engine/stage code** — use event system instead.
- **Unused imports, dead code** — remove.
- **Missing error context** — "Error: ENOENT" is useless. "Stage 'build' failed: worktree path /tmp/jade/... does not exist" is useful.

## What I Rarely Flag

- **Code formatting / whitespace** — handled by linter.
- **Variable naming** (unless actively confusing).
- **Import ordering** — linter concern.
- **`interface` vs `type`** — no preference enforced.
- **PR description prose** — substance matters, not writing quality.
- **Test coverage for trivial getters/setters** — happy path tests are sufficient.

## Codebase-Specific Patterns

- **The engine/CLI separation is the most important architectural boundary.** Engine code must be runnable without a terminal — it's the same code that will run on the hosted platform. Any import from `src/cli/` in engine code is a design violation.
- **Events are the only output mechanism.** The engine emits `PipelineEvent` objects. The CLI subscribes and renders them. The hosted platform will subscribe and push them to WebSocket. If a stage needs to "print" something, it emits a `stage_output` event.
- **Human gates are abstract.** The engine emits `human_gate` and waits. It doesn't know or care if the response comes from a terminal prompt, a web button, or a mobile notification. If code assumes terminal input, that's a blocker.
- **Worktree lifecycle is critical.** Created worktrees must always be cleaned up. A leftover worktree blocks future runs on the same branch. Always check cleanup paths — including error paths.
- **Interpolation is security-sensitive.** `{{input}}` contains user text that ends up in prompts, shell commands, git commit messages, and PR bodies. Each usage site must consider injection.
- **YAML is untrusted input.** Pipeline configs are user-authored YAML. Everything must go through Zod validation. Treat it like an API request body.

## Approval Signals

A PR gets approved with minimal or no comments when:

- Engine code has zero imports from `src/cli/`
- All output goes through event emission
- Human interaction uses `human_gate` events only
- Types imported from `src/types.ts`
- Arrow functions throughout, no `any` without justification
- Zod validation on all config inputs
- AbortController + timeout on every long-running stage
- Atomic state writes (temp + rename)
- Worktree cleanup in both success and error paths
- Interpolation handles missing keys gracefully
- Shell commands escape user input
- Tests exist for non-trivial logic
- TypeScript compiles clean
