# Smart-Park Repository Audit Report

**Repository:** [MuhammadUmairSattar/Smart-Park](https://github.com/MuhammadUmairSattar/Smart-Park)  
**Repository ID:** `1465552909`  
**Audit refreshed:** 2026-11-23  
**Current branch:** `main`  
**Current repository commit observed:** `6b0909c2060df4cb2f7080438d7f2ef063cb1f16`  
**Application source snapshot reviewed:** `a4dd2b25ca532fa602f081ccb333e3f2ef9c10b0`  
**Audit type:** Read-only inspection; no application code executed.

> This replaces the previous audit text. It corrects the workflow-path assessment, distinguishes the latest repository commit from the latest application-source commit, and states clearly where exact LOC and visibility-history facts cannot be established from the available API evidence.

## Executive Summary

Smart-Park is a Flutter/Dart parking-operations application with offline SQLite ticket handling, user authentication and refresh sessions, biometric unlock, HMAC-signed QR tickets, VIP-pass support, tariff calculations, reporting, and two backend implementations: Express/PostgreSQL and Cloudflare Workers/D1. The repository has standard Flutter platform scaffolding and a small set of tests. The code review confirms several meaningful features are implemented; it does not prove that the product is deployed or production-ready.

The repository is **public** as of this audit and declares the MIT license. The README advertises 22+ languages, while the inspected localization code defines three (English, Urdu, and Arabic). This is a material documentation mismatch. The current report commit is unsigned/unverified in GitHub's commit response; that status alone does not establish that the commit or content is fraudulent.

Security and release concerns include embedded development fallback secrets, broad CORS settings, absent visible branch/operator ownership checks on ticket actions, possible diagnostic detail leakage, a non-durable Express fallback mode, and no verified test/build/deployment results. There is a correctly located GitHub Actions workflow at `.github/workflows/ci_build.yml`; a similarly named duplicate exists at `github/workflows/ci_build.yml`, which is not the standard Actions discovery path.

**Recommendation:** Treat the repository as a prototype or controlled staging project until secret handling, authorization, backend deployment, and actual build/test verification are addressed. The report does not claim exact raw, eligible, excluded, or original LOC because no local clone/counting tooling was available.

## 1. Scope, Sources, and Confidence

Evidence examined in the prior and current audit context:

- GitHub repository metadata and language byte statistics
- Recursive tree of `main`
- `README.md`, `LICENSE`, `pubspec.yaml`, CI workflow
- Representative application, test, and backend source files
- Commit metadata for the repository's first application commit, latest application commit, and current report commit

**Not performed:** application execution, dependency installation, local LOC scan, static-analysis run, vulnerability scanner, source-similarity scan, device build, backend deployment, or penetration test. Security observations are source-review findings, not exploit demonstrations.

## 2. Repository Facts and Visibility

| Item | Finding | Status |
|---|---|---|
| Repository | `MuhammadUmairSattar/Smart-Park` | Verified |
| Repository ID | `1465552909` | Verified |
| Current visibility | **Public** (`private: false`, `visibility: public`) | Verified from current GitHub metadata |
| Default branch | `main` | Verified |
| License | MIT License | Verified in `LICENSE` and repository metadata |
| GitHub primary language | Dart | Verified |
| Fork / archived / disabled | Not a fork; not archived; not disabled | Verified |
| GitHub-reported repository size | 467 KB on refreshed metadata | Verified; GitHub's repository-size field, not total checkout size |
| Last pushed time in refreshed metadata | 2026-11-23 03:41:23Z | Verified |
| Visibility history | No transition record was available in the evidence reviewed | **Unverifiable** |

### Public/private history

The repository is public now. The available repository metadata and commit list do not show a public/private transition audit event. There is no sufficient evidence to say whether it was previously private or to provide an exact date on which a visibility change occurred. Current public visibility must not be presented as proof of continuous public visibility.

## 3. Repository Size, File Inventory, and LOC

The recursive tree response examined during the audit reported **184 blob/file entries** and **44 tree/directory entries** (228 total entries). This is the inventory at the inspected tree snapshot; report-file changes can alter the current count. The tree inventory includes platform setup, configs, tests, assets, and generated files, not just authored source.

| Metric | Result | Interpretation |
|---|---:|---|
| Tracked file entries at inspected source snapshot | 184 | Recursive-tree blob count; not source-only |
| Directory entries at inspected source snapshot | 44 | Recursive-tree tree count |
| Total tree entries | 228 | Files plus directories |
| Raw LOC | Not counted | Exact count requires local checkout or a counting service/tool |
| Eligible authored source LOC | Not counted | Must exclude templates, generated files, localization, assets, and third-party material |
| Excluded LOC | Not counted | Same limitation; exclusions are identified qualitatively below |
| Verified original LOC | Not counted | Requires content-level provenance and similarity review |

### Why LOC is not reported as a number

GitHub's language percentages and byte totals are not LOC. The available tools provided file contents and tree metadata but did not provide a local shell, `cloc`/`tokei`, or a reliable full-repository line-count operation. Supplying numerical raw, eligible, excluded, or verified-original LOC would therefore be unsupported. A precise follow-up requires a local checkout, a documented extension/path exclusion list, and a provenance review. This is a limitation of the evidence, not a claim that the source is absent.

### Candidate source inventory for a local LOC pass

- **Dart application and tests:** `lib/main.dart`, `lib/core/app_core.dart`, `lib/core/themes.dart`, `lib/features/auth/auth_screen.dart`, `lib/features/parking/parking_logic.dart`, `lib/features/parking/dashboard_screen.dart`, `lib/features/parking/receipt_screen.dart`, `lib/features/parking/settings_screen.dart`, `test/widget_test.dart`.
- **JavaScript backends:** `backend/server.js`, `backend_cf/src/index.js`.
- **Kotlin:** `android/app/src/main/kotlin/com/umairsattar/smartpark/smart_park_pro/MainActivity.kt`.
- **Swift / Objective-C:** iOS and macOS platform glue; much of this is Flutter-generated scaffolding and should not automatically be counted as original app logic.
- **C/C++/CMake:** desktop platform runners and generated plugin registration/build integration; classify generated registrants separately from handwritten runner code.
- **Configuration:** Gradle Kotlin DSL, CMake, Xcode project, Wrangler, and Actions YAML. Report separately from application LOC.

### Language-wise GitHub byte composition

GitHub's language endpoint reported the following byte counts. These are not LOC and should not be read as originality percentages.

| Language | Bytes | Approx. share |
|---|---:|---:|
| Dart | 145,460 | 67.6% |
| C++ | 24,552 | 11.4% |
| CMake | 19,762 | 9.2% |
| JavaScript | 19,276 | 9.0% |
| HTML | 2,118 | 1.0% |
| Swift | 2,044 | 0.9% |
| C | 1,488 | 0.7% |
| Kotlin | 158 | <0.1% |
| Objective-C | 38 | <0.1% |

This explains the supplied composition's rounding/grouping: GitHub separately reports C and Objective-C, while the user-provided summary grouped small categories as “Other.” The source inventory reviewed did not identify PHP, TypeScript, or Python source files; this is not a guarantee about uninspected/untracked content.

## 4. Purpose and Stack

### Purpose

A parking attendant/operator application for issuing parking tickets, recording check-in/check-out, calculating fees, supporting offline operation, and syncing ticket changes to a REST backend. The mobile app also includes configuration, localization, QR, and reporting features.

### Stack

| Component | Evidence in repository |
|---|---|
| Flutter / Dart | `pubspec.yaml`, `lib/` |
| State management | Riverpod (`flutter_riverpod`) |
| HTTP | Dio |
| Local persistence | SQLite (`sqflite`), SharedPreferences, FlutterSecureStorage |
| Connectivity | `connectivity_plus` |
| Biometrics | `local_auth` |
| OCR | `google_mlkit_text_recognition` dependency and dashboard feature references |
| QR | `mobile_scanner`, `barcode_widget`, app/backend HMAC routines |
| Reports | `pdf`, `printing`, CSV generation |
| Node backend | Express, PostgreSQL (`pg`), JWT, Node crypto |
| Edge backend | Cloudflare Worker, D1, Web Crypto |
| Platform projects | Android, iOS, macOS, Linux, Windows, Web |

## 5. Implemented Features and Claim Checks

### Confirmed in source

- **Application startup and providers:** `lib/main.dart` initializes localization, preferences, database and stored session.
- **Authentication:** `ApiService` in `lib/core/app_core.dart` contains login, registration, refresh, secure token persistence, and Dio authorization/refresh behavior.
- **Biometric unlock:** `lib/features/auth/auth_screen.dart` uses `local_auth` and a saved session.
- **Local ticket and VIP persistence:** `ParkingDatabase` in `lib/features/parking/parking_logic.dart` defines `tickets`, `sync_queue`, and `vip_passes` tables and related operations.
- **Offline sync:** `ParkingNotifier` listens to connectivity and sends queued ticket operations.
- **Tariffs:** `ParkingTicket.calculateSubtotal()` and `calculateTotalFee()` calculate grace-period, base/hourly, and tax amounts.
- **QR signing:** `QrCryptoService` builds/signs payloads and compares signatures in constant-time; tests cover tampering.
- **CSV export:** `ParkingNotifier.buildCsvReport()` constructs report content.
- **Tests:** `test/widget_test.dart` has fee, QR, local persistence/queue, and auth-validation tests.
- **Two backend implementations:** `backend/server.js` and `backend_cf/src/index.js` implement auth and ticket routes.

### Claims not established as production behavior

- README advertises **22+ languages**. `AppLocalizations.supportedLanguages` in `lib/core/app_core.dart` contains exactly three: English, Urdu, Arabic. No localization directory with 22+ translated locales appears in the reviewed tree.
- README advertises 50 themes. Theme source exists, but this audit does not assert an exact preset count without recounting the full theme file.
- OCR/ANPR source integration is not evidence of real-world plate recognition accuracy, “real-time” performance, or verified regional coverage.
- PDF/printing packages and receipt source do not verify compatibility with a specific thermal printer/device.
- An API client/backend implementation does not prove the configured external service is live or deployed.
- VIP passes and branch settings in local source do not by themselves establish multi-tenant SaaS isolation or cloud administration.

## 6. Build and CI Readiness

### Corrected workflow assessment

The inspected recursive tree contains both:

- `.github/workflows/ci_build.yml` — standard GitHub Actions workflow location
- `github/workflows/ci_build.yml` — duplicate under a nonstandard top-level directory

The `.github/workflows/ci_build.yml` file runs dependency retrieval, Flutter analysis, tests, and an Android APK build. Therefore, the earlier statement that the only CI file was in the wrong directory was incorrect. The duplicate `github/` path is not the standard discovery location. No Actions run/job result was retrieved, so workflow success and actual build readiness remain unverified.

### Build evidence

The manifests and platform files provide a plausible Flutter build setup. No command was run in this audit. The following remain **unverified**:

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- Android APK build
- iOS, macOS, web, Linux, or Windows builds
- backend tests or deployment
- Cloudflare bindings/D1 setup
- runtime OCR and biometric behavior
- physical receipt printing

`pubspec.yaml` permits Dart `>=3.4.0 <4.0.0` and declares `intl: any`; pinning and reproducibility should be reviewed in dependency management. `pubspec.lock` exists, but no dependency vulnerability or license scan was run.

## 7. Git History, Contributors, and Commit Authenticity

### First and latest commits

The date and author details distinguish the latest **repository** commit (the previous report creation) from the latest reviewed **application source** commit.

| Role | Author name | GitHub username / numeric ID | Profile | Commit URL | Date (UTC) | GitHub signature status |
|---|---|---|---|---|---|---|
| First visible commit | MuhammadUmairSattar | `MuhammadUmairSattar` / `344566430` | [github.com/MuhammadUmairSattar](https://github.com/MuhammadUmairSattar) | [Initial commit `4eb5cbb299150ff1cc5c668fd682f4ba6610d327`](https://github.com/MuhammadUmairSattar/Smart-Park/commit/4eb5cbb299150ff1cc5c668fd682f4ba6610d327) | 2026-11-20 14:52:59 | Verified |
| Latest application-source commit reviewed | MuhammadUmairSattar | `MuhammadUmairSattar` / `344566430` | [Profile](https://github.com/MuhammadUmairSattar) | [Commit `a4dd2b25ca532fa602f081ccb333e3f2ef9c10b0`](https://github.com/MuhammadUmairSattar/Smart-Park/commit/a4dd2b25ca532fa602f081ccb333e3f2ef9c10b0) | 2026-11-22 13:48:57 | Verified |
| Latest repository commit observed | MuhammadUmairSattar | `MuhammadUmairSattar` / `344566430` | [Profile](https://github.com/MuhammadUmairSattar) | [Report commit `6b0909c2060df4cb2f7080438d7f2ef063cb1f16`](https://github.com/MuhammadUmairSattar/Smart-Park/commit/6b0909c2060df4cb2f7080438d7f2ef063cb1f16) | 2026-11-23 03:41:23 | **Unverified/unsigned** |

The report commit's GitHub response identifies the linked author account `MuhammadUmairSattar` (ID `344566430`) but signature verification is false. GitHub web-flow commits may use a different committer identity than their author. Verification status describes cryptographic signature verification; it does not independently establish whether the author identity or code is truthful.

### Contributors

The repository contributor endpoint reported:

- `MuhammadUmairSattar` — 72 contributions, account ID `344566430`
- `bot` — 1 contribution, account ID `58210622`

A bot-attributed initialization commit exists. Contributor counts are GitHub's contribution accounting, not a complete legal authorship statement.

## 8. Originality, Templates, AI Indicators, and Ownership

### Templates and generated content

The repository has conventional Flutter platform directories and generated/template content: Android Gradle/platform setup, iOS/macOS project and asset structure, Linux/Windows runner scaffolding, web manifest/icons, and generated plugin registrants. Generated files such as `linux/flutter/generated_plugin_registrant.cc`, `windows/flutter/generated_plugin_registrant.cc`, and `macos/Flutter/GeneratedPluginRegistrant.swift` should be excluded from an authored-original LOC figure unless modifications are independently established.

No vendored dependency tree was observed in the inspected recursive tree. That does not prove all application source is original; similarity search or upstream comparison was not performed.

### AI-assisted code indicators

Rapid, regular commits, unusually polished broad implementations, highly descriptive messages, and a bot initialization commit may be consistent with automated or AI-assisted work. **These are not proof of AI generation.** No detector, source comparison, or author interview was performed. Do not treat stylistic indicators as a factual attribution.

### Ownership and licensing

- `LICENSE` contains MIT terms and copyright `(c) 2026 Muhammad Umair Sattar`.
- Repository metadata reports MIT.
- This supports the repository's declared license, not a legal finding that the owner holds rights to every contributed/generated asset.
- No separate dependency `NOTICE`/license inventory was found in the tree reviewed.
- Platform scaffolding and third-party dependencies may have their own licensing obligations.
- README's “All Rights Reserved” wording should be clarified against the repository's MIT grant; branding and code licensing can be distinct, but the README should say so explicitly.

## 9. Security Review Findings

These findings arise from reading source. No exploit, dynamic test, or third-party vulnerability scan was performed.

### High priority

1. **Development fallback secrets must not reach production.**
   - `lib/core/app_core.dart` has a placeholder default QR HMAC secret.
   - CI YAML uses a fallback secret when the repository secret is not set.
   - `backend_cf/src/index.js` uses fixed default strings for JWT and refresh secrets.
   - Enforce required secrets at deployment/startup and rotate any value that has been used outside isolated testing.

2. **Ticket ownership/branch authorization should be explicit.**
   - Ticket insert and checkout routes authenticate the caller, but the reviewed implementation does not visibly enforce that ticket/branch ownership matches the JWT claims.
   - Validate caller role and branch server-side; never rely on client-supplied branch/operator values as authorization.

### Medium priority

3. **Permissive CORS.** Cloudflare `corsHeaders()` returns `Access-Control-Allow-Origin: *`; Express uses `cors()` without a restrictive origin policy. Restrict origins where browser access is expected.

4. **Internal error detail in responses.** Cloudflare's 500 response includes an error detail string. Return a generic external message and retain sanitized server-side logs.

5. **Express's in-memory fallback is non-durable.** `backend/server.js` uses maps when `DATABASE_URL` is absent, losing stored state on restart and not supporting shared multi-instance state. Fail closed or clearly limit it to development.

6. **No visible throttling.** Reviewed login/register routes do not show rate limiting or lockout controls. Add abuse protection and monitoring.

7. **Password policy is minimal.** Both backend implementations accept passwords at six characters; revisit length, abuse detection, and account recovery policy.

8. **Database lifecycle.** Cloudflare creates schema lazily from request handling; there is no visible versioned migration/rollback process.

### Additional hardening

- Express PostgreSQL connection uses `ssl: { rejectUnauthorized: false }`; require certificate verification in production.
- Refresh-token rotation/revocation is not backed by a server-side token registry in the reviewed source.
- QR signature output is truncated to 16 hex characters. Review threat model and protocol before relying on it for high-value use.
- Review response-body validation, request-size limits, audit logging, data retention, and personal-data handling before deployment.

## 10. Placeholders and Quality Assessment

### Potential placeholders / unfinished deployment configuration

- API base URL defaults to `https://api.smartpark-enterprise.com/v1`; source alone does not prove this is a live or controlled production service.
- Express's in-memory mode is explicitly temporary.
- Environment/secret setup for consistent client and backend QR HMAC keys is not operationally documented.
- No evidence of production Cloudflare deployment, production database configuration, or signed release is included in the audited evidence.

### Quality strengths

- App code is organized under `lib/core` and `lib/features`.
- Riverpod providers separate key state services.
- Local database and sync queue are explicit.
- HMAC comparison uses a constant-time loop.
- Reviewed SQL operations use bound/parameterized values.
- Tests cover calculations, QR tamper rejection, persistence, queueing, and auth validation.

### Quality limitations

- Test coverage is small relative to app and backend surface.
- Two backend implementations duplicate logic and may drift.
- No backend test suite or API schema/contract was identified in the inspected tree.
- Several larger source files combine domain logic, persistence, networking, and state handling.
- CI configuration exists, but no successful run was verified.

## 11. Risk Matrix

| Severity | Finding | Evidence / impact |
|---|---|---|
| High | Fallback/placeholder cryptographic secrets | App config, CI fallback, Cloudflare defaults |
| High | Authorization ownership checks not evident | Ticket create/checkout API source |
| High | Production status/build not established | No executed builds, tests, or deployment evidence |
| Medium | Wildcard/permissive CORS | Cloudflare and Express setup |
| Medium | Internal exception detail returned | Cloudflare 500 handler |
| Medium | Non-durable backend fallback | Express memory maps when no DB URL |
| Medium | README language count mismatch | 22+ claim vs. 3 source locales |
| Medium | Lack of visible rate limiting | Auth handlers |
| Low/Medium | Dependency licensing and attribution not inventoried | No `NOTICE`/license inventory observed |
| Low | Unsigned report commit | GitHub verification false; not proof of maliciousness |

## 12. Final Recommendation and Action Plan

**Conditional hold for production.** Appropriate for a prototype, educational/portfolio demonstration, or controlled staging with non-sensitive data; do not rely on this audit as a security certification.

Prioritized steps:

1. Remove fixed/default secret fallbacks; require environment-managed secrets and document rotation.
2. Enforce server-side tenant, branch, role, and ticket ownership on every mutation/read route.
3. Restrict CORS, sanitize 500 responses, and configure request limits and abuse protection.
4. Disable the Express in-memory mode outside explicit development/test runs; require verified TLS.
5. Add migrations, backend tests, API contract tests, and a successful CI build record.
6. Run Android/iOS builds and validate biometric, OCR, offline replay, and printer behavior on representative devices.
7. Correct the README's language count or implement and test the advertised locales; validate theme counts too.
8. Create dependency license/NOTICE inventory and clarify MIT scope versus branding/copyright language.
9. Obtain exact source LOC with a local checkout and a reproducible counting policy, then classify generated/template/localization/external code separately.
10. Use a similarity/provenance review before making strong originality or ownership claims.

## 13. Evidence Limitations

- Exact raw/eligible/excluded/verified-original LOC values were not calculated; no local clone or LOC tool was available.
- GitHub language byte percentages are not LOC and do not prove source originality.
- No source similarity, AI provenance, dependency vulnerability, or dependency-license scan was run.
- No app code was executed; CI, build, tests, backend, OCR, biometric, and printing behavior are unverified.
- Current public visibility is verified; prior visibility and any exact public/private transition date are not verifiable from the available metadata.
- Commit identity/signature observations describe GitHub metadata only, not a legal or personnel identity verification.
