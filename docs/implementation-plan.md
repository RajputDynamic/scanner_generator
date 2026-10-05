# Implementation Plan — QR Scanner/Generator Enhancements (v0.1 Draft)

## Baseline
- Repo: https://github.com/RajputDynamic/scanner_generator.git
- Branch: master
- Baseline commit: 52e74014cecf75f00049e289956778a3f56339d4
- Requirements revision: v1 (approved)

## Scope (Approved)
A) Fix scan-type detection + add minimal vCard contact support (generator + scanner)  
B) Add local scan history with actions (open/share/copy/save/clear)  
C) Replace default widget test with app-aligned smoke tests + add Playwright web smoke tests with reports

## Baseline limitations
- Planning/design only; runtime behavior not verified.
- Tooling issue: Dart source contents could not be retrieved during planning. Confirm structure before implementation.

## Design decisions (proposed defaults; confirm)
- Bare domains on scan: treat as Text (not URL).
- History persistence: file-based JSON via existing path_provider (no new dependency).
- History entry point: Scanner screen AppBar action only.
- Max history entries: 50 (fixed).
- vCard: VERSION:3.0 minimal.
- Malformed vCard: treat as Text; show non-fatal error on Save.

---

## Work Plan (Ordered)

### Phase 0 — Evidence / repo verification
- TASK-P0-1: Verify `lib/*.dart` contents and identify insertion points for:
  - scanner detection logic
  - generator contact payload logic
  - navigation additions for history
  - existing permission + bottom sheet flows
  Output: citations and confirmed file paths.

### Phase 1 — Enhancement A (Detection + vCard)
- DRAFT-TASK-01: Add domain enum `QrContentType` and utility `QrContentClassifier`.
- DRAFT-TASK-02: Add `VCardCodec`:
  - encodeMinimalVCard(fullName, phone, email)
  - tryParseContact(payload) supporting vCard + legacy FN/TEL/EMAIL
- DRAFT-TASK-03: Update Generator (Contact mode):
  - validate at least one field is present
  - generate minimal vCard 3.0 payload
- DRAFT-TASK-04: Update Scanner:
  - classify payload via `QrContentClassifier`
  - show actions based on type (URL/Open, Contact/Save, Text)
  - parse contact via `VCardCodec` before saving

### Phase 2 — Enhancement B (History)
- DRAFT-TASK-07: Add model `ScanHistoryItem` + JSON serialization.
- DRAFT-TASK-06: Add `ScanHistoryRepository`:
  - store `scan_history.json` in documents directory (path_provider)
  - load/save list, cap at 50 entries
- DRAFT-TASK-09: Wire scanner scan success to append history (debounce to prevent duplicates).
- DRAFT-TASK-08: Add History UI:
  - empty/loading states
  - list items with actions: copy/share/open/save
  - clear all with confirmation

### Phase 3 — Enhancement C (Tests)
- DRAFT-TASK-10: Replace default widget test with app-aligned smoke tests:
  - Home renders
  - navigation to Generator
  - navigation to Scanner
- DRAFT-TASK-11: Add Playwright test project scaffold (Node):
  - config, test folder, scripts
- DRAFT-TASK-12: Document web serve strategy for Playwright:
  - chosen method to serve Flutter web locally on a stable port
- DRAFT-TASK-13: Ensure Playwright HTML report/artifacts produced in predictable location.

### Phase 4 — Hardening
- TASK-P4-1: Add minimal developer docs for running Playwright and interpreting reports (if not already captured).

---

## Build & Test Commands (local)
> Exact commands may vary; confirm during implementation.

### Flutter
- flutter pub get
- flutter analyze
- flutter test
- flutter run

### Web + Playwright
- Serve Flutter web locally (documented in repo)
- npx playwright install (first time)
- npx playwright test --reporter=html

Artifacts: playwright-report/

---

## Risks
- Tooling/evidence gap for Dart sources: must be resolved before implementation.
- Platform permission differences (contacts/camera): ensure graceful failures.
- vCard variations: keep minimal parsing + fallback.

---

## Rollback
- Revert commits.
- Delete local `scan_history.json` to reset history.
