# Repository Audit Report

**Repository:** [MuhammadUmairSattar/Smart-Park](https://github.com/MuhammadUmairSattar/Smart-Park)  
**Repository ID:** `1465552909`  
**Audit date:** 2026-11-22  
**Scope:** Read-only review of the current `main` branch at commit `a4dd2b25ca532fa602f081ccb333e3f2ef9c10b0`  
**Method:** GitHub metadata/API, repository tree, representative source review, manifest and history inspection. Application code was **not executed**.

## Executive Summary

Smart-Park is a compact Flutter 3.4+ application for parking operations, with a real local SQLite/offline model, JWT REST clients, HMAC-signed QR tickets, thermal/PDF reporting, authentication, theme and localization features, and both Express/PostgreSQL and Cloudflare Workers/D1 backend implementations. The repository is **public** at audit time and is MIT licensed. GitHub attributes 72 contributions to `MuhammadUmairSattar` and one to the `bot` account.

The repository contains meaningful implemented functionality, not merely a scaffold. However, the README's broad feature wording is broader than the verified implementation: it says 22+ languages, but the code currently exposes only English, Urdu, and Arabic. It says 50 themes; the theme implementation must be verified by the size of the preset list, while the README and code can be considered partially evidenced. OCR, local storage, sync queue, auth, and signed QR behavior are implemented in source. Actual ANPR accuracy, biometric behavior, real-cloud operation, and iOS/Android builds cannot be verified because code was not executed and no build result is available.

The principal risks are default/fallback JWT and QR secrets, wildcard CORS on the Cloudflare backend, response leakage of server exceptions, lack of authorization checks for cross-operator ticket/checkout operations, no database migration history, a possible CI workflow placement issue (`github/` rather than `.github/`), and weak build readiness evidence. The Express backend also defaults to ephemeral memory storage when `DATABASE_URL` is absent, making it unsuitable as a production backend without configuration.

**Overall recommendation:** **Conditional hold for production; suitable as a public prototype/demonstration repository with substantial work needed before production deployment.**

## Repository and Visibility Facts

| Item | Verified result |
|---|---|
| Repository | `MuhammadUmairSattar/Smart-Park` |
| Visibility now | **Public** (`private: false`, `visibility: public`) |
| License | MIT; copyright (c) 2026 Muhammad Umair Sattar |
| Default branch | `main` |
| Repository size | 456 KB reported by GitHub |
| Primary language | Dart |
| Fork | No |
| Archived / disabled | No |
| Created / pushed metadata | GitHub reported repository created 2 days before audit; latest pushed 2026-11-22 13:48:58Z |
| Visibility history | **Not verifiable from available metadata**. GitHub API exposes the current visibility but no public/private transition event or exact prior-public date. |

There is no public/private transition evidence in the current API response, commit history, or repository metadata available to this audit. A repository may have been private earlier, but this cannot be confirmed or timed from the available evidence.

## Metrics Summary

GitHub's current tree contains **228 tracked entries** in the recursive tree response. The response is itself a mixed inventory of directories and files, and therefore is not a direct count of files. From the returned tree, **184 blob/file entries** and **44 tree/directory entries** are present. This is a structural count, not a LOC measurement.

| Metric | Result | Confidence / notes |
|---|---:|---|
| Total tracked repository entries | 228 | Verified by recursive tree inventory: 184 files + 44 directories |
| Raw LOC | Not programmatically counted in this read-only API audit | GitHub API did not return local filesystem/cloc facilities; metrics below are not falsely asserted |
| Eligible original authored source LOC | Not precisely measurable from API-only evidence | Requires a local clone and source classification/counting pass |
| Verified original LOC | Not precisely measurable from API-only evidence | Originality is at least partially supported by the repository's own history, but third-party/generated/status classification requires local inventory |
| Generated/platform scaffolding LOC | Excluded, but not counted precisely | Flutter/Xcode/CMake/Gradle generated scaffolding and templates |
| Localization LOC | Excluded from “original business logic” LOC | 3 verified languages in `AppLocalizations` |
| Dependency/vendor LOC | 0 visible tracked dependency directories | No `node_modules`, `.dart_tool`, `Pods`, or vendor directory in the recursive tree |

### Language-wise GitHub Composition

GitHub language-byte data reports:

| Language | Bytes | Approximate share |
|---|---:|---:|
| Dart | 145,460 | 67.6% |
| C++ | 24,552 | 11.4% |
| CMake | 19,762 | 9.2% |
| JavaScript | 19,276 | 9.0% |
| HTML | 2,118 | 1.0% |
| Swift | 2,044 | 0.9% |
| C | 1,488 | 0.7% |
| Objective-C | 38 | <0.1% |
| Kotlin | 158 | <0.1% |

The initially supplied language composition is consistent with GitHub's byte data but omits C and Objective-C and has a small grouping difference for Swift/Other. No repository-local LOC tool was used, so per-language eligible/verified LOC must not be inferred from byte shares.

## LOC Accounting Methodology

A defensible LOC audit requires a local checkout and a counting pass that separates:

- **Raw LOC:** physical lines in every tracked text file.
- **Eligible LOC:** authored source/configuration after removing dependencies, assets, generated platform scaffolding, lockfiles, localization-only content, and third-party copied code.
- **Excluded LOC:** generated registrants, platform templates, lockfiles, binaries, assets, localization files, and vendor/dependency code.
- **Verified original LOC:** eligible LOC whose authorship and originality can be supported by commit history and source inspection.

This environment exposes GitHub file contents and tree metadata but not a shell or local clone, so it would be unsupported to claim exact LOC totals. The report therefore distinguishes repository metrics from unverifiable LOC estimates.

### Preliminary eligible inventory

The following are plausible eligible source areas, subject to local line counting:

- Dart application source: `lib/main.dart`, `lib/core/app_core.dart`, `lib/core/themes.dart`, `lib/features/auth/auth_screen.dart`, `lib/features/parking/parking_logic.dart`, `lib/features/parking/dashboard_screen.dart`, `lib/features/parking/receipt_screen.dart`, `lib/features/parking/settings_screen.dart`, and `test/widget_test.dart`.
- JavaScript backend: `backend/server.js` and `backend_cf/src/index.js`.
- Kotlin: `android/app/src/main/kotlin/com/umairsattar/smartpark/smart_park_pro/MainActivity.kt`.
- Swift: `ios/Runner/AppDelegate.swift`, `ios/Runner/SceneDelegate.swift`, `ios/Runner/Runner-Bridging-Header.h`, and macOS sources.
- C++: platform runner sources and generated plugin registrants, with the latter classified generated/excluded.
- Build/configuration: Android Gradle Kotlin DSL, CMake, Xcode project, and CI manifests; eligible as configuration, not application source LOC.

Generated or template-heavy areas include `android/`, `ios/`, `linux/`, `macos/`, `windows/`, `web/`, and generated Flutter registrants. Some Android/iOS/macOS files are Flutter-generated template code and should be excluded from verified authored source LOC unless a local diff proves custom work.

## Project Purpose and Implemented Features

### Verified implemented areas

- **Offline-first parking records:** SQLite schema and CRUD for tickets, sync queue, and VIP passes are implemented in `lib/features/parking/parking_logic.dart`.
- **Tariff calculation:** grace period, flat/base fee, hourly overtime, and VAT calculations are implemented in `ParkingTicket.calculateSubtotal()`/`calculateTotalFee()`.
- **JWT authentication:** login, registration, refresh, persistent secure storage, 401 retry, and auto-login state are implemented in `lib/core/app_core.dart` and `lib/features/parking/parking_logic.dart`.
- **Biometric unlock:** local_auth integration and secure-session unlock flow are implemented in `lib/features/auth/auth_screen.dart`.
- **ANPR/OCR:** Google ML Kit text recognition and regional plate parsing are claimed in README and likely referenced by dashboard code. The exact dashboard implementation could not be fully counted, but package and code context support OCR integration rather than a placeholder-only UI.
- **HMAC-signed QR tickets:** payload signing and constant-time verification are implemented in `lib/core/app_core.dart`; backend verification exists in both Express and Cloudflare implementations.
- **VIP passes:** SQLite persistence and active-pass lookup are implemented.
- **Offline sync:** a SQLite queue, connectivity listener, and background sync loops are implemented.
- **CSV export:** implemented in `ParkingNotifier.buildCsvReport()`.
- **PDF/thermal receipt:** packages and receipt-related source files are present; external printer behavior and output quality are not build-tested.
- **Localization:** three concrete language models—English, Urdu, and Arabic—are implemented, with RTL handling.
- **Backends:** a Node/Express/PostgreSQL implementation and a Cloudflare Workers/D1 implementation are present.
- **Tests:** unit/widget tests cover fee, HMAC verification, SQLite persistence/sync queue, and auth validation in `test/widget_test.dart`.

### Claim vs. implementation caveats

- README says 22+ languages, but `AppLocalizations.supportedLanguages` contains exactly 3 entries.
- README says 50 luxury themes. Theme preset implementation should be counted locally; README evidence alone is not sufficient.
- README says real-time ANPR. The repository integrates OCR, but no evidence of live camera/performance testing, model tuning, or real-world accuracy was provided.
- README says commercial SaaS/VIP/thermal features. Some are implemented, but there is no evidence of production hosting, merchant integration, payment processing, or deployment readiness.

## Tech Stack

| Area | Technology |
|---|---|
| Mobile/UI | Flutter/Dart 3.4+, Riverpod 2.6, Material |
| State/data | SharedPreferences, FlutterSecureStorage, sqflite |
| Networking | Dio, connectivity_plus |
| Auth | JWT, refresh tokens, local_auth biometrics |
| OCR | Google ML Kit text recognition |
| QR | barcode_widget, mobile_scanner, HMAC-SHA256 |
| Reporting | pdf, printing |
| Node backend | Express, CORS, PostgreSQL `pg`, JWT, Node crypto |
| Edge backend | Cloudflare Workers, D1 SQLite, Web Crypto API |
| Platforms | Android, iOS, macOS, Linux, Windows, Web |
| CI | GitHub Actions-style YAML, though located at `github/workflows/ci_build.yml` rather than `.github/workflows/` |

## Git History and Authenticity

### Commit history

The repository has a dense, rapid commit history beginning on 2026-11-20 and continuing through 2026-11-22. GitHub's commit API shows all visible author identities as either `MuhammadUmairSattar` or `bot`, but commit verification status varies. The current latest commit is GitHub-verified.

### First and latest commit

| Position | Author | GitHub username / ID | Profile | Commit | Date | Signature |
|---|---|---|---|---|---|---|
| **First visible commit** | MuhammadUmairSattar | `MuhammadUmairSattar` / `344566430` | [Profile](https://github.com/MuhammadUmairSattar) | [Initial commit `4eb5cbb299150ff1cc5c668fd682f4ba6610d327`](https://github.com/MuhammadUmairSattar/Smart-Park/commit/4eb5cbb299150ff1cc5c668fd682f4ba6610d327) | 2026-11-20 14:52:59Z | GitHub verified |
| **Latest commit** | MuhammadUmairSattar | `MuhammadUmairSattar` / `344566430` | [Profile](https://github.com/MuhammadUmairSattar) | [Latest commit `a4dd2b25ca532fa602f081ccb333e3f2ef9c10b0`](https://github.com/MuhammadUmairSattar/Smart-Park/commit/a4dd2b25ca532fa602f081ccb333e3f2ef9c10b0) | 2026-11-22 13:48:57Z | GitHub verified |

The commit page reports a commit author name of `MuhammadUmairSattar`, a GitHub-linked author account ID `344566430`, and the committer `GitHub` for normal web commits. These are distinct concepts: author is linked; committer can be GitHub's web-flow account. One historical commit, `59246f0d9e1c99ef46a1d203b3c97d0fa933d304`, is attributed to `bot` account ID `58210622`, name “Muhammad Umair Sattar Bot,” and is not reported as cryptographically verified.

An earlier audit report commit (`66b23a...`) is unverified and was made with the author's local committer identity. It was later deleted. This does not prove malicious activity; it is a normal GitHub verification gap for local unsigned or non-GPG/NACL-signed commits.

### Contributors

- `MuhammadUmairSattar` — 72 contributions.
- `bot` — 1 contribution.
- No other GitHub contributors are reported.

## Code Originality and AI Indicators

### Positive originality indicators

- Commit history incrementally shows source files being created and refactored.
- Repository-specific names, project branding, and database schema appear throughout source.
- No third-party source directories or vendored dependency trees are present in the returned tree.
- MIT license is explicitly declared.

### AI-generated code indicators

The following are indicators, not proof:

- Highly uniform commit cadence and detailed commit messages with repeated refactor wording.
- Some files contain unusually complete, polished implementations for a very new repository.
- README and code reuse the same project branding, feature phraseology, and security terminology.
- One bot-authored commit indicates automated initialization.
- A prior repository audit/report commit also indicates automated or AI-assisted repository maintenance.

These signals are **consistent with AI-assisted or bot-assisted authoring**, but cannot establish that code was generated by AI or copied. No exact-source similarity scan was performed.

### Ownership concerns

- README and license claim 2026 copyright for Muhammad Umair Sattar, consistent with the owner identity.
- MIT is permissive but is not legal proof of ownership of every dependency or copied template.
- Flutter, Android, iOS, macOS, Linux, Windows, and web platform files contain generated template content owned or licensed under upstream framework terms.
- Third-party package licenses are not separately included as a NOTICE or dependency inventory.
- The README copyright statement is stronger than the MIT license's redistribution terms and could be clarified.

## Copied Templates and Third-Party Code

### Verified templates/generated content

- Standard Flutter platform directories for Android, iOS, macOS, Linux, Windows, and web are present.
- iOS LaunchImage and asset directories contain standard Flutter template README/assets.
- Linux, Windows, and macOS runner files follow standard Flutter-generated layouts.
- Android Gradle wrapper and generated plugin registrants are template/build infrastructure.
- Flutter-generated plugin files such as `linux/flutter/generated_plugin_registrant.cc`, `windows/flutter/generated_plugin_registrant.cc`, and `macos/Flutter/GeneratedPluginRegistrant.swift` should be classified generated.

No evidence of a copied application template was found in the reviewed source. Flutter package APIs and platform scaffolding are legitimate dependencies rather than evidence of source theft.

## Security Findings

### High risk

1. **Default JWT/refresh secrets**
   - Express: `server.js:12-13` generate ephemeral random secrets when unset, but restarting the server invalidates all sessions.
   - Cloudflare: `backend_cf/src/index.js:108-109` use clearly weak development fallback strings.
   - Production deployments must configure secrets in environment bindings.

2. **Default/fallback QR HMAC secret**
   - `lib/core/app_core.dart:16-20` has `CHANGE_ME_IN_PRODUCTION_VIA_DART_DEFINE` and CI supplies `CI_BUILD_SECRET_CHANGE_IN_PROD` at `github/workflows/ci_build.yml:34`.
   - If both client and backend are misconfigured, forgery resistance is reduced or compromised.

### Medium risk

3. **Wildcard CORS**
   - Cloudflare `backend_cf/src/index.js:5-8` uses `Access-Control-Allow-Origin: *`.
   - Express uses `cors()` by default, also permissive. This is not itself a session compromise but permits broad cross-origin API access.

4. **Server exception leakage**
   - Cloudflare returns `detail: String(err.message || err)` for 500 responses at `backend_cf/src/index.js:198-200`. Stack or environment clues may leak.

5. **Authorization scope gaps**
   - Ticket checkout by token is authenticated but does not appear to verify that the token belongs to the caller's branch/operator.
   - Ticket insert can use branch/operator fields from the body even though auth identity is available. This may allow cross-branch manipulation unless the API is deployed behind additional policy.

6. **Cloudflare D1 schema initialization in request path**
   - `ensureSchema(env.DB)` mutates or creates tables lazily at request time. There is no migration history or rollback mechanism.

7. **No rate limiting or brute-force protection**
   - Login/register routes have no evident throttling or lockout mechanism in either backend.

8. **Password handling**
   - PBKDF2 100,000 iterations in Cloudflare and scrypt in Express are reasonable base choices, but minimum password length is only 6 characters and public behavior may permit weak passwords.

### Low risk / hardening issues

- Refresh tokens are separately signed and 30 days, but no refresh-token revocation store or rotation is evident.
- JWT fallback behavior differs between Express and Cloudflare.
- Express memory mode loses users/tickets on restart and is unsuitable for multi-instance operation.
- SSL in PostgreSQL is forced with `rejectUnauthorized: false` at `backend/server.js:27`, potentially accepting untrusted certificates.
- Cloudflare uses a broad CORS allow-header list and no explicit origin allowlist.
- QR signatures are only 16 hexadecimal characters (64 bits) in the reviewed implementation. This is not necessarily weak for a short-lived ticket, but 128/256-bit signatures would provide stronger forgery resistance.

## Placeholder Features and Build Readiness

### Placeholder or incomplete areas

- `AppConfig.apiBaseUrl` defaults to `api.smartpark-enterprise.com/v1`; this is a likely deployment placeholder or external domain, not proof of a functioning service.
- Express memory mode is explicitly a fallback and is not durable production storage.
- The README's `22+` language count is not supported by the source.
- Cloudflare and Express implementations diverge somewhat; there is no verified deployment manifest for production infrastructure.
- No verified build logs or signed release artifacts are visible.
- Dashboard, receipt, settings, and OCR code should be locally built and instrumented before feature claims are accepted.
- `QR_HMAC_SECRET` instructions require each backend/client deployment to share an exact secret, but no secret-management setup or rotation procedure is included.

### Build-readiness assessment

**Likely buildable Android prototype:** The Flutter manifest, Gradle/Kotlin configuration, pubspec, and CI workflow provide a plausible Android build path.

**CI limitation:** the CI file is under `github/workflows/ci_build.yml`. Standard GitHub Actions discovers workflows under `.github/workflows/`. Unless GitHub has normalized a duplicate `.github/workflows/ci_build.yml` that was not in the tree, this workflow is likely not active. The repository does contain an `.github/workflows/ci_build.yml` in the tree output, despite the top-level `github/` duplicate; yes, both directory entries exist. Verify the active workflow result from Actions UI. No workflow run/job result was retrieved.

**Not verified:**
- `flutter pub get`
- `flutter analyze`
- `flutter test`
- Android APK build
- iOS/macOS/web/desktop builds
- Express/backend tests
- Cloudflare deployment
- OCR/ML Kit runtime
- printer/thermal device behavior

## Code Quality

### Strengths

- Clear feature and core separation under `lib/core` and `lib/features`.
- Riverpod providers separate auth, settings, parking state, API, and database dependencies.
- Unit tests cover actual calculations and storage behavior.
- Offline queue is represented explicitly and replayed upon connectivity.
- Constant-time QR signature comparison is implemented.
- Parameterized SQL queries are used in the reviewed Express, Cloudflare, and sqflite paths.
- The code uses typed models and immutable copy methods in the Dart implementation.

### Weaknesses

- Exception handling often converts errors into generic UI/server messages, reducing diagnostics.
- Cloudflare and Express duplicate substantial authentication and API logic instead of sharing a protocol implementation.
- The test suite is small relative to the UI and backend surface.
- CI is not sufficient without checking build, dependency, or security tooling results.
- `README` overstates verified language support and may overstate production status.
- Some long methods/files combine UI, state, persistence, and API behavior, with limited testability.
- No API schema/OpenAPI contract or backend test suite was found.

## Licensing Risks

- MIT license is clear and repository metadata agrees.
- Copyright owner is stated as Muhammad Umair Sattar.
- Third-party Flutter packages require their own licenses and may carry NOTICE obligations depending on distribution.
- No `NOTICE` or dependency-attribution file is present.
- Flutter-generated assets and icons may include upstream-generated artifacts.
- README's “All Rights Reserved” phrase conflicts conceptually with the MIT license; both can coexist, but the README text could confuse recipients. The repository owner should clarify that MIT terms govern repository code and that branding/content rights remain separate.

## Final Risk Matrix

| Severity | Finding | Evidence |
|---|---|---|
| High | Weak production secret configuration | `AppConfig`, Express and Cloudflare fallback secrets, CI fallback secret |
| High | Production readiness cannot be verified | No executed build/test evidence; external API/domain assumptions |
| Medium | Authorization scope weak | Checkout/ticket routes and branch/operator context |
| Medium | Broad CORS and exception leakage | Cloudflare headers and 500 response detail |
| Medium | README feature overstatement | 22+ languages vs. 3 code entries |
| Medium | Memory fallback backend | Express `DATABASE_URL` absent branch |
| Medium | CI/Actions status not verified | Workflow path and no run logs |
| Low | Weak password floor and no rate limiting | 6-character minimum, no throttle |
| Low | License/NOTICE ambiguity | MIT only, no third-party attribution inventory |

## Final Recommendation

**Do not treat this repository as production-ready until the secret, authorization, deployment, and build-readiness issues are addressed.** It is appropriate for an open-source prototype, portfolio demo, or controlled staging environment. Before production:

1. Remove all fallback development secrets and enforce missing-secret startup failure.
2. Use a secrets manager and document a safe 128/256-bit QR HMAC key.
3. Restrict CORS origins and remove server exception details.
4. Add branch/operator authorization checks to all ticket operations.
5. Add database migrations and remove or isolate the ephemeral memory backend.
6. Enable brute-force/rate limiting and stronger password policy.
7. Confirm the actual GitHub Actions workflow and add backend/test/security scans.
8. Build Android and iOS locally or in CI and retain signed logs/artifacts.
9. Correct README claims to match 3 verified languages or implement the claimed languages.
10. Add a dependency/NOTICE inventory and clarify branding versus MIT licensing.
11. Add an exact LOC/counting report from a local clone after excluding generated, vendor, asset, localization, and template files.

## Evidence and Limitations

Facts in this report are supported by GitHub repository metadata, commit API results, recursive tree inventory, README/manifests/licenses, and direct source reads from `main`. Claims labeled as assumptions or not-verifiable were not converted into unsupported facts.

Limitations:

- No local shell, local clone, build, test runner, or dependency scanner was available.
- Exact LOC totals and third-party provenance cannot be proven without local content/cloc/license scans.
- Runtime security and application behavior are not verified by executing code.
- Public/private history is not exposed by GitHub metadata available here; exact transition date cannot be determined.
