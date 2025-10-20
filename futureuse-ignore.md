## 8. Testing & Verification
- Add focused unit tests when introducing non-trivial business logic (e.g., calculations, scheduling rules).
- Provide inline sample usage or preview snippets for complex views.
- Run `xcodebuild -scheme Sherpa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test` before handing off major feature work.

## 10. Prepare for the Future Hardening Pass
Document TODOs that should happen during the Swift 6 upgrade sprint:
- Enable `SWIFT_VERSION = 6.0` and `SWIFT_STRICT_CONCURRENCY = complete`.
- Turn the lint/format rule set and CI workflow back on.
- Add security reviews for Supabase/auth flows and implement automated tests around critical async paths.
