# Implementation Plan — Local History, Favorites/Tags, Privacy & Retention (v0.4 DRAFT)

## Baseline
- Repo: https://github.com/RajputDynamic/scanner_generator.git
- Branch: master
- Baseline commit: 52e74014cecf75f00049e289956778a3f56339d4
- Evidence: README.md, pubspec.yaml, android/app/src/main/AndroidManifest.xml
- Limitation: lib/*.dart contents were not retrievable in the planning environment; confirm locally before implementation.

## Approved Requirements
- Requirements revision: v1 (approved)
- Epic: DRAFT-EPIC-01
- Stories: DRAFT-STORY-01..05
- FRs: FR-1..FR-7

## Open Decisions (must confirm before implementation)
1. Default Save History: ON vs OFF
2. Store full decoded values for all types vs redact contacts
3. Persistence choice: Hive vs sqflite; shared_preferences for settings
4. Metadata: minimal vs include scan format/raw bytes
5. Testing: Playwright (Flutter web) vs Flutter integration_test for mobile execution reports

## Proposed Technical Design (summary)
Add:
- History subsystem (model + repository + service + UI)
- Settings subsystem (saveHistory + retentionDays + clear history)
Integrate:
- Scanner screen logs decoded results when enabled
- Generator screen logs generated payloads when enabled
Retention cleanup runs on app start and/or when opening history.

## Ordered Tasks (no Jira IDs; pending creation)
### Phase 0 — Validate baseline
- TASK-00.1: Inspect lib/ navigation/state patterns at baseline.
- TASK-00.2: Confirm open decisions and finalize storage + testing approach.

### Phase 1 — Persistence & domain
- TASK-01: Implement Settings model + repository (saveHistory, retentionDays).
- TASK-02: Implement HistoryItem model + HistoryRepository + HistoryService (CRUD, search, favorites, tags).
- TASK-03: Implement retention cleanup in HistoryService (applyRetentionCleanup).

### Phase 2 — UI
- TASK-04: History screen (search, filters, list, empty/disabled/error states).
- TASK-05: History detail screen (copy/share/open/regenerate/delete; edit tags).
- TASK-06: Settings screen (saveHistory toggle, retention selector, clear all history).

### Phase 3 — Integrations
- TASK-07: Scanner -> HistoryService.addScanResult (guard empty; debounce duplicates).
- TASK-08: Generator -> HistoryService.addGeneratedPayload.
- TASK-09: Add navigation entry points to History and Settings aligned with existing UI.

### Phase 4 — Testing & docs
- TASK-10: Unit tests for services/repositories (CRUD, filters, retention).
- TASK-11: Widget tests for History/Settings screens (smoke states).
- TASK-12: E2E plan:
  - Preferred: Playwright against Flutter web build (if supported)
  - Alternative (mobile): Flutter integration_test with execution report artifact
- TASK-13: Update runbook docs (flutter run/test; any permission notes).

## Components Affected (expected)
- lib/main.dart (routing / app init) — verify locally
- lib/home_page.dart (navigation entry points) — verify locally
- lib/qr_scanner_screen.dart (save scan results hook) — verify locally
- lib/qr_generate_screen.dart (save generated payload hook) — verify locally
- New: lib/history/*, lib/settings/*, lib/data/*
- pubspec.yaml: add persistence deps (Hive/sqflite + shared_preferences) per decision.

## Build / Test / Run
- flutter pub get
- flutter test
- flutter run (android/ios)
- E2E: Playwright (if flutter web) or integration_test (mobile)

## Rollback
- Disable Save History
- Clear All History
- If persistence schema changes, bump schema version or implement migration; document steps.
