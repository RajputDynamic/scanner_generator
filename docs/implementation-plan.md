# Implementation Plan — QR Workflow Enhancements (v0.1)

## Scope (Approved BA Requirements v1)
- Enhancement A: Scan History (local) with actions & privacy controls (clear all + incognito)
- Enhancement B: Save/Export Generated QR as PNG + share
- Enhancement C: URL safety/validation + confirmation before opening external links

## Baseline Evidence (Verified)
- Multi-platform Flutter scaffold exists (android/ios/web/windows/macos/linux) (repo tree)
- Flutter dependencies include:
  - mobile_scanner, qr_flutter, permission_handler, share_plus, url_launcher, screenshot, path_provider, flutter_contacts, google_fonts
  - Source: `pubspec.yaml`
- Baseline limitation: Dart `lib/` sources were not visible via current tooling at time of planning; module/file-level integration points are TBD until `lib/` is accessible.

## Implementation Phases

### Phase 0 — Baseline validation (blocking)
1. Record baseline commit SHA for `master`.
2. Re-check repository for `lib/` sources and confirm actual navigation/screen structure:
   - Scan screen, Result screen, Generate screen.
3. Identify existing patterns for state management, toasts, dialogs, and navigation.
**Exit criteria:** integration points confirmed and documented with file paths.

### Phase 1 — Cross-cutting foundations
1. Add centralized configuration/constants:
   - preview truncation length
   - allowed URL schemes (default http/https)
   - max payload length for safe handling (e.g., 4096 chars)
2. Add stable UI selectors (Flutter `Key`s) to critical widgets for Playwright/widget tests:
   - generate input & submit
   - QR display card
   - save/share buttons
   - result open button and confirm dialog
   - history navigation entry and rows

### Phase 2 — Enhancement C: URL safety & confirmation
1. Implement `URLSafetyService`:
   - parse + classify raw scan content
   - validate allowlisted schemes
   - return decision types: AllowedWithConfirm / Blocked / NotAUrl
2. Update Result screen behavior:
   - show confirmation dialog for http/https
   - block risky/unsupported schemes with warning
   - handle `url_launcher` failures gracefully with actionable message

**Tests**
- Unit tests: URL parsing/validation boundaries.
- Playwright (web): verify confirmation dialog appears; cancel keeps user on page.

### Phase 3 — Enhancement A: Scan History
1. Define model `ScanHistoryItem` (id, rawValue, createdAt, kind).
2. Implement persistence via local JSON file (default approach to avoid new deps):
   - file located under app documents directory
   - schemaVersioned root object containing settings + history list
   - safe parse + recovery behavior
3. Add Incognito mode:
   - stored locally
   - disables history writes when enabled
4. Add History screen:
   - newest-first list with preview + timestamp
   - item actions: copy, share, open (if URL), delete
   - clear all with confirmation
   - empty state + CTA back to scan

**Tests**
- Unit tests: repository add/get/delete/clear; incognito prevents add.
- Widget tests: empty vs populated rendering; clear all confirm.
- Playwright: history renders and clear all empties list.

### Phase 4 — Enhancement B: Export generated QR as PNG + share
1. Implement `QrExportService` using:
   - `screenshot` to capture QR widget area
   - `path_provider` to find documents dir
   - write PNG with collision-safe filenames
2. UI actions on generated QR view:
   - Save as PNG
   - Share (via `share_plus`)
   - show progress + success/failure messages
3. Web fallback:
   - if share not supported, show message and keep Save available

**Tests**
- Widget tests: save triggers success/failure (mock IO/capture).
- Playwright: verify save button exists and success UI state appears (web-friendly assertion).
- Manual: verify file exists on device.

### Phase 5 — Regression + build + local deploy
- Commands:
  - `flutter pub get`
  - `flutter analyze`
  - `flutter test`
  - `flutter run -d chrome` (web) and `flutter run -d <android-emulator>`
- Playwright:
  - `flutter build web`
  - serve `build/web`
  - run Playwright suite and produce report

## Provisional Work Items (Jira pending)
- DRAFT-EPIC-01: Retention, Export, and Safer Actions for QR Workflows
- DRAFT-STORY-01..08 as defined in BA v1 (traceability maintained in design docs)

## Risks
- `lib/` source not available in tooling → integration points unknown; must be resolved before implementation.
- Web share/save differences → require fallback UX and test adjustments.
- Local JSON corruption → require safe parse and reset flow.
- Privacy concerns → mitigate with incognito + clear all; local-only storage.

## Rollback
- Revert commit(s).
- Remove history JSON file from app documents dir.
- Disable features via config flags (if implemented).
