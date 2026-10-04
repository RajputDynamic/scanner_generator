## SCM Capstone — Implementation Plan — History/Favorites, URL Safety Check, Export/Import (v0.1)

Baseline: `52e74014cecf75f00049e289956778a3f56339d4` on `master`  
Scope: approved Requirements v1 — **History/Favorites**, **URL Safety Check**, **Export/Import**.

---

## 0) Decisions required (open questions gate)

These must be decided before implementation begins (or defaulted explicitly by product owner):

1. **History de-duplication:** allow duplicates vs de-duplicate (e.g., if same payload scanned within 5 seconds, update existing).
2. **Clear-all impact:** clear favorites too vs keep favorites separate.
3. **URL normalization:** auto-prepend `https://` when scheme missing vs show validation error.
4. **Contact minimum fields:** for vCard validation, require (a) name OR (b) phone/email? Which is mandatory?
5. **Export format:** JSON only vs JSON + CSV (CSV may be lossy for contact payloads).

---

## 1) Implementation plan (ordered tasks)

> Jira is unavailable; keep provisional IDs from requirements. “Jira creation pending” applies to all tasks.

### Phase A — Repo grounding & design validation (must happen first)

- **TASK-A1 (DRAFT-TASK-01)**: Review existing routes/navigation and current scan/result UX.
  - Confirm where scan results are currently handled and whether any persistence exists already.
- **TASK-A2**: Confirm current URL handling (open-in-browser behavior, any existing validation/normalization).
- **TASK-A3**: Confirm current permission/storage strategy (ensure app-private storage via `path_provider`, avoid new permissions).

### Phase B — History & Favorites (FR-1, FR-2)

- **TASK-B1 (DRAFT-TASK-02)**: Define `ScanHistoryItem` data model + storage schema (versioned JSON).
- **TASK-B2 (DRAFT-TASK-03)**: Implement persistence service (file-based JSON using `path_provider`).
- **TASK-B3 (DRAFT-TASK-04)**: Add History entry point + screen (from Home).
- **TASK-B4 (DRAFT-TASK-05)**: History detail view actions: copy/share/open (URLs)/save contact (if supported).
- **TASK-B5 (DRAFT-TASK-06)**: Empty state + delete item + clear all (with confirmation) + optional de-dupe.
- **TASK-B6**: Favorites: toggle star + favorites-only filter/tab.

### Phase C — URL Safety Check (FR-3)

- **TASK-C1 (DRAFT-TASK-07)**: Implement URL classification + normalization behavior (per decision).
- **TASK-C2 (DRAFT-TASK-08)**: Add “URL Safety Check” UI and result states:
  - Identify suspicious URLs (punycode, IP literals, very long host, mixed-script, uncommon TLD, etc.).
  - Provide user-facing messaging: “Looks safe”, “Be cautious”, “High risk” (heuristic; no network calls).
- **TASK-C3 (DRAFT-TASK-09)**: Ensure “Open URL” action requires passing safety check or explicit user confirmation.

### Phase D — Export / Import (FR-4)

- **TASK-D1 (DRAFT-TASK-10)**: Add “Export history” action (History screen menu/button).
  - Export file content from repository (JSON v1) and share via `share_plus`.
- **TASK-D2 (DRAFT-TASK-11)**: Add “Import history” action.
  - Pick file, validate schema/version, merge into existing history (dedupe rules apply), report results (imported/skipped).
- **TASK-D3**: Add “Reset import” safety: do not overwrite without explicit confirmation; prefer merge-by-default.

### Phase E — Tests & documentation (FR-5)

- **TASK-E1 (DRAFT-TASK-12)**: Unit tests for:
  - repository read/write/migration behavior
  - URL safety heuristic classifier
- **TASK-E2 (DRAFT-TASK-13)**: Widget tests for:
  - History empty state
  - favorite toggle persistence
  - clear-all confirmation
- **TASK-E3 (DRAFT-TASK-14)**: Update `README.md` with user-facing steps for:
  - history/favorites
  - export/import
  - URL safety check behavior and limitations

---

## 2) Affected components / modules (expected)

- `lib/main.dart` — routes / navigation entry changes (History route)
- `lib/home_page.dart` — add History access point
- `lib/qr_scanner_screen.dart` — save-to-history hook; URL open action gating via safety check
- `lib/history/...` — model, repository, storage/migration
- `lib/url_safety/...` — URL detector + heuristic classifier + UI component
- `lib/export_import/...` — export/import helpers (file pick/share, schema validation)
- `test/...` — unit + widget tests

---

## 3) Data design (LLD excerpt)

### 3.1 Model: `ScanHistoryItem`

Fields (JSON-serializable):

- `id: String` (uuid-like)
- `rawValue: String`
- `type: String` enum-like: `text | url | contact | unknown`
- `createdAt: String` (ISO8601)
- `isFavorite: bool`
- `metadata: Map<String,dynamic>?` (optional: parsed contact fields, url, display label)

Storage:

- Location: app documents directory via `path_provider`
- Filename: `scan_history.json`
- Format: `{ "version": 1, "items": [ ... ] }`
- Migration strategy: versioned schema; if parse fails, back up corrupted file and start fresh.

### 3.2 Dedupe strategy (pending decision)

- If dedupe enabled: if `rawValue` equals last saved item and `now - last.createdAt < 5s`, update timestamp instead of append.

---

## 4) API contracts (internal)

### 4.1 `HistoryRepository`

- `Future<List<ScanHistoryItem>> list({bool favoritesOnly=false})`
- `Future<void> add(ScanHistoryItem item)`
- `Future<void> toggleFavorite(String id)`
- `Future<void> delete(String id)`
- `Future<void> clearAll({bool includeFavorites=true|false})` (pending decision)
- `Future<Uint8List> exportJson()` (v1 export)
- `Future<ImportResult> importJson(Uint8List bytes, {bool merge=true})`

### 4.2 `QrTypeDetector`

- `QrType detect(String raw)`

Rules (baseline assumption; align with current app behavior once code is visible):

- URL: `Uri.tryParse(raw)` and has scheme+host (or normalize per decision)
- Contact: starts with `BEGIN:VCARD`
- else text/unknown

### 4.3 `UrlSafetyClassifier`

- `UrlSafetyResult classify(Uri url)`

Output fields:

- `level: safe | caution | highRisk`
- `reasons: List<String>` (human-readable)
- `normalizedUrl: Uri` (if normalization enabled)

No network calls; purely heuristic.

---

## 5) Validation & error handling (LLD)

### 5.1 URL safety heuristics (no network calls)

Flag conditions (examples; tune during implementation):

- Host is an IP literal (especially public ranges)
- Punycode (`xn--`) present
- Mixed-script / confusable characters (best-effort)
- Extremely long host or many subdomains
- Non-`http/https` scheme (block)
- Username/password in URL (block)
- Suspicious TLD list (optional; keep maintainable)

UX:

- Show a concise status chip and a “Why?” expandable section listing reasons.
- For **high risk**, require explicit “Open anyway” confirmation.

### 5.2 Export/import errors

- Import file invalid JSON → show “Invalid export file.”
- Version unsupported → show “Unsupported export version.”
- Partial import → show counts: imported/skipped/failed; do not crash.
- Export failures (IO/share) → show snackbar error.

---

## 6) Security / privacy considerations

- History stored locally only.
- Provide “Clear all history”.
- Avoid logging scanned payloads.
- Do not expand Android storage permissions; use app-private storage.

---

## 7) Architecture (current vs proposed)

### Observed (from repo + README)

- Flutter UI with Home, Scanner, Generator screens
- Scanner uses `mobile_scanner`; generator uses `qr_flutter`
- Sharing via `share_plus`; screenshot via `screenshot`

### Proposed additions

- `HistoryRepository` + local JSON storage
- `UrlSafetyClassifier` (pure, testable) + UI result component
- Export/import helpers (JSON v1)
- Unit/widget tests for repository + classifier

---

## 8) Build, run, test (local)

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter run -d android`
- `flutter run -d chrome`

---

## 9) Rollback plan

- Remove History screens/routes and repository class
- Remove URL safety classifier/UI gating
- Remove export/import actions
- Existing `scan_history.json` files remain on-device but unused

---

## 10) Risks & mitigations

- **R1: Heuristic false positives/negatives** → mitigate with clear wording (“heuristic”, “no network verification”) and allow override with confirmation.
- **R2: Import merging edge cases** → mitigate with versioning + robust parsing + detailed import result reporting.
- **R3: Storage corruption** → mitigate with backup-on-failure and clean reset.
