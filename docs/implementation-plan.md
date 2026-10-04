# Implementation Plan — Trust & Utility Enhancements (History + Export + Permissions)
Version: v0.1 (DRAFT)
Baseline: master @ 52e74014cecf75f00049e289956778a3f56339d4

## Scope (Approved Requirements v1)
- Enhancement A: Local scan history (last N items, history screen, actions, local-only)
- Enhancement B: Save generated QR as PNG + copy payload content
- Enhancement C: Privacy & Permissions screen + pre-permission rationale (camera; contacts when used)

## Evidence (repo)
- Flutter multi-platform scaffold present (android/ios/web/windows/macos/linux).
- Dependencies: mobile_scanner, qr_flutter, permission_handler, flutter_contacts, url_launcher, share_plus, screenshot, path_provider.
  - See: pubspec.yaml
- Android permissions: CAMERA, READ/WRITE_EXTERNAL_STORAGE
  - See: android/app/src/main/AndroidManifest.xml
- Screens described in README: main.dart, home_page.dart, qr_scanner_screen.dart, qr_generate_screen.dart
  - See: README.md
- Tool limitation: lib/*.dart content not retrievable in this environment; validate locally during implementation.

## Proposed Design Decisions (pending confirmation)
1. Use shared_preferences to store scan history as JSON (key: scan_history_items_v1), cap=50.
2. No de-duplication: store each successful scan as its own history entry.
3. PNG export renders QR widget to bytes (avoid full-screen screenshot); keep screenshot as fallback if needed.
4. Privacy wording conservative until verified; avoid absolute “no cloud” unless confirmed.

## Ordered Tasks (WBS)
### Track 0 — Validation
- TASK-0.1: Validate baseline locally; confirm existing navigation and patterns.
- TASK-0.2: Confirm persistence approach; add shared_preferences if none exists.

### Track A — Scan History (FR-A)
- TASK-A1: Define ScanHistoryItem model (id, rawValue, scannedAt, optional kind/display).
- TASK-A2: Implement ScanHistoryRepository with add/list/delete/clear/search; enforce cap=50.
- TASK-A3: Integrate scanner save hook on successful scan with debounce guard.
- TASK-A4: Implement History screen UI (list + search + actions + empty/loading/error states).
- TASK-A5: Add Home navigation entry to History.

### Track B — Generator Export (FR-B)
- TASK-B1: Ensure generator exposes payload string consistently across modes.
- TASK-B2: Add “Copy content” action with validation/disabled state.
- TASK-B3: Implement “Save as PNG” with platform handling:
  - Web: download
  - Mobile/Desktop: save to app documents dir + success feedback + optional Share
- TASK-B4: Error handling + user feedback.

### Track C — Privacy/Permissions (FR-C)
- TASK-C1: Add Privacy & Permissions screen.
- TASK-C2: Add camera pre-permission rationale UI before requesting permission.
- TASK-C3: Contacts permission rationale only when user triggers contact actions.

### Track QA
- TASK-Q1: Flutter unit tests for ScanHistoryRepository.
- TASK-Q2: Flutter widget tests for History screen (empty/list/search/clear confirm).
- TASK-Q3: Playwright web tests:
  - Generator: Save as PNG triggers download
  - Privacy screen content visible
- TASK-Q4: Manual smoke checklist (Android+iOS): permission flow, scan saves history, save PNG, share.

## Build & Run
- flutter pub get
- flutter run -d chrome
- flutter run -d android

## Automated Test Commands
- flutter analyze
- flutter test
- (Playwright) npm ci && npx playwright install --with-deps && npx playwright test --reporter=html

## Risks & Mitigations
- Multiple scan events -> history spam: add debounce/lock until “Scan again”.
- Web PNG download quirks: verify via Playwright download assertions.
- Android storage restrictions: save to app-scoped directory via path_provider.

## Rollback
- Hide History navigation and disable save hook.
- Hide Save PNG/Copy content actions.
- Bypass rationale UI and revert to direct permission request.

## Open Questions
- History de-duplication rule?
- Is adding shared_preferences acceptable?
- Filename convention for PNG?
- Final wording for privacy statements after verifying no network calls?
