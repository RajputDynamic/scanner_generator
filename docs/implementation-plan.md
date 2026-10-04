# Implementation Plan — QR Scan Classification + vCard + Tests (v0.4 DRAFT)

## Baseline
- Repo: https://github.com/RajputDynamic/scanner_generator.git
- Baseline branch/commit: master @ 52e74014cecf75f00049e289956778a3f56339d4
- Constraints: preserve stack; no runtime verification in this plan; Jira access unavailable (use provisional IDs).
- Approved scope: Enhancements A (scan classification fixes), B (vCard generation + backward compatible parsing), C (tests: Flutter unit/widget + Playwright smoke).

## Goals
1. Correctly classify scanned payloads as URL, CONTACT, or TEXT.
2. Support generating contact QR in Simple format (existing) and vCard (recommended).
3. Support parsing/saving both Simple and vCard contacts from scanned payload.
4. Establish automated tests: Flutter unit/widget and Playwright web smoke.

## Non-goals
- No QR history/favorites
- No backend/services/accounts
- No major UI redesign
- No camera automation in tests

---

## Work Plan (ordered)

### Phase 0 — Planning
- DRAFT-TASK-00: Create planning branch `planning/enhancement-plan`, add this doc as `docs/implementation-plan.md`, open PR (docs-only).

### Phase 1 — Domain utilities (pure Dart)
- DRAFT-TASK-01: Add `QrPayloadClassifier` + supporting models (`QrPayloadType`, `QrClassificationResult`, `ContactModel`).
- DRAFT-TASK-02: Implement robust URL detection (http/https + Uri validation).
- DRAFT-TASK-03: Implement Simple contact parser (FN/TEL/EMAIL).
- DRAFT-TASK-05: Implement minimal vCard parser (`BEGIN:VCARD`…`END:VCARD` with FN/TEL/EMAIL).

### Phase 2 — Generator changes (Contact mode)
- DRAFT-TASK-04: Add Format selector: Simple vs vCard (recommended).
- DRAFT-TASK-04b: Implement vCard generator (VERSION:3.0 + FN + optional TEL/EMAIL).

### Phase 3 — Scanner changes
- DRAFT-TASK-06: Replace existing scan-type heuristics with classifier; update bottom sheet actions.
- DRAFT-TASK-05b: Save parsed contact using `flutter_contacts` with graceful permission/error handling.

### Phase 4 — Automated tests
- DRAFT-QA-01: Add Flutter unit tests for URL detection, simple contact parsing, vCard encode/decode, classifier behavior.
- DRAFT-QA-02: Add widget test for Generator Contact mode format toggle.
- DRAFT-QA-03: Add Playwright smoke test for Flutter Web: Home -> Generator -> Contact -> QR preview visible.
- DRAFT-QA-04: Add negative tests (malformed URL, malformed vCard) ensuring no crashes and safe behavior.

### Phase 5 — Docs
- DRAFT-TASK-07: Update README with explicit commands for run/test/web build and Playwright smoke.

---

## Build & Test Commands (planned)
### Flutter
```bash
flutter pub get
flutter test
flutter run
```

### Web + Playwright (planned)
```bash
flutter build web
npx http-server build/web -p 4173
npx playwright test --reporter=html
```

---

## Risks
- False-positive URL detection if bare domains are treated as URLs. Default plan: only http(s)://.
- vCard format variance. Mitigation: strict minimal subset; ignore unknown fields.
- Flutter web DOM targeting for Playwright. Mitigation: add Semantics labels / stable UI text targets.

---

## Open Questions
1. Should URL detection include bare domains (example.com) or only http(s)://?
2. vCard minimum fields beyond Name/Phone/Email?
3. Should scanner include a universal "Copy" action? (Not in scope unless approved.)
4. For Playwright: standardize on `flutter build web + static server` vs `flutter run -d web-server`?

---

## Jira Mapping
Jira access unavailable. Keep provisional IDs:
- DRAFT-EPIC-01
- DRAFT-STORY-01..04
- DRAFT-TASK-01..07
- DRAFT-QA-01..04
