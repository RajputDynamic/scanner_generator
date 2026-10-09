# Implementation Plan — scanner_generator Enhancements (v0.1)

Baseline: master @ 52e74014cecf75f00049e289956778a3f56339d4  
Approved BA Requirements: v1 (Enhancements A–C)

## Scope
- FR-1: Improve scan result normalization & classification (URL/vCard/text), fix misclassification bugs, ensure actions match type.
- FR-2: Add local Scan History (list, details/actions, delete single, clear all, retention policy).
- FR-3: Minimize unnecessary Android storage permissions while preserving save/share for generated QR images.

## Constraints
- Preserve existing stack (Flutter + current plugins) unless explicitly approved.
- Add Playwright smoke tests and execution reports for web flows.
- Local deployment required.
- No Jira creation (pending; Jira access unavailable).

## Open Decisions (must confirm before implementation)
1. History retention: cap at N (proposed 100 FIFO) vs unlimited.
2. Persistence: shared_preferences JSON (proposed) vs local JSON file vs DB.
3. Classification scope: only http/https + vCard + text (proposed) vs additional schemes.
4. Malformed URL behavior: hide Open link (proposed) vs disable/show with error.
5. Android minSdk/targetSdk: confirm from gradle.
6. Playwright approach: flutter web-server (proposed) vs build+static serve.

## Architecture Summary
Add small domain/data layer:
- ScanClassifier (pure functions)
- VCardParser (minimal)
- ScanHistoryRepository + storage (SharedPreferences JSON)
- ScanHistoryScreen UI

## Ordered Task Plan

### Phase 0 — Baseline verification
- TASK-0.1: Verify Dart file readability and confirm integration points for scanner/generator/home.
- TASK-0.2: Confirm open decisions and record in docs.

### Phase 1 — FR-1 Classification improvements
- TASK-A.1: Create ScanClassifier returning type + normalized values.
- TASK-A.2: Fix URL detection to support http:// and https://; treat malformed URLs as text.
- TASK-A.3: Implement VCardParser (extract FN/TEL/EMAIL defensively).
- TASK-A.4: Integrate classifier into scanner result bottom sheet; ensure correct action buttons.
- TASK-A.5: Ensure Copy action exists for all types (Clipboard).
- TASK-A.6: Add unit tests for classifier/parser.

### Phase 2 — FR-2 Scan History
- TASK-B.1: Implement ScanHistoryStorage + ScanHistoryRepository (SharedPreferences JSON) and add dependency if required.
- TASK-B.2: Implement ScanHistoryEntry model + JSON serialization.
- TASK-B.3: Persist scans on successful scan display.
- TASK-B.4: Add History entry point from Home and/or Scanner.
- TASK-B.5: Implement ScanHistoryScreen (loading/empty/list).
- TASK-B.6: Implement delete single + clear all with confirmation.
- TASK-B.7: Apply retention policy (if capped).

### Phase 3 — FR-3 Android permission minimization
- TASK-C.1: Audit generator file-saving path and sharing method.
- TASK-C.2: Update AndroidManifest to remove unused storage permissions and requestLegacyExternalStorage when safe.
- TASK-C.3: Manual regression testing on Android (save/share + scan flows).
- TASK-C.4: Document outcomes and any OS-version caveats.

### Phase 4 — QA automation (Playwright + reports)
- TASK-Q.1: Add Playwright smoke tests for:
  - Home loads
  - Navigate to Generator
  - Navigate to History (empty state)
- TASK-Q.2: Add Playwright execution report output and document command.
- TASK-Q.3: Ensure `flutter analyze` and `flutter test` are part of local/CI checklist.

## Build & Run (local)
- flutter pub get
- flutter analyze
- flutter test
- flutter run (Android device/emulator)

## Web Run (for Playwright)
Option A:
- flutter run -d web-server --web-port=8080
- Run Playwright against http://localhost:8080

Option B:
- flutter build web
- Serve build/web with a static server; run Playwright against served URL.

## Rollback Strategy
- Revert AndroidManifest permission removals if save/share regressions occur.
- If history persistence introduces instability, disable auto-save and keep UI behind a toggle (only if needed; otherwise omit).

## Traceability
See planning package traceability matrix (Story/FR → tasks → tests).
