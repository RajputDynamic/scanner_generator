# Implementation Plan — QR Scanner/Generator Enhancements (v0.1)

Baseline:
- Repo: https://github.com/RajputDynamic/scanner_generator.git
- Branch: master
- Baseline commit (per approved BA handoff): 52e74014cecf75f00049e289956778a3f56339d4
- Note: current repository tree evidence retrieved via tooling does not include `lib/` or `test/` directories. This plan is based on approved requirements v1 + README intent and must be revised once Dart source paths are verified.

Approved requirements: v1 (published to Confluence page “Application Analysis (AI-Generated)” id 8749059)

## Goals (in scope)
1) Robust QR content classification (URL vs Contact vs Text), and contextual actions.
2) Standards-based vCard generation + parsing (with legacy support).
3) Replace template test with meaningful unit/widget tests; optional Playwright for web smoke if feasible.

Out of scope: new QR types, history/favorites, accounts, major UI redesign, analytics.

---

## Decisions required before implementation (blockers)
- D0.1: vCard version to emit: 3.0 vs 4.0 (recommend 3.0).
- D0.2: Scan behavior for bare domains like `example.com` (default: treat as Text/Unknown).
- D0.3: Generator validation rule when contact fields empty (recommend: require Full Name).
- D0.4: Playwright approach (optional): only if Flutter Web build is verified.

---

## Planned changes (high-level)
- Add a pure-Dart domain utility layer:
  - `QrPayloadClassifier` to classify scanned payloads.
  - `VCardBuilder` to generate vCard payloads in generator.
  - `VCardParser` to parse vCards (and legacy FN/TEL/EMAIL format) in scanner.
- Update scanner result bottom sheet to show type + raw content and contextual actions.
- Update generator contact mode to emit vCard and enforce validation.
- Add unit tests for classifier/vCard utilities and widget smoke tests for navigation.

---

## Work plan (ordered tasks)

### Phase 0 — Confirm baseline and decisions
- TASK-0.1 Decide vCard version to emit (3.0 vs 4.0).
- TASK-0.2 Decide URL auto-prefix behavior for scanned `example.com`.
- TASK-0.3 Decide generator validation UX for empty contact fields.
- TASK-0.4 Decide whether Playwright will target Flutter Web or remain out of scope.

### Phase 1 — Classifier utility (FR-1, FR-2, FR-3, FR-7)
- TASK-1.1 Define models: `QrPayloadType`, `QrPayloadClassification`, `ContactData`.
- TASK-1.2 Implement URL detection using `Uri.tryParse` + validation (`http|https`, hasAuthority).
- TASK-1.3 Implement contact detection (vCard BEGIN:VCARD and legacy FN/TEL/EMAIL lines).
- TASK-1.4 Provide `classify(raw)` API.

### Phase 2 — vCard builder + parser (FR-4, FR-5)
- TASK-2.1 Implement `VCardBuilder.build(...)` to output minimal valid vCard.
- TASK-2.2 Implement `VCardParser.tryParseVCard(raw)` for FN/TEL/EMAIL with params support (e.g., `TEL;TYPE=CELL:`).
- TASK-2.3 Implement legacy parser for FN/TEL/EMAIL lines.
- TASK-2.4 Finalize “best effort” parsing semantics and warnings.

### Phase 3 — UI integration (FR-2, FR-3, FR-7)
- TASK-3.1 Update scanner bottom sheet:
  - show detected type badge
  - show raw payload (selectable)
  - show actions: Open URL (URL only), Save Contact (Contact only), Share, Scan Again
  - handle failures with snackbars.
- TASK-3.2 Update generator contact mode:
  - generate payload using VCardBuilder
  - validation UX per Phase 0 decision.

### Phase 4 — Tests (FR-6, NFR-3)
- TASK-4.1 Unit tests for classifier and vCard utilities.
- TASK-4.2 Widget smoke tests for navigation (Home → Generate/Scan).
- TASK-4.3 Optional: Playwright smoke test for Flutter Web build, if feasible.

### Phase 5 — Build/run/local deploy + QA
- TASK-5.1 Document build steps:
  - `flutter pub get`
  - `flutter analyze`
  - `flutter test`
  - `flutter run`
- TASK-5.2 Manual QA checklist:
  - scan http/https QR → Open URL action
  - scan vCard → Save Contact populates fields
  - generate vCard → import with external scanner app
  - permission denied flows for camera/contacts
- TASK-5.3 Rollback strategy: revert commits on feature branch; no DB migrations expected.

---

## Testing & reports
- Primary: `flutter test` (unit + widget). Deterministic; no camera dependency.
- Optional: Playwright (web smoke) only if `flutter build web` verified.
- Capture test execution outputs/screenshots as artifacts per project conventions.

---

## Risks
- R1: Dart sources not present in current repo snapshot; plan needs update once paths confirmed.
- R2: vCard parsing complexity beyond minimal FN/TEL/EMAIL.
- R3: Platform permission differences for saving contacts.
- R4: Widget tests may fail if scanner initializes camera; mitigate via indirection/guards.

---

## Traceability
- FR-1..FR-7 mapped to tasks and tests in the design package v0.1.
