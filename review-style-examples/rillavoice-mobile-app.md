# Mara's PR Review Style — rillavoice/mobile-app

_Generated from 126 review comments across rillavoice/mobile-app_

## Voice & Tone

Extremely casual and direct. Uses lowercase throughout, abbreviations ("pls", "imo", "rm", "wdyt", "u"), and sometimes slang or emotional shorthand ("u tripping", "no bueno", ":("). Comments are often terse — a single word ("tailwind", "i18", "same") or a short question ("why usememo?"). When something is wrong, the tone sharpens with question marks ("???", "why is this in this pr???"). Longer comments are reserved for architectural issues or multi-part suggestions, and even then they stay conversational — no formal phrasing, no pleasantries.

## Severity Vocabulary

- **`nit:` / `nit`** — minor style or preference issues: "nit could do isNonEmptyArray(selectedGifs)", "nit: pull this up in a function"
- **`#suggestion:`** — non-blocking improvement ideas: "#suggestion: move these numbers into constants", "#suggestion: take out the render function from flashlist to make it more readable"
- **`+1`** — agreeing with another reviewer's comment
- **`??` / `???`** — signals confusion or disbelief that something exists: "??", "why is this in this pr???"
- **Merge blockers** — stated directly: "we should not merge this pr before this is changed", "I actually don't want us to merge this PR until we have this route"
- **No formal labels** for most comments — severity is inferred from tone and directness. A bare "tailwind" is a standard expectation, not a nit.

## What I Always Flag

- **Tailwind/NativeWind usage** — inline styles or StyleSheet usage when tailwind classes exist. Single-word "tailwind" is the most frequent comment in the history.
- **i18n** — hardcoded user-facing strings. Flagged with just "i18" or "i18 handles that".
- **clsx for conditional classes** — "you should be able to put this in clsx", "tailwind +clsx"
- **Functions recreated every render** — callbacks defined inline in render without useCallback or extraction: "these will get recreated on every render", "this function will get recreated on every render"
- **Unnecessary state and effects** — "I don't think you need this useffect or the openPaywallModal state", "why usememo?"
- **Code reuse** — points out existing components that can be reused: "why can't you use RecordingRealtimeCommentsList?", "i think you can reuse the component from the recording screen"
- **Naming clarity** — pushes for names that reflect the feature domain: "can we rename this to LIVE_CHAT_HISTORY?", "I think ChatHistory is not super clear"
- **Boolean logic complexity** — catches compound conditions that hide bugs: "hasNoAccess = !hasRealtimeAccess && isLoading; so this becomes isLoading && !hasRealtimeAccess", "that is no bueno, easy to introduce bugs"
- **Loading/empty states** — "we don't have this pattern anywhere else. should show either a skeleton or a loading indicator", "no loading indicator, so users won't know a request is in flight"
- **Magic numbers** — wants them in constants: "#suggestion: put all numbers in constants", "-mt-10??? u tripping"
- **`interface` over `type`** — "prefer interface"
- **Design tokens** — "this is prob a token", "token if possible"
- **Scope creep** — changes that don't belong in the PR: "why is this in this pr???", "this should be a Dif pr"
- **Web/mobile parity** — checks if behavior matches the web app: "is this the same event we have on web", "do we not persist the rep message like we do on web?"
- **Silent error handling** — "i don't like this silent conversion. you can get the error from tanstack and handle this on the component side where you have better context for the UI"
- **Unnecessary analytics** — "you don't need mixpanel tracking. we use mixpanel to track user behavior, this could be at max logged, but imo not necessary"
- **Consistency with existing patterns** — "we don't use useSuspenseQuery anywhere else why use it here?"

## What I Rarely Flag

- Test coverage — never mentioned in any comment
- JSDoc / code documentation — only flagged once ("Can you add a comment") for an especially confusing line
- Import ordering or formatting
- Git commit messages or PR description quality
- Security concerns
- Accessibility — mentioned once ("tested accessibility?") but not a recurring pattern
- Performance beyond render-cycle issues (no comments about bundle size, lazy loading, etc.)
- CSS specificity or style architecture beyond "use tailwind"

## Codebase-Specific Patterns

- **React Native + NativeWind** — the app uses NativeWind (Tailwind CSS for React Native). Inline `StyleSheet` or style objects should be tailwind classes.
- **clsx** — conditional class composition utility; expected to be used instead of ternary style objects.
- **i18next** — all user-facing strings must go through i18n, including plurals (`i18next.com/translation-function/plurals`).
- **TanStack Query** — data fetching layer. Knows patterns deeply (enabling/disabling queries, error handling, suspense queries). Flags `useSuspenseQuery` since the codebase doesn't use it elsewhere.
- **gorhom Bottom Sheet** — aware of animation timing issues (dismiss → present race conditions).
- **Reanimated** — shared values shouldn't be in useEffect dependency arrays; they're stable references.
- **FlashList** — prefers extracting renderItem functions for readability.
- **Mixpanel** — analytics layer. Pushes back on unnecessary or duplicate tracking events. Checks for web/mobile event parity.
- **Design tokens** — hardcoded colors/spacing should reference tokens.
- **Mobile release cadence** — aware that mobile releases are less frequent than web, which affects merge decisions ("I actually don't want us to merge this PR until we have this route because of how we release mobile").
- **`isNonEmptyArray` / `NonEmptyArray<T>`** — codebase utility for type-safe array checks.

## Representative Example Comments

> "tailwind"

> "i18"

> "+1"

> "you should be able to put this in clsx"

> "nit could do isNonEmptyArray(selectedGifs)"

> "#suggestion: move these numbers into constants"

> "these will get recreated on every render"

> "i don't like this silent conversion. you can get the error from tanstack and handle this on the component side where you have better context for the UI"

> "I see, your hasNoAccess already has !isLoading in it. that is no bueno, easy to introduce bugs - as can be seen here"

> "I think we can make a few simplifications: you can use `useRef` instead of `useState` for `hasStartedAnimation` since you don't need a re-render when it changes. also, shared values shouldn't be in the useEffect dependency array - they're stable references and reanimated doesn't want them there. lastly, you can use `toastLeftOffset` directly instead of storing it in the `slideDistance` variable. the dependency array should just be `[hasRequestedHelp, isInitiallyCollapsed, toastLeftOffset]`."

> "we should not merge this pr before this is changed"

> "-mt-10??? u tripping"

> "why is this in this pr???"

> "we don't use useSuspenseQuery anywhere else why use it here?"

> "i don't see a strong reason to keep this named as pinned prompts this is the only place pinned prompt is mentioned and it's confusing. if it's confusing on the web i don't think we should do the same in mobile just for the sake of consistency"

## Approval Signals

- PR follows existing codebase patterns (tailwind, i18n, proper TypeScript types with `interface`)
- No unnecessary state, effects, or re-renders — clean React patterns
- Functions are properly memoized or extracted
- Feature parity with web is maintained or intentionally different with justification
- Changes stay within PR scope — no drive-by refactors or unrelated files
- Loading and error states are handled with skeletons or indicators
- Naming is clear and domain-specific
- Magic numbers are in constants, hardcoded strings are in i18n
