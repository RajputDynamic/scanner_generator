# Implementation Plan & Design Package — QR Payload Parsing + vCard + Tests/CI (v0.1)

## Metadata
- Repo: https://github.com/RajputDynamic/scanner_generator.git
- Baseline branch: master
- Baseline commit (provided): 52e74014cecf75f00049e289956778a3f56339d4
- Requirements revision: v1 (Approved)
- Design revision: v0.1 (Approved for publication)
- Jira: Unavailable (use provisional IDs; creation pending)
- Confluence: EliteASpac (parent: 5537793)
- Planning branch: planning/enhancement-plan

## Scope (approved)
Enhancement A — Robust QR content parsing + correct action routing  
Enhancement B — Generate standards-compliant vCard 3.0 payload for contact mode  
Enhancement C — Add baseline automated tests + GitHub Actions CI (flutter analyze + flutter test)

## Out of scope
- Backend services, accounts, analytics
- UI redesign beyond necessary states/messages
- Mobile E2E automation (Playwright is browser-focused; optional web smoke only if explicitly requested)
- App code changes in this planning phase (this document is a plan only)

---

## 1. Observed facts (verified evidence)
### 1.1 App type and dependencies
Flutter app with QR scanning/generation and sharing capabilities.

Evidence:
- Dependencies include:
  - `mobile_scanner` (scanning), `qr_flutter` (generation), `flutter_contacts` (contact save),
  - `permission_handler`, `url_launcher`, `share_plus`, `screenshot`, `path_provider`, `google_fonts`.
  - `flutter_test` and `flutter_lints` in dev deps.
  - Path: `pubspec.yaml`

### 1.2 Repository structure (platforms)
Multi-platform Flutter project includes Android/iOS/Web/Desktop scaffolding.

Evidence:
- Android gradle kotlin: `android/app/build.gradle.kts`
- iOS runner: `ios/Runner/AppDelegate.swift`
- Web assets: `web/manifest.json`, `web/icons/*`
- Desktop runner scaffolding: `windows/**`, `macos/**`, `linux/**`

### 1.3 Documented feature set
README describes:
- `lib/main.dart`, `lib/home_page.dart`, `lib/qr_scanner_screen.dart`, `lib/qr_generate_screen.dart`
- Result processing: detect text/URL/contact

Evidence:
- Path: `README.md`

### 1.4 Evidence gap
`lib/**` contents could not be retrieved in this tooling session; LLD references to exact widget/class names must be validated once accessible.

---

## 2. Decisions (final)
These were confirmed by human approval and are treated as constraints for implementation.

1) Bare domain handling: **Keep as Text unless scheme present** (`http://` or `https://`).  
2) vCard version: **3.0**.  
3) Contact fields scope: **FN / TEL / EMAIL only**.  
4) Permission UX: **message + Open Settings** on denial.  
5) CI triggers: **pull_request + push to master**.

---

## 3. Proposed architecture (current vs proposed)
### 3.1 Current (as documented)
- UI screens:
  - Home (routes to Generate / Scan)
  - Generator screen (text/url/contact)
  - Scanner screen (camera + bottom sheet actions)
- Packages:
  - Scanner: `mobile_scanner`
  - QR render: `qr_flutter`
  - Contact: `flutter_contacts`
  - Permissions: `permission_handler`
  - Launch URLs: `url_launcher`
  - Share: `share_plus`
  - Screenshot: `screenshot`
  - File write: `path_provider`

### 3.2 Proposed
Add two (optionally three) pure-Dart utility modules:
- `lib/utils/qr_payload_parser.dart`
- `lib/utils/vcard_builder.dart`
- `lib/utils/vcard_parser.dart` (optional but recommended for separation)

Update generator + scanner screens to use these utilities.

Add tests:
- `test/qr_payload_parser_test.dart`
- `test/vcard_builder_test.dart`
- `test/home_widget_test.dart`

Add CI workflow:
- `.github/workflows/flutter_ci.yml`

---

## 4. Mermaid architecture diagram
```mermaid
flowchart TB
  subgraph UI[Flutter UI Layer]
    Home[Home Screen]
    Gen[QR Generate Screen]
    Scan[QR Scanner Screen]
    Sheet[Result Bottom Sheet]
  end

  subgraph Utils[Proposed Utility Layer (Pure Dart)]
    Parser[QrPayloadParser\n(parse -> typed result)]
    VBuilder[VCardBuilder\n(build -> vCard 3.0 string)]
    VParser[VCardParser\n(parse vCard -> fields)\n(optional)]
  end

  subgraph Plugins[Platform Plugins]
    MobileScanner[mobile_scanner]
    QrFlutter[qr_flutter]
    Contacts[flutter_contacts]
    Perm[permission_handler]
    Launcher[url_launcher]
    Share[share_plus]
    Screenshot[screenshot]
    Files[path_provider]
  end

  Home --> Gen
  Home --> Scan

  Gen --> VBuilder --> QrFlutter
  Gen --> Screenshot --> Files --> Share

  Scan --> Perm
  Scan --> MobileScanner --> Parser --> Sheet
  Parser --> VParser
  Sheet --> Launcher
  Sheet --> Contacts
  Sheet --> Share
```

---

## 5. High-Level Design (HLD)
### 5.1 Typed parsing model
Define an internal sealed-style model (Dart `sealed class` or `abstract class` + factory):
- `QrParsedPayload`
  - `QrUrlPayload { Uri uri; String raw; }`
  - `QrVCardPayload { VCardData data; String raw; }`
  - `QrTextPayload { String text; }`
  - `QrUnknownPayload { String raw; String reason; }`

`VCardData` minimal:
- `String? fullName`
- `String? phone`
- `String? email`

### 5.2 Parsing flow (scanner)
- On scan result string `raw`:
  1. Trim whitespace; if empty -> Unknown/Empty
  2. If begins with `BEGIN:VCARD` (case-insensitive after trim) -> parse vCard fields -> Contact
  3. Else if URL scheme present -> Url
  4. Else -> Text

### 5.3 Action routing (bottom sheet)
- URL: show Open Link + Share Text + Scan Again
- Contact: show Save Contact + Share Text + Scan Again
- Text/Unknown: show Copy + Share Text + Scan Again

### 5.4 Generator flow (contact mode)
- Collect name/phone/email fields
- Build vCard 3.0 text via `VCardBuilder.build(...)`
- Feed string to `qr_flutter` for QR generation
- Existing share-as-image continues unchanged (still screenshot QR widget)

### 5.5 CI / quality gates
- GitHub Actions:
  - Setup Flutter
  - `flutter pub get`
  - `flutter analyze`
  - `flutter test`

---

## 6. Low-Level Design (LLD)
> Some UI method names and state variables require validation once `lib/**` is accessible.

### 6.1 Module: `lib/utils/vcard_builder.dart`
**Public API**
- `class VCardBuilder {`
  - `static String buildV3({required String fullName, String? phone, String? email});`
  - `}`

**Rules**
- Output includes:
  - `BEGIN:VCARD`
  - `VERSION:3.0`
  - `FN:<escaped full name>`
  - optional `TEL:<escaped phone>`
  - optional `EMAIL:<escaped email>`
  - `END:VCARD`
- Line endings: `\n` (acceptable for QR payload)
- Escaping:
  - Replace `\n` in values with `\\n`
  - Escape `,` and `;` as `\,` and `\;`

**Validation**
- `fullName` must be non-empty after trim; else caller must prevent generation.

### 6.2 Module: `lib/utils/qr_payload_parser.dart`
**Public API**
- `QrParsedPayload parse(String raw);`

**Algorithm details**
- `final trimmed = raw.trim();`
- If `trimmed.isEmpty`: return `QrUnknownPayload(reason: "empty")`
- If `trimmed.toUpperCase().startsWith("BEGIN:VCARD")`:
  - Use `VCardParser.parse(trimmed)` to extract minimal fields
  - If at least one meaningful field found (FN or TEL or EMAIL): return `QrVCardPayload`
  - Else return Unknown (reason: "vcard_unparseable")
- Else:
  - Try `Uri.tryParse(trimmed)` and validate:
    - scheme is `http` or `https`
    - has non-empty host
  - If valid: Url payload
  - Else: Text payload

**Bare domains policy (approved)**
- Keep as Text unless scheme is present.

### 6.3 Module (optional): `lib/utils/vcard_parser.dart`
**Public API**
- `VCardData parse(String rawVCard);`

**Minimal parsing**
- Split by lines (`\n` and `\r\n`)
- Find first `FN:`, `TEL:`, `EMAIL:` (case-insensitive key match)
- Remove key prefix and unescape `\\n`, `\,`, `\;`
- Handle parameterized keys like `TEL;TYPE=CELL:` by extracting the value after the last `:`

### 6.4 Scanner screen integration (behavioral spec)
- When scan completes:
  - Stop scanning (if current implementation supports pausing controller)
  - Parse payload
  - Present bottom sheet with:
    - Title: "Scanned Result"
    - Content preview (truncate long strings)
    - Type chip: URL / Contact / Text / Unknown
    - Action buttons based on type
- Save contact:
  - Request contacts permission if needed
  - On denial: show message + offer "Open Settings"
  - On success: confirmation message

### 6.5 Generator screen integration (behavioral spec)
- Mode selection: Text / URL / Contact
- Contact mode:
  - Required: Name
  - Optional: Phone, Email
  - QR preview updates as fields change
- Share button:
  - Disabled if no QR data
  - Uses existing screenshot/share pipeline (no change in output type)

### 6.6 Error messages and edge cases
- Empty scan payload -> show Unknown, disable Open/Save actions
- Malformed vCard -> show Text/Unknown with share/copy only
- URL launch failure -> show message "Could not open link"
- Contact save failure -> show message "Could not save contact"

---

## 7. Implementation plan (ordered tasks)
### EPIC
- DRAFT-EPIC-01 — Interoperable Contacts + Reliable Scan Actions + Test Coverage

### Stories (provisional)
- DRAFT-STORY-01 — Parse scanned QR into URL/contact/text
- DRAFT-STORY-02 — Save contact from scanned vCard
- DRAFT-STORY-03 — Generate vCard QR for contact mode
- DRAFT-STORY-04 — Add automated tests + CI

### Tasks (ordered, with dependencies)
#### Phase 0 — Repo hygiene / discovery
1. DRAFT-TASK-00 — Verify `lib/**` availability in repo tooling and confirm actual implementations in:
   - `lib/qr_scanner_screen.dart`
   - `lib/qr_generate_screen.dart`
   - `lib/home_page.dart`
   - `lib/main.dart`
   Dependency: none
   Output: evidence citations for final design diffs

#### Phase 1 — Utilities
2. DRAFT-TASK-01 — Add `VCardBuilder` utility module
   - Files: `lib/utils/vcard_builder.dart`
   Dependency: Task-00
3. DRAFT-TASK-04a — Add minimal `VCardParser`
   - Files: `lib/utils/vcard_parser.dart` (or same as qr parser)
   Dependency: Task-01
4. DRAFT-TASK-01a — Add `QrPayloadParser` utility module + typed result model
   - Files: `lib/utils/qr_payload_parser.dart`
   Dependency: Task-04a

#### Phase 2 — Integrate with UI
5. DRAFT-TASK-02 — Update scanner screen to use `QrPayloadParser` output for:
   - Type chip
   - Action button visibility
   - Correct URL handling for http/https
   Dependency: Task-01a
6. DRAFT-TASK-04 — Update contact save flow to map `VCardData` → `flutter_contacts` contact creation
   Dependency: Task-02
7. DRAFT-TASK-06 — Update generator contact mode to use `VCardBuilder.buildV3(...)`
   Dependency: Task-01

#### Phase 3 — Automated tests
8. DRAFT-TASK-08 — Add unit tests: payload parser
   - `https://example.com` => Url
   - `http://example.com` => Url
   - `example.com` => Text
   - `BEGIN:VCARD...` => Contact
   - empty => Unknown
   Dependency: Task-01a
9. DRAFT-TASK-08a — Add unit tests: vCard builder
   - Always includes BEGIN/END/VERSION/FN
   - Omits TEL/EMAIL when null/empty
   - Escapes newline/comma/semicolon
   Dependency: Task-01
10. DRAFT-TASK-09 — Add minimal widget test for Home screen navigation controls
    Dependency: Task-00

#### Phase 4 — CI
11. DRAFT-TASK-10 — Add GitHub Actions workflow
    - `.github/workflows/flutter_ci.yml`
    - Trigger: `pull_request` + `push` to master
    Dependency: Tasks 8-10

#### Phase 5 — Manual QA checklist
12. DRAFT-QA-01..05 — Execute manual QA scenarios (document results in PR/Confluence later)

---

## 8. Build, run, test, deploy (local)
> Commands are standard Flutter (README does not include explicit CLI commands).

- Install deps: `flutter pub get`
- Static analysis: `flutter analyze`
- Run unit/widget tests: `flutter test`
- Run locally:
  - Android: `flutter run -d <android-device>`
  - iOS: `flutter run -d <ios-device>`
  - Web (optional smoke): `flutter run -d chrome`

---

## 9. Playwright testing plan
This is a **mobile app**, so Playwright cannot drive native Android/iOS UI directly.

Proposed minimal, capstone-appropriate use of Playwright (optional):
- Add a **web smoke test** (only if web build is used) that:
  - Loads the Flutter web app
  - Verifies Home screen renders and navigation to Generator/Scanner routes works

Alternative (recommended for this repo):
- Use Flutter widget tests for UI-level assurance (already in scope).

---

## 10. Rollback plan
- All changes are additive and localized:
  - Remove new utility files
  - Revert scanner/generator integration commits
  - Remove `test/` additions
  - Remove CI workflow file
- Rollback is a simple `git revert` sequence (no DB/migrations involved).

---

## 11. Risks & mitigations
- Parsing false positives/negatives:
  - Mitigate via unit tests and conservative URL rules.
- vCard compatibility variance:
  - Mitigate by using minimal v3.0; optionally support v2.1 later (out-of-scope unless approved).
- Permissions differences across OS versions:
  - Mitigate with clear denial messaging; avoid crashes; manual QA on at least one Android device.

---

## 12. Traceability matrix
| Story ID | Design section | Tasks | Planned tests |
|---|---|---|---|
| DRAFT-STORY-01 Parse scanned QR into URL/contact/text | HLD 5.1–5.3, LLD 6.2–6.4 | 01a, 02 | Unit: `qr_payload_parser_test.dart` cases for http/https/vcard/empty |
| DRAFT-STORY-02 Save contact from scanned vCard | HLD 5.3, LLD 6.4–6.6 | 04a, 04 | Unit: vCard parser coverage; (manual QA) save contact success/denied |
| DRAFT-STORY-03 Generate vCard QR for contact mode | HLD 5.4, LLD 6.1, 6.5 | 01, 06 | Unit: `vcard_builder_test.dart` (format + omission rules) |
| DRAFT-STORY-04 Add automated tests + CI | HLD 5.5, Impl Plan Phases 3–4 | 08, 08a, 09, 10 | CI: run `flutter analyze` + `flutter test` |

---

## 13. Pending Jira
- Jira issue creation is pending due to lack of access. All IDs above are provisional.
