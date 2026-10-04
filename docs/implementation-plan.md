## SCM Capstone — Implementation Plan & Design Package (v0.1)
Baseline: `52e74014cecf75f00049e289956778a3f56339d4` on `master`  
Scope: approved Requirements v1 (History/Favorites, Generator validation/actions, Web upload decode, Playwright tests)

### 0) Decisions required (open questions gate)
These must be decided before implementation begins (or defaulted explicitly by product owner):
1. **History de-duplication:** allow duplicates vs de-duplicate (e.g., if same payload scanned within 5 seconds, update existing).
2. **Clear-all impact:** clear favorites too vs keep favorites separate.
3. **URL normalization:** auto-prepend `https://` when scheme missing vs show validation error.
4. **Contact minimum fields:** for vCard validation, require (a) name OR (b) phone/email? Which is mandatory?
5. **Web decode approach:** allowed to add a small decoding dependency if needed (because `mobile_scanner` is camera-first)? If not allowed, web upload decode may be reduced to “upload UI + not supported” (not recommended).

### 1) Implementation plan (ordered tasks)
> Jira is unavailable; keep provisional IDs from requirements. “Jira creation pending” applies to all tasks.

#### Phase A — Repo grounding & design validation (must happen first)
- **TASK-A1 (DRAFT-TASK-01)**: Retrieve and review `lib/main.dart`, `lib/home_page.dart`, `lib/qr_scanner_screen.dart`, `lib/qr_generate_screen.dart` once tool access works.  
  - Output: confirmed navigation routes, existing models, current share/save behavior.
  - Risk: current environment can’t read these files; if still blocked, dev must inspect locally and paste key excerpts into Confluence or PR comments for traceability.
- **TASK-A2**: Confirm current web behavior (camera access? existing scanner on web?) and decide whether upload decode is net-new.  
- **TASK-A3**: Confirm current generator validation (README implies URL formatting exists) and align enhancements to avoid duplicating functionality. (`README.md`)

#### Phase B — History & Favorites (FR-1, FR-2)
- **TASK-B1 (DRAFT-TASK-02)**: Define `ScanHistoryItem` data model + storage schema.
- **TASK-B2 (DRAFT-TASK-03)**: Implement persistence service (file-based JSON using `path_provider`). (`pubspec.yaml` has `path_provider`)
- **TASK-B3 (DRAFT-TASK-04)**: Add History UI entry + screen (from Home or Scanner).
- **TASK-B4 (DRAFT-TASK-05)**: Detail view actions: copy/share/open (for URLs)/save contact (if already supported by existing flow).
- **TASK-B5 (DRAFT-TASK-06)**: Empty state + delete item + clear all with confirmation.
- **TASK-B6**: Favorites filter (toggle star, show favorites list or filter).

#### Phase C — Generator validation & QR preview actions (FR-3)
- **TASK-C1 (DRAFT-TASK-07)**: Add/confirm content type selector (Text/URL/Contact).
- **TASK-C2 (DRAFT-TASK-08)**: Add validation + inline error states; disable generate/share until valid.
- **TASK-C3 (DRAFT-TASK-09)**: Ensure share of QR image via `screenshot` + `share_plus` (both present in `pubspec.yaml`).
- **TASK-C4**: Optional “Share as text” action (explicitly allowed in FR-3). Keep optional behind a small button, not default.

#### Phase D — Web upload image to decode (FR-4)
- **TASK-D1 (DRAFT-TASK-10)**: Web-only UI affordance (“Upload image”) on Scanner screen; guard with `kIsWeb`.
- **TASK-D2 (DRAFT-TASK-11)**: Implement decode-from-image flow:
  - Option 1: use an existing capability in current packages (to be verified after code access).
  - Option 2: add a small Dart dependency that can decode QR from image bytes on web.
  - Output: decoded text displayed in same result component and optionally saved to history.

#### Phase E — Playwright tests and report (FR-5)
- **TASK-E1 (DRAFT-TASK-12)**: Add Playwright config (baseURL, retries, trace/video on failure, html report).
- **TASK-E2 (DRAFT-TASK-13)**: Smoke test: load app → navigate to generator → generate QR from known string → assert QR preview present.
- **TASK-E3 (DRAFT-TASK-14)**: Upload-decode test: upload known QR fixture → assert decoded result matches expected.
- **TASK-E4 (DRAFT-TASK-15)**: Document local commands for web server + Playwright run and where reports are generated.

### 2) Affected components / modules (expected)
Because `lib/` source could not be read here, affected files are inferred from README structure and repo layout:
- `lib/main.dart` — routing / navigation entry changes (History route)
- `lib/home_page.dart` — add History access point (button/tab)
- `lib/qr_scanner_screen.dart` — save-to-history hook; web upload option; result detail actions
- `lib/qr_generate_screen.dart` — validation logic; actions states; share/share-as-text
- New: `lib/history/…` (or similar) — model, storage service, history list/detail widgets (exact folder name to be chosen after code inspection)
- Tests:
  - New Flutter unit/widget tests under `test/` (directory currently not present; will be created)
  - New `playwright/` folder for E2E tests (Node-based)

### 3) Data design (LLD excerpt)
#### 3.1 Model: `ScanHistoryItem`
Fields (JSON-serializable):
- `id: String` (uuid-like)
- `rawValue: String`
- `type: String` enum-like: `text | url | contact | unknown`
- `createdAt: String` (ISO8601)
- `isFavorite: bool`
- `metadata: Map<String,dynamic>?` (optional: parsed contact fields, url, display label)

Storage:
- Location: app documents directory via `path_provider` (`pubspec.yaml`)
- Filename: `scan_history.json`
- Format: `{ "version": 1, "items": [ ... ] }`
- Migration strategy: versioned schema; if parse fails, back up corrupted file and start fresh (NFR-3 privacy + resilience)

#### 3.2 Dedupe strategy (pending decision)
- If dedupe enabled: if `rawValue` equals last saved item and `now - last.createdAt < 5s`, update timestamp instead of append.

### 4) API contracts (internal)
No external APIs. Define internal service interfaces to isolate UI from storage.

#### 4.1 `HistoryRepository`
- `Future<List<ScanHistoryItem>> list({bool favoritesOnly=false})`
- `Future<void> add(ScanHistoryItem item)`
- `Future<void> toggleFavorite(String id)`
- `Future<void> delete(String id)`
- `Future<void> clearAll({bool includeFavorites=true|false})` (pending decision)

#### 4.2 `QrTypeDetector`
- `QrType detect(String raw)`
Rules (baseline assumption; must align with current app behavior once code is visible):
- URL: `Uri.tryParse(raw)` and has scheme+host (or normalize per decision)
- Contact: starts with `BEGIN:VCARD` (common vCard marker)
- else text/unknown

### 5) Validation & error handling (LLD)
#### 5.1 Generator validation (FR-3)
- Text mode: non-empty (trimmed)
- URL mode:
  - If URL normalization approved: if missing scheme, prepend `https://`
  - Validate scheme in (`http`,`https`) and host present
  - Show inline error under input; disable “Generate” and actions until valid
- Contact mode (pending decision):
  - Validate required fields; show per-field errors
  - On generate: build vCard string

Error UX:
- Inline field error messages
- Action buttons disabled with tooltip/secondary text (“Enter a valid URL to generate QR”)
- Non-blocking snackbars for operations (saved, copied, shared, failed)

#### 5.2 Web upload decode errors (FR-4)
- If decode fails: show error state (“No QR detected in image”) and allow retry.
- If file type unsupported: show “Please upload PNG/JPG”.
- Do not save to history on failure.

### 6) Security / privacy considerations
- History stored locally only (NFR-3).
- Provide “Clear all history” (FR-1).
- Avoid logging scanned payloads in production logs (to be verified in code once accessible).
- Android manifest currently requests legacy external storage permissions (`WRITE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE`, `requestLegacyExternalStorage="true"`). (`android/app/src/main/AndroidManifest.xml`)
  - **Plan:** do not expand permissions; prefer app-private storage via `path_provider`. If saving images requires media store, handle via existing packages and minimize permission prompts.

### 7) Architecture (current vs proposed)
#### Observed (from repo + README)
- Flutter UI with 3 screens: Home, Scanner, Generator (`README.md`)
- Scanner uses `mobile_scanner`; generator uses `qr_flutter`; sharing via `share_plus`; screenshot via `screenshot` (`pubspec.yaml`)

#### Proposed additions
- `HistoryRepository` + local JSON storage
- `HistoryScreen` + `HistoryDetailBottomSheet` (or page) for actions
- `GeneratorValidator` utilities
- Web-only `ImageUploadDecoder` component
- Playwright E2E harness

##### Mermaid diagram (architecture)
```mermaid
flowchart LR
  subgraph UI[Flutter UI Layer]
    Home[Home Screen]
    Scan[Scanner Screen]
    Gen[Generator Screen]
    Hist[History Screen]
    Detail[History Detail / Result Sheet]
  end

  subgraph Domain[Domain/Logic]
    Detect[QrTypeDetector]
    Validate[GeneratorValidator]
  end

  subgraph Storage[Local Persistence]
    Repo[HistoryRepository]
    File[(scan_history.json\nDocuments Dir)]
  end

  subgraph Platform[Platform/Plugins]
    MS[mobile_scanner]
    QRF[qr_flutter]
    SS[screenshot]
    Share[share_plus]
    URL[url_launcher]
    Contacts[flutter_contacts]
    PP[path_provider]
    WebFile[Web file picker/input]
    Decoder[Web Image QR Decoder\n(TBD pkg or existing)]
  end

  Home --> Scan
  Home --> Gen
  Home --> Hist

  Scan --> MS
  Scan --> Detect
  Scan --> Repo
  Scan --> Detail

  Hist --> Repo
  Detail --> Share
  Detail --> URL
  Detail --> Contacts

  Gen --> Validate
  Gen --> QRF
  Gen --> SS
  Gen --> Share

  Repo --> PP
  Repo --> File

  Scan -.web only.-> WebFile
  WebFile -.web only.-> Decoder
  Decoder -.web only.-> Detect
```

### 8) High-Level Design (HLD)
#### 8.1 User flows
1) **Scan → Result → Auto-save → History**
   - User scans QR → app shows result sheet → app saves item in history → user can share/copy/open/save contact → later accessible in History.
2) **History browsing**
   - User opens History → sees list (recent first) → filter favorites → open item detail → actions.
3) **Generate with validation**
   - User selects type → fills input → validation shows errors or enables Generate → QR preview appears → share/save actions enabled.
4) **Web upload decode**
   - On web, user chooses image → app decodes → shows same result UI → saves to history.

#### 8.2 Component responsibilities
- **UI screens**: rendering, navigation, calling services, showing errors.
- **HistoryRepository**: persistence, ordering, dedupe/clear rules.
- **Detector/Validator**: pure functions, unit-testable.
- **Web decoder**: isolated so mobile platforms unaffected.

### 9) Low-Level Design (LLD)
#### 9.1 History UI behavior
- List item shows:
  - icon by type (URL/text/contact)
  - primary text (shortened rawValue or extracted display value)
  - timestamp (relative)
  - favorite star toggle
- Interactions:
  - Tap row → detail
  - Swipe delete (optional; if not in current UX patterns, provide delete in detail)

#### 9.2 Generator UI behavior
- Type selector (segmented control)
- For URL:
  - one input field with hint “https://example.com”
  - inline error if invalid
- For Contact:
  - fields: Name, Phone, Email (actual minimum required pending decision)
- Actions area:
  - Generate/Update
  - Share QR image
  - Save QR image (only if supported; else hide/disable with message)
  - Optional “Share as text”

#### 9.3 Web upload decode UI behavior
- On Scanner screen, show:
  - Primary: “Start scanning” (camera)
  - Secondary: “Upload image” (web only)
- After upload:
  - show loading spinner “Decoding…”
  - success: show decoded result sheet
  - error: show inline error + retry button

### 10) Wireframes (text)
> Rendering limitations: text-only wireframes. Final spacing/typography may differ.

#### 10.1 Home screen (add History entry)
```
[AppBar: QR CODE]
--------------------------------
[Card]
  [Button] Scan QR
  [Button] Generate QR
  [Button] History   <-- NEW
[/Card]
```

#### 10.2 Scanner screen (web upload option + result)
```
[AppBar: Scan]
--------------------------------
[Camera Preview + overlay frame]
[Flash toggle]

(web only)
[Secondary button] Upload image  <-- NEW

[Bottom hint text: Align QR within frame]

On success -> Bottom Sheet:
--------------------------------
[Result Type Icon]  URL / TEXT / CONTACT
[Decoded value (selectable)]
[Button] Copy
[Button] Share
(if URL)     [Button] Open
(if Contact) [Button] Save contact
[Button] Scan again
--------------------------------
```

#### 10.3 History screen (list + clear)
```
[AppBar: History]                 [Clear All]
[Tabs/Toggle] All | Favorites
--------------------------------
(List)
(Empty state)
  "No scans yet"
  [Button] Go to Scanner
--------------------------------
Row:
[Icon] Short value...        [☆/★]
       2 minutes ago
(Tap -> detail)
```

#### 10.4 History detail (page or bottom sheet)
```
[Type] URL
[Full decoded value (selectable)]
[Created at timestamp]
[Favorite toggle]

Actions:
[Copy] [Share] [Open] [Delete]
```

#### 10.5 Generator screen (validation + actions)
```
[AppBar: Generate]
--------------------------------
[Segmented] Text | URL | Contact

(Text)
[Input: Text content]   (error if empty)

(URL)
[Input: https://example.com] (error if invalid)
(note: normalization behavior pending decision)

(Contact)
[Name] [Phone] [Email] (field errors per rule)

[Button] Generate/Update (disabled until valid)
--------------------------------
[QR Preview Card]
[Button] Share QR image (disabled until generated)
[Button] Save QR image  (platform dependent)
[Button] Share as text (optional)
```

### 11) Build, run, test, deploy (local)
> Not runtime-verified in this environment; aligns with standard Flutter workflows.

#### 11.1 Flutter
- Install Flutter SDK compatible with Dart `^3.7.0` (`pubspec.yaml`)
- Commands:
  - `flutter pub get`
  - `flutter analyze`
  - `flutter test`
  - Run Android: `flutter run -d android`
  - Run Web: `flutter run -d chrome`

#### 11.2 Web build for Playwright
- Serve web app locally:
  - Option A: `flutter run -d chrome --web-port 5173` (or any stable port)
  - Option B: `flutter build web` then serve `build/web` with a static server (to be decided in TASK-E4 docs)

#### 11.3 Playwright
- Node setup (repo-local):
  - `npm init -y` (if no package.json) and install Playwright
  - `npx playwright install`
- Run:
  - `npx playwright test`
- Report:
  - `npx playwright show-report` (HTML report)

### 12) Rollback plan
- All changes are additive and local-only.
- Rollback steps:
  - Remove History screens/routes and repository class
  - Remove file `scan_history.json` usage (existing files remain but unused)
  - Remove web upload UI and decoding module
  - Remove Playwright folder/config

### 13) Risks & mitigations
- **R1: lib source unreadable in tooling** → mitigate by having a developer confirm actual widget tree and paste summaries; keep design flexible.
- **R2: Web image decoding dependency** → mitigate by selecting smallest dependency and isolating behind `kIsWeb` and an abstraction; if not allowed, adjust scope with explicit approval.
- **R3: Android storage permissions** (`WRITE/READ_EXTERNAL_STORAGE`, legacy flag) may trigger Play Store policy concerns → mitigate by not expanding permissions and prefer app-private storage (`path_provider`).
- **R4: E2E brittleness** → mitigate by using stable selectors (semantic labels) and a known QR fixture image instead of screenshot-download loops.

---

# Traceability matrix (Requirements → Design → Tasks → Tests)

| Story ID | Requirement | Design section(s) | Planned tasks | Planned test coverage |
|---|---|---|---|---|
| DRAFT-STORY-01 | FR-1 History save/list | Data design §3, LLD §9.1, Wireframes §10.3–10.4 | A1, B1–B5 | Flutter unit tests for repository; widget test for list/empty state |
| DRAFT-STORY-02 | FR-2 Favorites | LLD §9.1, Wireframes §10.3–10.4 | B6 | Widget test: toggle favorite persists; repository unit test |
| DRAFT-STORY-03 | FR-1 delete/clear | LLD §9.1, Wireframes §10.3–10.4 | B5 | Widget test: delete; confirmation for clear; repository tests |
| DRAFT-STORY-04 | FR-3 validation | Validation §5.1, LLD §9.2, Wireframes §10.5 | C1–C2 | Widget tests for validation errors; unit tests for validator |
| DRAFT-STORY-05 | FR-3 share/save actions | HLD §8, LLD §9.2 | C3–C4 | Manual QA (platform share hard to unit test); smoke widget test for enabled state |
| DRAFT-STORY-06 | FR-4 web upload decode | HLD §8.1, LLD §9.3, Wireframes §10.2 | D1–D2 | Playwright test for upload flow; manual web test |
| DRAFT-STORY-07 | FR-5 Playwright | Build/Test §11.3 | E1–E4 | Playwright HTML report, trace on failure |
