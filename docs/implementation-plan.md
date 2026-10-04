# Implementation Plan — QR Classification, vCard, and Scan History (v0.3)

## Goals

- Classify scanned QR content into a small set of canonical types.
- Support vCard QR codes (parse and display as contact).
- Store scan history locally with a simple UI to view, search, and clear.
- Keep existing scanning flow intact; changes should be additive and low-risk.

## Non-Goals

- Cloud sync, accounts, or analytics.
- Editing or exporting contacts beyond basic vCard display.
- Enterprise-grade vCard compliance (we’ll handle common cases only).

## Assumptions

- The app already scans QR codes and produces a string payload.
- We can add local persistence (SQLite/Room/CoreData/IndexedDB) depending on platform.
- UI is modular enough to add a History screen and a result details view.

## Scope Overview

1. **QR content classification**
2. **vCard parsing and rendering**
3. **Scan history persistence + UI**
4. **Migration & rollback strategy**

---

## 1) QR Content Classification

### Canonical Types

- `url`
- `text`
- `wifi`
- `email`
- `phone`
- `sms`
- `vcard`
- `geo`
- `unknown`

### Classification Rules (in priority order)

1. **vCard**
   - Starts with `BEGIN:VCARD` (case-insensitive, trim leading whitespace).
2. **WiFi**
   - Starts with `WIFI:` (common format: `WIFI:T:WPA;S:ssid;P:pass;H:false;;`).
3. **URL**
   - Valid `http://` or `https://` prefix, or matches a conservative URL regex.
4. **Email**
   - `mailto:` prefix or simple email regex.
5. **Phone**
   - `tel:` prefix or E.164-ish pattern with optional separators.
6. **SMS**
   - `sms:` prefix (handle `sms:number?body=...`).
7. **Geo**
   - `geo:` prefix (latitude,longitude).
8. **Text**
   - Fallback when printable text.
9. **Unknown**
   - Non-printable/binary or extremely long payloads (define a safe cutoff).

### Output Model

Create a normalized result object:

- `raw` (string)
- `type` (enum)
- `data` (type-specific parsed fields)
- `displayTitle` (short summary)
- `displayBody` (formatted details)
- `actions` (suggested actions: open URL, copy, call, email, add contact, etc.)

### Testing

Add unit tests for:
- Each type detection
- Edge cases (leading spaces, lowercase prefixes, missing fields)
- Ambiguous payloads (e.g., “example.com” without scheme)

---

## 2) vCard Parsing and Rendering

### Supported Fields (v0.3)

- `FN` (Full Name)
- `N` (Name components; fallback if `FN` missing)
- `ORG`
- `TITLE`
- `TEL` (multiple)
- `EMAIL` (multiple)
- `ADR` (optional; basic string rendering)
- `URL` (optional)
- `NOTE` (optional)

### Parsing Approach

- Implement a small parser for common vCard 2.1/3.0/4.0 lines:
  - Handle folded lines (lines starting with space/tab are continuations).
  - Split on first `:` to separate key/params from value.
  - Key may include parameters: `TEL;TYPE=CELL:+123...`
- Keep unknown fields in a `rawFields` map for debugging display (optional).

### Rendering

- Display a “Contact” result view with:
  - Name (FN or derived from N)
  - Organization/title
  - List of phones/emails (tap-to-call/tap-to-email)
  - Address and URL if present
  - “Copy vCard” action
- Provide an “Add to contacts” action only if platform supports it easily; otherwise keep it as a future enhancement.

### Testing

- Sample vCards (at least 5) covering:
  - Multiple phones/emails
  - Folded lines
  - Missing FN but present N
  - Parameterized TEL/EMAIL

---

## 3) Scan History (Local)

### Data Model

Store each scan as a record:

- `id` (uuid/autoincrement)
- `timestamp`
- `raw`
- `type`
- `summary` (short string, e.g., domain, contact name, first line of text)
- `metadata` (JSON/blob for parsed fields if convenient)

### Persistence

- Use the platform’s standard local DB:
  - Mobile: SQLite/Room/CoreData
  - Web: IndexedDB
- Keep writes async and resilient:
  - On successful scan classification, write record.
  - If write fails, do not block the scan flow.

### History UI

- Add a “History” screen reachable from the main UI.
- Show list with:
  - Icon by type
  - Summary
  - Timestamp (relative + full on detail)
- Tap an item to open the same result view used after scanning.
- Provide:
  - Search (by raw text/summary)
  - Clear all (with confirmation)
  - Optional swipe-to-delete per item (nice-to-have)

### Performance & Limits

- Keep last N scans (e.g., 500). When inserting new scans beyond N, delete oldest.
- Consider debouncing duplicate scans:
  - If same `raw` scanned within 5 seconds, skip insert (optional).

### Testing

- Persistence insert/read/delete
- Limit pruning behavior
- Search filtering correctness

---

## 4) Integration Plan

### Step-by-step

1. Introduce classification module with tests.
2. Hook classification into scan result handler.
3. Add vCard parsing + UI rendering.
4. Add persistence layer + repository interface.
5. Add History screen + navigation.
6. Add QA pass on end-to-end flows.

### Acceptance Criteria

- Scanning a QR shows correct type and details.
- vCard codes display a contact card with actionable fields.
- Every scan appears in History with correct summary and timestamp.
- History can be searched and cleared.
- No regressions in existing scan flow.

---

## Rollback

- Feature-flag the History screen and persistence writes.
- Keep classification as a non-breaking enhancement; if issues arise, fall back to treating all results as plain text.
- If vCard parsing fails, display raw text with a “Copy” action.
