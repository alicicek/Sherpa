# Sherpa Agents Playbook

Use this guide whenever you generate or modify code for the Sherpa iOS app. The goal is to move fast on features **while** keeping the codebase ready for a future Swift 6 hardening pass.

---

## 1. Project Snapshot
- **Platform:** iOS 17+, SwiftUI + SwiftData, Swift 5 language mode (Xcode 15 toolchain).
- **Current focus:** Ship features quickly; the app is still early (≈18 % complete).
- **Upcoming hardening pass:** Later we’ll migrate to Swift 6, enable strict concurrency, run SwiftLint/SwiftFormat, and bring CI back. Keep today’s code compatible with that future step.

## 2. General Guidelines
1. Match the existing structure and naming in `Sherpa/` (design tokens, logging, helper views). Reuse utilities instead of reinventing patterns.
2. Keep changes scoped and composable. Avoid refactors outside the requested area unless necessary for correctness.
3. No new third-party dependencies without explicit approval.
4. Prefer readable, well-structured code over cleverness. Add short comments only when intent isn’t obvious.
5. Preserve user-facing behaviours (e.g., habit tiles must keep their `simultaneousGesture` scroll behaviour).
6. When working with new APIs, tricky SwiftUI behaviour, or security/network-sensitive code, consult Context7 MCP for the latest Apple documentation and Bright Data MCP for current industry practices before implementing changes.

## 3. Concurrency Expectations (Swift 5 today, Swift 6 tomorrow)
- Use Swift concurrency APIs (`async`/`await`, `Task {}`) instead of GCD where possible.
- Annotate types that touch UI or SwiftData with `@MainActor`.
- Keep shared state immutable or route mutations through an actor/`@MainActor` context.
- Avoid escaping closures that capture mutable state unless the isolation is explicit.
- When scheduling background work (e.g., Supabase sync), hop back to the main actor before updating UI.
- Write code as if `Sendable` checking will be enforced soon—favour value types and thread-safe patterns.

## 4. Security & Privacy Baseline
- **Networking:** Use TLS-only endpoints. Never hardcode API keys or secrets—load from secure configuration or the Keychain.
- **Persistence:** Store tokens/credentials in the Keychain, not `UserDefaults`.
- **Validation:** Treat all remote responses as untrusted—validate JSON/data before persisting or rendering.
- **Logging:** Use the convenience APIs in `Logger+Sherpa.swift`; redact names, emails, or other PII when logging errors.
- **Privacy:** When adding features that need system permissions (camera, mic, notifications, etc.), include clear `Info.plist` usage descriptions.

## 5. SwiftData, Models, and Scheduling
- Reuse `ScheduleService` for generating habit/task instances. Do not duplicate scheduling logic.
- When interacting with SwiftData, respect model isolation and call `try modelContext.save()` at appropriate checkpoints.
- Never create duplicate habit/task instances; rely on the existing guardrails.

## 6. UI & Design
- Use components from `DesignTokens` and existing UI helpers (`sherpaCardStyle`, `SherpaChip`, etc.).
- Maintain the rounded, playful visual style and spacing defined in the design tokens.
- Ensure accessibility labels and identifiers are present on interactive elements (see existing patterns).
- Keep animations subtle and performant; prefer SwiftUI-provided transitions.

## 7. Logging & Error Handling
- Use `Logger.startup`, `Logger.persistence`, `Logger.habits`, or add new categories sparingly.
- Surface recoverable errors to the user with friendly messaging; never crash with `fatalError`.
- For background failures, log with appropriate privacy levels and consider retry/backoff strategies.

## 8. Testing & Verification
- Add focused unit tests when introducing non-trivial business logic (e.g., calculations, scheduling rules).
- Provide inline sample usage or preview snippets for complex views.
- Run `xcodebuild -scheme Sherpa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test` before handing off major feature work.

## 9. Things to Avoid
- No global singletons beyond the existing SwiftUI environment/state objects.
- No ad-hoc thread hopping with `DispatchQueue.main.async` unless strictly necessary.
- Don’t mutate SwiftData models off the main actor.
- Don’t silence compiler warnings; fix the underlying issue instead.
- Avoid speculative optimisations or premature abstraction.

## 10. Prepare for the Future Hardening Pass
Document TODOs that should happen during the Swift 6 upgrade sprint:
- Enable `SWIFT_VERSION = 6.0` and `SWIFT_STRICT_CONCURRENCY = complete`.
- Turn the lint/format rule set and CI workflow back on.
- Add security reviews for Supabase/auth flows and implement automated tests around critical async paths.

---

### Quick Checklist (per task)
1. Understand the surrounding code and reuse existing patterns.
2. Keep concurrency safe (`@MainActor`, structured tasks, immutable state).
3. Ensure security/privacy basics (no secrets, validated data, safe logging).
4. Verify UI/UX matches the rest of Sherpa.
5. Leave notes for anything intentionally deferred to the hardening phase.
