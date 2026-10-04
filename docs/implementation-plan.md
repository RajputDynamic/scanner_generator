# Implementation Plan — Scanner/Generator Enhancements (v0.1)

## Status
- Draft revision: v0.1
- Based on approved BA requirements revision: v1
- Repo baseline branch: master
- Baseline commit reference: 52e74014cecf75f00049e289956778a3f56339d4 (not re-verified via tooling)

## Blocker (must resolve before implementation)
Repository tooling currently does not surface `lib/` and `test/` source files in the file tree, although README references them. Design is therefore best-effort and includes assumptions.

## Scope (approved)
A) Fix scan-result type detection and actions (URLs, vCards/contacts; tel/sms/mailto)
B) Generate standards-compliant contact QR (vCard) and support round-trip scan parsing/display
C) Establish testing and linting foundation (Flutter widget tests + Playwright web smoke + report)

## Key decisions (defaults; confirm)
- vCard version: 3.0
- Bare domain URL normalization: assume https://
- Add-contact: provide copy/share fallback unless existing code supports OS insertion
- Playwright target: flutter run -d web-server

## Task plan (ordered)

### Phase 0 — Alignment
- TASK-PLAN-01: Verify baseline commit and regain access to `lib/` + `test/` via tooling.
- TASK-PLAN-02: Add this plan to `docs/implementation-plan.md` on planning branch (docs-only).

### Phase 1 — Scan classification (Enhancement A)
- TASK-IMPL-01 (FR-1): Add `ScanPayload` models + `ScanPayloadClassifier` (pure).
- TASK-IMPL-02 (FR-2): Implement URL detection & normalization (http/https + bare domain -> https).
- Unit tests: classifier cases.

### Phase 2 — vCard encode/parse (Enhancement B)
- TASK-IMPL-05 (FR-3): Implement vCard encode (FN/TEL/EMAIL) and use for Generator Contact QR.
- TASK-IMPL-03 (FR-4): Implement vCard parse and integrate into classifier.
- TASK-IMPL-04 (FR-1/FR-4): Update scanner result sheet to show parsed fields + raw copy.
- Tests: vCard encode/parse; widget test for vCard rendering.

### Phase 3 — QA foundation (Enhancement C)
- TASK-IMPL-08 (FR-5): Enable `flutter_lints` in `analysis_options.yaml` and fix critical analysis issues.
- TASK-IMPL-07 (FR-5): Replace default widget test with:
  - Home navigation to Generator/Scanner
  - Generator shows QR preview when text is entered
- TASK-IMPL-09 (FR-5): Add Playwright setup + web smoke test + HTML report.

### Phase 4 — Manual QA & evidence
- TASK-QA-01: Add sample payload table (URL/tel/sms/mailto/vCard/text).
- TASK-QA-02: Validate generated vCard QR with external scanner app (manual).
- TASK-QA-03: Capture `flutter test` logs.
- TASK-QA-04: Capture Playwright report artifact.

## Build/run/test steps
- flutter pub get
- flutter analyze
- flutter test
- flutter run

Web + Playwright:
- flutter run -d web-server --web-port=8080
- npm ci
- npx playwright install --with-deps
- npx playwright test
- npx playwright show-report

## Rollback
Revert commits affecting classifier/vCard changes; remove Playwright tooling; restore prior scan/generate logic. No DB migrations in scope.

## Traceability
See design package traceability matrix in the planning deliverable.
