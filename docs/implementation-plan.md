# Implementation Plan & Design Package — Scanner Generator Enhancements (v0.1)

## Context
- Repo: https://github.com/RajputDynamic/scanner_generator.git
- Baseline branch: master
- Baseline commit (provided): 52e74014cecf75f00049e289956778a3f56339d4
- Approved requirements revision: v1 (Enhancements A/B/C)
- Jira: unavailable (use provisional IDs DRAFT-*)

## Scope (Approved)
A) Standards-based contact QR (vCard) generation + robust parsing on scan  
B) Fix scanned-content classification/actions (URL validation and gating)  
C) Local-only scan history (view, actions, clear, cap=50)

## Open Questions (must decide before implementation)
1. vCard version: 3.0 vs 4.0
2. URL without scheme: treat as non-URL vs prompt vs auto-prefix
3. Persistence: file-based JSON via path_provider (preferred) vs shared_preferences
4. Playwright: add Flutter Web smoke tests vs document non-applicability
5. History schema: raw only vs raw + derived type

## Architecture
(Include Mermaid diagram in Confluence / docs—see planning output.)

## Work Plan (Ordered Tasks)
### Phase 1 — Domain utilities
- TASK 1.1 (DRAFT-STORY-01): Implement VCardCodec.buildVCard()
- TASK 1.2 (DRAFT-STORY-02): Implement VCardCodec.parseVCard() (tolerant)
- TASK 1.3 (DRAFT-STORY-03): Implement PayloadClassifier.classify()

### Phase 2 — UI integrations
- TASK 2.1 (DRAFT-STORY-01): Update QR generator contact mode to use vCard builder
- TASK 2.2 (DRAFT-STORY-02/03): Update scanner result sheet to use classifier for actions
- TASK 2.3 (DRAFT-STORY-04): Add History entry point (Home button)

### Phase 3 — Scan history feature
- TASK 3.1 (DRAFT-STORY-04/05): Implement ScanHistoryStore (file-based JSON) with cap=50
- TASK 3.2 (DRAFT-STORY-04/05): Implement History list screen + empty/loading + clear confirm
- TASK 3.3 (DRAFT-STORY-04): Implement History detail screen with actions
- TASK 3.4 (DRAFT-STORY-04): Hook scanner to write to history store

### Phase 4 — Tests & reports
- TASK 4.1: Add Flutter unit tests for vCard, classifier, history store
- TASK 4.2: Decide and implement Playwright strategy (blocked by Open Question #4)

### Phase 5 — Docs
- TASK 5.1: Update README with run/test steps and feature notes

## Build & Test
- flutter pub get
- flutter analyze
- flutter test
- flutter run (android/ios)
- (Optional) flutter run -d chrome for Playwright smoke tests if adopted

## Rollback
- Revert feature commits; no migrations.
- History data remains local file; can be cleared via UI.
