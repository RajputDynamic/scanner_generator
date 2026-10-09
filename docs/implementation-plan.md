# Implementation Plan — QR Parser, History, and Tests (v0.1)

Baseline: master @ 52e74014cecf75f00049e289956778a3f56339d4 (runtime not verified)  
Approved Requirements: v1 (Confluence page: 10354689)  
Status: Draft for human review

## Goals (Approved Scope)
- Enhancement A: Reliable QR content parsing + fixes (URL + vCard/contact)
- Enhancement B: Local scan history with actions and clear/delete
- Enhancement C: Replace template tests + add Playwright web smoke tests (non-camera)

## Constraints
- Preserve existing Flutter stack (Dart ^3.7.0).
- No implementation in this phase; plan/design only.
- Camera scanning not covered by Playwright automation.

## Open Questions (must confirm before build)
1. vCard format: vCard 3.0 vs 4.0 vs custom.
2. Persistence: allow adding `shared_preferences` or require file-based JSON.
3. History limit N (default proposal: 50).
4. Privacy: opt-in toggle vs always-on local history.
5. Entry point: History from Scanner only vs also Home.
6. Contact saving UX: confirm before save or save directly.

## Proposed Architecture
- Add `QrPayloadParser` (pure Dart) to classify payloads as url/contact/text.
- Add `ScanHistoryRepository` + `ScanHistoryService` for local persistence and trimming.
- Add `HistoryScreen` to display past scans and actions.

## Work Plan (Ordered Tasks)
### DRAFT-STORY-01 — Centralized parsing (URL/contact/text)
1. TASK-A1: Add models: `QrPayloadType`, `ParsedQrPayload`, `ParsedContact`.
2. TASK-A2: Implement `QrPayloadParser`:
   - URL: detect http/https and parse `Uri`
   - vCard: detect BEGIN:VCARD and parse FN/TEL/EMAIL
   - fallback: text
3. TASK-A3: Refactor scanner result sheet to rely on parser output for action visibility.
4. TASK-A4: Remove ad-hoc URL detection and fix http/https handling via parser.

### DRAFT-STORY-02 — Normalize contact generator output
5. TASK-B1: Implement vCard formatter helper for generator contact payload.
6. TASK-B2: Ensure payload has no unintended indentation and includes VERSION + FN/TEL/EMAIL.

### DRAFT-STORY-03 — Scan history
7. TASK-C1: Add `ScanHistoryEntry` model (id, timestamp, type, raw, displayLabel).
8. TASK-C2: Implement repository:
   - Option A: SharedPreferences JSON blob
   - Option B: JSON file in app docs dir
9. TASK-C3: Implement service (append, trim to N, list, delete, clear).
10. TASK-C4: Add History UI + navigation from Scanner (AppBar icon).
11. TASK-C5: Add item actions: copy/share/open/save contact/delete.
12. TASK-C6: Add clear-all confirmation dialog and empty state.

### DRAFT-STORY-04 — Tests
13. TASK-D1: Replace `test/widget_test.dart` with app-aligned widget tests.
14. TASK-D2: Add Playwright e2e project for web:
   - smoke: home navigation, generator segment switching, QR preview appears
15. TASK-D3: Update README with commands to run analyze/test/e2e.

## Affected Areas
- Existing screens (per README): `lib/main.dart`, `lib/home_page.dart`, `lib/qr_scanner_screen.dart`, `lib/qr_generate_screen.dart`
- New modules (proposed): `lib/domain/`, `lib/data/`, `lib/screens/history_screen.dart`
- Tests: `test/` and `e2e/` (Playwright)

## Test Plan
### Flutter unit/widget tests
- Parser tests: url/http/https; vCard parse; plain text; empty/invalid.
- Widget tests: home buttons; generator preview; history empty/list; action visibility.

### Playwright (web) smoke tests
- Home loads
- Navigate to Generator
- Enter text and verify QR preview container present
- Switch to URL and verify normalization effect on preview (UI-level)
- Navigate back/home

## Build & Run Steps (local)
- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter run`
- Web for Playwright: `flutter run -d chrome` OR `flutter build web` then serve

## Rollback
- Revert commits in reverse order.
- If a new dependency is added (e.g., shared_preferences), remove from pubspec and run `flutter pub get`.
