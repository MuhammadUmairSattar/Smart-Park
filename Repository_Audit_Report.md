# Repository Audit Report — Smart-Park

**Repository:** [MuhammadUmairSattar/Smart-Park](https://github.com/MuhammadUmairSattar/Smart-Park)  
**Repository ID:** `1465552909`  
**Audit date:** 2026-11-21  
**Audit mode:** Read-only GitHub API and source inspection  
**Audited revision:** `8d0202a285604e7d94045aa04fbe1e78d0e?` — corrected SHA: `8d0202a285604e7d94045aa04fbe1e70ad4c5b32`

> **Method and evidence rules.** This report distinguishes repository facts, source observations, and assumptions. No application code was executed and no existing repository file was modified. It does not claim a complete third-party/copy scan beyond what the available source evidence permits.

## 1. Executive Summary

Smart-Park is presented as a Flutter smart-parking and token-management application. The repository is currently **public** and is owned by GitHub user [MuhammadUmairSattar](https://github.com/MuhammadUmairSattar) (ID `344566430`). The audited default branch contains an extensive Flutter scaffold, Android/iOS/desktop runner templates, GitHub Actions, and a small set of application Dart modules.

However, the repository is **not build-ready as currently checked out**: `pubspec.yaml` and `lib/main.dart` are inconsistent with one another, and `lib/main.dart` is the default Flutter counter template rather than the Smart-Park entry point shown in `build_app.sh`. The project description and README significantly overstate implemented readiness. Authentication is simulated locally, OCR/QR UI is present, and parking/ticket logic exists in memory, but there is no evidence of a real cloud API or persistent database implementation.

Overall assessment:

- **Build readiness:** Low to moderate, requiring a known-good dependency manifest and regenerated application entry point.
- **Feature maturity:** Prototype/Demo only.
- **Security posture:** Moderate/high risk for production because authentication is fake, a static token is written to secure storage, there is no real backend, and release signing uses debug credentials.
- **Licensing:** High ownership/legal ambiguity because no license is declared and no `LICENSE` file was found.
- **Code authenticity:** 37 of 38 listed commit contributions belong to `MuhammadUmairSattar`; one belongs to `bot`. GitHub reports the initial and latest commits as GitHub-verified commit objects, while the bot commit is not verified.
- **Production recommendation:** Do not deploy. Restore a coherent build, implement real backend/security, add tests, declare licensing, and run signed CI/release builds.

## 2. Repository Purpose and Tech Stack

### Verified purpose

The README and repository description describe a cross-platform parking/token system with ANPR, multiple languages, biometric login, thermal/PDF receipts, and a cloud REST API.

### Actual implemented areas

| Area | Verified implementation | Limitation |
|---|---|---|
| Authentication UI | Email/password, sign-up toggle, local-auth biometric callback | [app_core.dart](https://github.com/MuhammadUmairSattar/Smart-Park/blob/main/lib/core/app_core.dart#L174-L182) and [auth_screen.dart](https://github.com/MuhammadUmairSattar/Smart-Park/blob/main/lib/features/auth/auth_screen.dart#L38-L46) simulate success only |
| Plate/OCR | Camera capture and Google ML Kit text recognition | [dashboard_screen.dart](https://github.com/MuhammadUmairSattar/Smart-Park/blob/main/lib/features/parking/dashboard_screen.dart#L32-L49); regex is basic and no actual ANPR model |
| QR exit | Mobile Scanner checks ticket token | [dashboard_screen.dart](https://github.com/MuhammadUmairSattar/Smart-Park/blob/main/lib/features/parking/dashboard_screen.dart#L246-L265) |
| Parking state | In-memory Riverpod ticket state and hourly fee calculation | [parking_logic.dart](https://github.com/MuhammadUmairSattar/Smart-Park/blob/main/lib/features/parking/parking_logic.dart#L65-L119); state is not persisted |
| Receipts | QR display and 80mm PDF/print layout | [receipt_screen.dart](https://github.com/MuhammadUmairSattar/Smart-Park/blob/main/lib/features/parking/receipt_screen.dart#L53-L86) |
| Languages | 22 language models listed, with English, Urdu, and Arabic translations plus RTL flags | [app_core.dart](https://github.com/MuhammadUmairSattar/Smart-Park/blob/main/lib/core/app_core.dart#L60-L84); many languages fall back to English or a key |
| Cloud API | Dio client with bearer-token interceptor | [app_core.dart](https://github.com/MuhammadUmairSattar/Smart-Park/blob/main/lib/core/app_core.dart#L152-L182); no network authentication call is made |
| Storage | Flutter secure storage dependency | Used for fake token in [app_core.dart](https://github.com/MuhammadUmairSattar/Smart-Park/blob/main/lib/core/app_core.dart#L174-L182); no backend credential storage |

### Tech stack

- **Primary language/framework:** Dart / Flutter
- **State management:** Flutter Riverpod (declared in `build_app.sh`; current `pubspec.yaml` is inconsistent)
- **Android:** Kotlin, Gradle Kotlin DSL, AndroidX/Flutter runner
- **iOS/macOS:** Swift and Xcode project templates
- **Desktop/native:** C++, CMake
- **OCR/biometrics/scanning:** Google ML Kit, `local_auth`, `image_picker`, `mobile_scanner`
- **HTTP/storage/PDF:** Dio, Flutter Secure Storage, PDF/Printing, barcode widgets
- **CI:** GitHub Actions

GitHub language-byte composition reported for the current revision: Shell 43.2%, Dart 27.4%, C++ 14.4%, CMake 11.6%, HTML 1.2%, Swift 1.2%, and Other 1%. GitHub's language API additionally reports C and Objective-C.

## 3. Repository Metrics

| Metric | Result | Confidence |
|---|---:|---|
| GitHub repository size | 460 KB | Verified |
| Default branch | `main` | Verified |
| Tracked files | See table limitation below | Could not be independently enumerated to a final exact count by the read-only API surface used |
| Git history entries | 38 commits | Verified by commit listing/contributor counts |
| Contributors | `MuhammadUmairSattar`: 37; `bot`: 1 | Verified |
| Raw text LOC | Not exact; only GitHub byte counts and per-file source access were available | Not verified as a whole |
| Eligible authored source LOC | Not exact; source candidates are a small Dart subset plus native runner/configuration | Limited |
| Verified original LOC | Cannot be conclusively proven from similarity/licensing evidence alone | Limited |

**File-count limitation:** The GitHub recursive-tree response contains all blob and tree entries, but the audit could not safely derive a final de-duplicated count without a local shell or programmatic traversal. A human request for “comprehensive LOC” should therefore treat exact LOC totals below as structural estimates, not as line counts measured by `cloc` or `git ls-files`.

### LOC classification

| Category | Measured/observed result | Basis |
|---|---:|---|
| Raw LOC in directly retrieved application Dart files | 1,082 lines across `lib/main.dart`, `app_core.dart`, auth, dashboard, parking logic, and receipt | Direct file line ranges; includes template/test only where counted |
| Eligible original application LOC | 951 lines across `app_core.dart`, auth, dashboard, parking logic, and receipt, excluding `lib/main.dart` | Conservative and based on direct retrieval; localization blocks remain separately excluded |
| Localization-excluded LOC | Not exact; app-core file contains 22 language names and approximately 89 English/Urdu/Arabic localization lines | Verified structure; exact claim excluded until line-level localization diff |
| Generated/template/native/lockfile LOC | Excluded from verified originality; includes generated plugin registrants, iOS/macOS assets, runner projects, `pubspec.lock`, and standard Flutter output | Verified by standard generated/template filenames/content |
| Copied/third-party LOC | 0 third-party source LOC verified as copied | Absence of an exact dependency-origin/third-party scan means this is not a complete claim |
| Raw LOC in `build_app.sh` | 1,629 lines, including embedded source and setup commands | Direct file line range |
| Verified original LOC | No definitive final figure | Commit-level and file-level provenance do not prove independent originality |

### Language-wise breakdown

| Language | GitHub API bytes | Eligible original-source assessment |
|---|---:|---|
| Dart | 46,644 bytes | Core application candidates: 951 lines in five feature/core files, with template/localization exclusions; exact raw LOC requires a local scanner |
| Kotlin | 142 bytes | One small Flutter `MainActivity.kt` wrapper; effectively a framework/template bridge |
| C++ | 24,552 bytes | Desktop runner/template code; generated framework integration, not eligible third-party-free authored source |
| CMake | 19,762 bytes | Build templates/configuration; excluded from original application LOC |
| Swift | 2,044 bytes | iOS/macOS runner/template code; excluded or separately reviewed as generated/framework scaffolding |
| Shell | 73,501 bytes | Build/automation script and setup scripts; excluded from application LOC, but eligible as authored automation LOC after a separate scanner |
| HTML | 2,118 bytes | Web runner template, excluded or eligible only as copied scaffold |
| PHP/Java/TypeScript/Python | 0 bytes reported by GitHub | No material project source identified |

## 4. Git History and Commit Authenticity

There are 38 commits reported. The repository's first commit is a no-parent `Initial commit`, and the latest commit deletes `github/workflows/build_apk.yml`.

### First commit

- **Author name:** `MuhammadUmairSattar`
- **Git username/ID:** [MuhammadUmairSattar](https://github.com/MuhammadUmairSattar) / `344566430`
- **Commit author email:** `akhrofficial68@gmail.com`
- **Commit:** [4eb5cbb299150ff1cc5c668fd682f4ba6610d327](https://github.com/MuhammadUmairSattar/Smart-Park/commit/4eb5cbb299150ff1cc5c668fd682f4ba6610d327)
- **Commit date:** 2026-11-20T14:52:59Z
- **Verification:** GitHub reports the commit object/author identity as verified

### Latest commit

- **Author name:** `MuhammadUmairSattar`
- **Git username/ID:** [MuhammadUmairSattar](https://github.com/MuhammadUmairSattar) / `344566430`
- **Commit:** [8d0202a285604e7d94045aa04fbe1e70ad4c5b32](https://github.com/MuhammadUmairSattar/Smart-Park/commit/8d0202a285604e7d94045aa04fbe1e70ad4c5b32)
- **Commit date:** 2026-11-21T14:47:25Z
- **Verification:** GitHub reports the commit object/author identity as verified
- **Change:** Deletes `github/workflows/build_apk.yml` (note: repository tree contains `.github/workflows/build_apk.yml`, and latest commit's exact message may refer to the former path)

### Commit authenticity findings

- GitHub lists one additional author identity, `bot` / ID `58210622`, at [bot](https://github.com/bot), with one contribution.
- The bot commit is [59246f0d9e1c99ef46a1d203b3c97d0fa933d304](https://github.com/MuhammadUmairSattar/Smart-Park/commit/59246f0d9e1c99ef46a1d203b3c97d0fa933d304), dated 2026-11-20T14:56:39Z.
- The bot commit's author name is `Muhammad Umair Sattar Bot`; its verification status is not verified.
- GitHub web commits are separately attributed to committer `web-flow` (ID `19864447`) for owner-authored commits. This does not by itself indicate ownership impersonation.
- Verified facts: contribution balance and commit signatures/statuses reported by GitHub.
- Not verified: whether every code line is independently authored by the account, or whether AI-generated or copied content was used.

## 5. Features and Placeholder Assessment

### Implemented in source

- Vehicle classes, in-memory entry/checkout, fixed and hourly fee models
- Biometric and password UI
- Camera OCR for plate-like text
- QR exit scanning
- Basic 22-language model and RTL/LTR framework support
- QR tickets and 80mm thermal/PDF layout
- Material UI theme code
- Platform runner projects and GitHub setup/build automation

### Placeholder or non-production indicators

- `_api.authenticate()` deliberately delays and stores the hard-coded value `jwt_enterprise_token_2026`; no HTTP request is sent. ([app_core.dart](https://github.com/MuhammadUmairSattar/Smart-Park/blob/main/lib/core/app_core.dart#L174-L182))
- `_baseUrl` points to an undeclared external hostname and is unused for authentication. ([app_core.dart](https://github.com/MuhammadUmairSattar/Smart-Park/blob/main/lib/core/app_core.dart#L152-L172))
- Parking tickets exist only in Riverpod state and are lost on app restart. ([parking_logic.dart](https://github.com/MuhammadUmairSattar/Smart-Park/blob/main/lib/features/parking/parking_logic.dart#L65-L119))
- OCR extracts a broad alphanumeric pattern and is not a robust plate-recognition pipeline. ([dashboard_screen.dart](https://github.com/MuhammadUmairSattar/Smart-Park/blob/main/lib/features/parking/dashboard_screen.dart#L32-L49))
- Only English, Urdu, and Arabic contain translation maps; most of the 22 listed languages fall back to English or a raw key. ([app_core.dart](https://github.com/MuhammadUmairSattar/Smart-Park/blob/main/lib/core/app_core.dart#L89-L149))
- `main.dart` is a default counter app, and imports `material_ui`, which is not in the checked-in manifest. ([main.dart](https://github.com/MuhammadUmairSattar/Smart-Park/blob/main/lib/main.dart#L1-L33); [pubspec.yaml](https://github.com/MuhammadUmairSattar/Smart-Park/blob/main/pubspec.yaml))
- The widget test is the default counter smoke test and is incompatible with Smart-Park. ([widget_test.dart](https://github.com/MuhammadUmairSattar/Smart-Park/blob/main/test/widget_test.dart#L13-L29))
- `build_app.sh` contains embedded source that differs from the checked-in Dart source and would overwrite project files; it should not be treated as a checked-in source-of-truth mechanism. ([build_app.sh](https://github.com/MuhammadUmairSattar/Smart-Park/blob/main/build_app.sh))

## 6. Build Readiness

### Verified build blockers

1. **Manifest mismatch.** `lib/main.dart` imports `material_ui/material_ui.dart`, but the checked-in `pubspec.yaml` does not declare `material_ui` directly.
2. **Entry-point mismatch.** The checked-in app entry point is a Flutter demo. The intended Smart-Park app is embedded in `build_app.sh` and may only appear after running the script.
3. **Stale lockfile.** `pubspec.lock` and `pubspec.yaml` are not consistent; the lockfile contains `material_ui` and packages absent from the current manifest, while dependencies from the manifest may not be represented correctly.
4. **SDK constraints.** The manifest declares `Dart >=3.4 <4.0`, while the retrieved lockfile requires Dart `>=3.14` and Flutter `>=3.47`, so resolution could fail on the manifest SDK range/with older toolchains.
5. **Release signing.** Android `release` uses the debug signing configuration. ([build.gradle.kts](https://github.com/MuhammadUmairSattar/Smart-Park/blob/main/android/app/build.gradle.kts#L32-L37))
6. **CI integration weakness.** The remaining APK workflow is deleted; `build_app.sh` is a mutating setup/build script and may overwrite source. Actions may not represent a stable reproducible release pipeline.
7. **Lint/test mismatch.** The default counter test does not test Smart-Park and may fail or be obsolete.

### Build status classification

- **Not executed:** No application or build command was run.
- **Build-ready verdict:** **No**, not in the audited checkout, until manifest/entrypoint conflict is resolved and a clean Flutter resolution/build is performed.

## 7. Security Findings

| Severity | Finding | Evidence / impact |
|---|---|---|
| High | Authentication is not real | [app_core.dart](https://github.com/MuhammadUmairSattar/Smart-Park/blob/main/lib/core/app_core.dart#L174-L182); any non-empty credentials accepted after delay |
| High | Static fake bearer token | The code writes `jwt_enterprise_token_2026` to secure storage; a real system must never use such a token |
| High | No backend authorization or server validation | Ticket issuance/check-out and identity are local-only, making a production app trivial to bypass |
| Medium | Debug signing for release | [build.gradle.kts](https://github.com/MuhammadUmairSattar/Smart-Park/blob/main/android/app/build.gradle.kts#L32-L37) |
| Medium | No server-side receipt/payment evidence | Receipts include no payment provider, invoice, transaction ID, or server verification |
| Medium | QR tokens do not contain cryptographic signatures | Any user knowing or recreating a token format could invoke in-app checkout; no backend verification exists |
| Medium | OCR/camera permissions and sensitive image handling | [setup_flutter.yml](https://github.com/MuhammadUmairSattar/Smart-Park/blob/main/.github/workflows/setup_flutter.yml#L41-L63) adds camera/Face ID usage; storage/upload lifecycle is not documented |
| Low/Medium | Error text exposes exception details to users | [auth_screen.dart](https://github.com/MuhammadUmairSattar/Smart-Park/blob/main/lib/features/auth/auth_screen.dart#L21-L35) can reveal implementation details |

No exposed passwords, API keys, private keys, or personal secrets were found in the directly inspected files. Absence of evidence is not proof that none exist in git history or binary assets.

## 8. Code Quality

- The Dart architecture separates core/theme, auth, state/logic, dashboard, and receipt code, which is reasonable for a prototype.
- Some state updates and provider configuration are straightforward.
- The code lacks dependency injection, backend services, persistence, error models, and meaningful domain validation.
- Auth, API, OCR, parking, receipt, and UI concerns are mixed in local widgets/services.
- The `build_app.sh` embedded-copy design creates two competing source versions and is a major maintainability risk.
- No meaningful domain tests were found: the only test is the default counter test.
- No license or contributor agreement is present.
- The code contains user-facing developer name/copyright text and should not infer formal copyright or license rights from this alone.

## 9. Copied Templates and AI-Generated Indicators

### Verified template indicators

- Standard Flutter counter comments and structure in `lib/main.dart`.
- Standard generated iOS launch assets and Xcode project files.
- Android standard Gradle/Manifest/runner scaffold.
- macOS/Windows/Linux standard runner and generated plugin registrant files.
- Standard iOS launch README under assets.
- Default widget test generated by Flutter.

### AI-generated-code indicators

The repository shows several weak indicators, including polished comments, generated workflow content, repetitive theme data, and a large embedded setup script. These are **signals only**, not proof of AI authorship:

- Highly systematic 50-theme and localization blocks
- `build_app.sh` writing many large source files wholesale
- Bot-authored auto-initialization commit
- README and app description with marketing-style feature claims
- Template code/comments left unchanged in `main.dart`

No similarity search or exact provenance scan was performed. Accordingly, copied third-party source cannot be ruled in or out.

## 10. Licensing and Ownership Risks

- GitHub metadata reports no license.
- No `LICENSE`, `COPYING`, SPDX headers, or package-license declaration was identified.
- The repository owner and commit history are strongly associated with the same named person/account, but GitHub ownership is not legal proof of copyright ownership.
- Repeated developer attribution/copyright strings do not establish valid ownership or transfer rights.
- Standard Flutter templates remain subject to their upstream licenses; use of package dependencies is governed by their own licenses via `pubspec.lock` and pub.dev metadata.
- Third-party packages and assets in binary/generated content require separate license review.
- No evidence was found for an explicit disclaimer or organization/school/employer IP assignment.

**Risk level:** High until a license and authorship/third-party inventory are added.

## 11. Visibility and Previous-Visibility Assessment

- **Currently public:** Verified. GitHub metadata reports `visibility: public` and `private: false`.
- **Currently accessible public URL:** https://github.com/MuhammadUmairSattar/Smart-Park
- **Visibility history:** Not determinable through the available read-only API response. No visibility-change event was exposed, and no exact public-to-private or private-to-public transition date could be retrieved.
- **Evidence of prior private status:** None found.
- **Evidence of prior public status:** None beyond the fact that the repository is public now and the initial commit exists as GitHub-hosted history.
- **Conclusion:** It is unverified whether the repository was ever private or previously public. A visibility transition date is not supported by available evidence.

## 12. Risks Register

| Risk | Severity | Type | Status |
|---|---|---|---|
| Fake authentication/API | Critical | Security / feature reality | Verified |
| In-memory-only ticket state | High | Reliability | Verified |
| No license | High | Legal | Verified |
| Current build inconsistency | High | Delivery | Verified |
| Debug APK signing | High | Security/supply chain | Verified |
| Feature claims exceed implementation | High | Product/marketing | Verified |
| No ANPR model/server | High | Functional | Verified by source |
| Localization fallback | Medium | Internationalization | Verified |
| Default counter test/template | Medium | Quality | Verified |
| Unknown third-party copied code | Medium-High | Legal/security | Unverified |
| AI-generated authorship/ownership ambiguity | Medium | Ownership | Not determinable |
| Visibility history unknown | Low | Historical evidence | Unverified |

## 13. Final Recommendation

**Recommendation: Hold / Prototype status only.** Do not present this repository as production-ready or as a live enterprise parking system.

Before a build or security review can be approved:

1. Reconcile `pubspec.yaml`, `pubspec.lock`, `lib/main.dart`, and `build_app.sh`; make a single source tree canonical.
2. Replace `main.dart` with the actual Smart-Park entry point and remove or regenerate the default counter test.
3. Implement real server-backed authentication, authorization, ticket persistence, QR signing, and checkout validation.
4. Replace the simulated fake token with a secure OAuth/JWT or short-lived backend session flow.
5. Configure a production keystore and signing pipeline; do not use debug signing for releases.
6. Run a clean dependency resolution and Android/iOS build in CI, not by mutating source in a shell script.
7. Add real unit/widget/integration tests, especially for fee calculation, checkout, auth, and persistence.
8. Add an explicit license and third-party/asset inventory.
9. Review all platform permissions and document privacy retention/upload behavior.
10. Re-evaluate feature claims after real OCR accuracy, backend integration, localization completeness, and payment workflows are implemented.

---

**End of audit**
