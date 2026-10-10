# Implementation Plan — Productivity & Safety Enhancements (v0.3)

## Baseline
- Repo: https://github.com/RajputDynamic/scanner_generator.git
- Branch/commit: master @ 52e74014cecf75f00049e289956778a3f56339d4
- Evidence: `README.md`, `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`
- Limitation: Dart source under `lib/` not readable via current toolchain; design assumes structure described in README.

## Approved Scope (Requirements v1)
- Enhancement A: Scan History (local) + Favorites + reuse actions; delete item; clear history.
- Enhancement B: Generator “Recent generated” + pinned Templates; selecting pre-fills forms.
- Enhancement C: QR content validation + safer Open URL (http/https allowlist, invalid/empty blocked, confirm Open/Copy/Cancel, improved unsupported messaging).
- Tests include Flutter unit/widget tests and a Playwright web smoke test + report.
- No backend, no login/cloud sync.

## Decisions (resolved by human approval)
1. History duplication rule: **CONSOLIDATE** (same `normalizedValue + type` updates `lastSeenAt` and increments `scanCount`).
2. Clear history scope: clear **non-favorites** by default; separate “Clear all (incl. favorites)” in overflow menu.
3. URL normalization: prompt user “Open as https://example.com?” if domain-like (contains dot, no spaces, no scheme). Otherwise treat as plain text.
4. Retention limits:
   - Scan history: **500 non-favorites**
   - Recents: **50 items**
   - Pinned templates: **20 items**
5. Navigation placement: History button on Home screen (third button); Templates/Recents panel inside Generator screen; no new top-level tab.
6. Platform persistence: Mobile (Android/iOS) **REQUIRED**; Web/Desktop **BEST-EFFORT**; show message if storage unavailable on web.
7. Don’t ask again (URL): **out of scope** for v1; always confirm before opening URL.
8. Persistence library: **shared_preferences + JSON arrays**, include `schemaVersion` starting at 1.
9. Label field on ScanHistoryItem: **omit** in v1.
10. Contact storage: store **vCard payload text only**; no address-book IDs.
11. Playwright target: Flutter web build; fallback to Flutter `integration_test` if web is not viable (document reason in README).
12. Widget keys: **yes** — add stable `Key` values to critical widgets.
13. UX: persistence failures → snackbar; URL open confirm → dialog; clear history confirm → dialog; delete item confirm → dialog.

## Technical Approach
- Local persistence: `shared_preferences` storing JSON arrays with a root object that includes `schemaVersion: 1`.
- New models:
  - `ScanHistoryItem`: id, rawValue, normalizedValue, type, createdAt, lastSeenAt, scanCount, isFavorite
  - `GeneratedPayloadItem`: id, type, payload map, createdAt, lastUsedAt, isPinned
- New repositories:
  - `ScanHistoryRepository`
  - `GeneratedPayloadRepository`
- Utilities:
  - `UrlSafetyService` for validation/normalization and data shown in confirmation dialog
- UI:
  - New `HistoryScreen`
  - Generator Templates/Recents panel
  - URL confirm dialog (Open/Copy/Cancel)

## Work Breakdown Structure (Ordered)

### Phase 0 — Verification
- T0.1 Verify access to Dart `lib/` sources and confirm current navigation/actions; update citations in design docs.

### Phase 1 — Foundation
- T1.1 Add models + JSON serialization.
- T1.2 Implement repositories + retention (keep favorites/templates; prune non-favorites/recents beyond limits).
- T1.3 Add unit tests for serialization, consolidation behavior, and retention pruning.

### Phase 2 — Enhancement C (cross-cutting)
- T2.1 Implement URL validation/normalization rules:
  - allow schemes: http/https
  - missing scheme + domain-like → prompt “Open as https://…?”
  - otherwise treat as text
- T2.2 Implement URL confirm dialog (Open/Copy/Cancel) before external navigation.
- T2.3 Ensure unsupported content still offers copy/share.

### Phase 3 — Enhancement A (History)
- T3.1 Record scan results on successful scan (non-blocking; snackbar on failure).
- T3.2 Add History screen and navigation from Home (third button).
- T3.3 List item actions: open (URL confirm), copy, share, delete, favorite toggle.
- T3.4 Clear history dialogs:
  - Clear history (non-favorites)
  - Clear all (incl. favorites)

### Phase 4 — Enhancement B (Recents/Templates)
- T4.1 Record generated payloads to recents when QR is successfully displayed.
- T4.2 Add Templates/Recents panel inside generator screen.
- T4.3 Selecting an entry pre-fills the generator form and updates the preview.
- T4.4 Pin/unpin templates and apply retention.

### Phase 5 — QA + Docs
- T5.1 Unit tests:
  - URL validation and normalization
  - repository read/write, consolidation, retention
- T5.2 Widget tests (with stable Keys):
  - History list rendering + interactions
  - URL confirm dialog actions
  - Generator recents/templates selection + prefill
- T5.3 E2E:
  - Primary: Playwright against Flutter web build, generating a text QR and verifying UI updates + report
  - Fallback: Flutter `integration_test` if Playwright on web is not viable (document the reason and the substitute report)
- T5.4 Update README:
  - run/test instructions
  - what is stored locally and how to clear it
  - URL confirmation behavior

## Build & Test Commands (local)
- `flutter pub get`
- `flutter analyze`
- `flutter test`
- Web for Playwright: `flutter build web` and serve the build output (serve approach TBD during implementation).

## Rollback
- Rollback by reverting implementation PR(s).
- Storage schema versioning (`schemaVersion: 1`) to support safe evolution.

## Traceability
See Confluence page “Planning and Design - (AI-Genereted)” (design_revision v0.3) for full architecture/HLD/LLD/wireframes/traceability matrix and approval record.
