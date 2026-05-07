# Offline Sync Queue App

A Flutter application that demonstrates an **offline-first architecture** with a persistent sync queue, Firebase Firestore backend, and real-time connectivity awareness. Built with BLoC state management, Hive local storage, and a feature-first folder structure.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture & Approach](#architecture--approach)
3. [Folder Structure](#folder-structure)
4. [Tech Stack](#tech-stack)
5. [Key Features](#key-features)
6. [How the Sync Queue Works](#how-the-sync-queue-works)
7. [Tradeoffs](#tradeoffs)
8. [Known Limitations](#known-limitations)
9. [Next Steps](#next-steps)
10. [Getting Started](#getting-started)
11. [AI Prompt Log](#ai-prompt-log)
12. [Verification Evidence](#verification-evidence)

---

## Overview

Users can create, edit, delete, like, and bookmark notes while **completely offline**. Every mutation is captured in a local Hive-backed sync queue with an idempotency key. When connectivity is restored, queued items are automatically replayed to Firestore in order. A live Logs & Stats screen shows every sync event with success/failure/warning/info levels, and stats persist across app restarts via Firestore.

---

## Architecture & Approach

### Offline-First, Local-First

The app never blocks the user on a network call. Every write goes to Hive (local) immediately and returns success to the UI. Firestore is treated as an eventually-consistent remote mirror, not the source of truth for the active session.

```
User Action
    │
    ▼
NotesBloc (flutter_bloc)
    │
    ├── Write to Hive (instant, always succeeds)
    │
    └── Enqueue SyncQueueItem in Hive queue
            │
            ▼
    SyncQueueManager
            │
    online? ─── Yes ──► FirebaseService ──► Firestore
            │
           No
            │
            └── Wait for connectivity event ──► retry
```

### State Management — BLoC

`NotesBloc` handles all user events (`AddNote`, `UpdateNote`, `DeleteNote`, `ToggleLike`, `ToggleSave`, `SyncNow`, `RefreshNotes`, `ConnectivityChanged`). States (`NotesInitial`, `NotesLoading`, `NotesLoaded`, `NotesError`) carry the full notes list so the UI is always a pure function of state.

### Sync Queue — Idempotency

Each `SyncQueueItem` has:
- `idempotencyKey` — UUID generated at write time so Firestore writes are safe to retry
- `retryCount` — max 2 retries before the item is marked failed and removed
- `action` — serialized `SyncAction` enum (`addNote`, `updateNote`, `deleteNote`, `likeNote`, `saveNote`)
- `payload` — full note snapshot, so replay works even if the app restarts

### Persistence of Logs & Stats

Sync logs and aggregate stats are pushed to Firestore after every operation (`sync_logs` collection, `sync_stats/current` document) and reloaded on `SyncQueueManager.init()`. This means the Logs screen survives app restarts.

---

## Folder Structure

```
lib/
├── core/
│   ├── config/
│   │   └── firebase_options.dart       # Auto-generated Firebase config
│   ├── constants/
│   │   ├── app_colors.dart             # Semantic color constants
│   │   ├── app_dimensions.dart         # Spacing, radius, sizing
│   │   ├── app_strings.dart            # All string literals
│   │   └── app_text_styles.dart        # Named TextStyle constants
│   └── theme/
│       └── app_theme.dart              # Material 3 ThemeData
├── features/
│   └── notes/
│       ├── bloc/
│       │   ├── notes_bloc.dart
│       │   ├── notes_event.dart
│       │   └── notes_state.dart
│       ├── models/
│       │   ├── note.dart               # Hive-persisted note model
│       │   ├── note.g.dart
│       │   ├── sync_log.dart           # In-memory log entry
│       │   ├── sync_queue_item.dart    # Hive-persisted queue item
│       │   └── sync_queue_item.g.dart
│       ├── screens/
│       │   ├── notes_list_screen.dart
│       │   ├── add_note_screen.dart
│       │   ├── edit_note_screen.dart
│       │   └── logs_screen.dart
│       ├── services/
│       │   ├── connectivity_service.dart   # connectivity_plus wrapper
│       │   ├── firebase_service.dart       # Firestore CRUD + log/stats push
│       │   ├── local_database.dart         # Hive adapter
│       │   └── sync_queue_manager.dart     # Queue orchestrator + streams
│       └── widgets/
│           ├── connectivity_pill.dart
│           ├── empty_state.dart
│           ├── log_tile.dart
│           ├── note_card.dart
│           ├── note_form_body.dart         # Shared Add/Edit form
│           ├── stat_card.dart
│           ├── status_banner.dart
│           └── sync_button.dart
└── main.dart
```

Design rationale: **feature-first** layout means every `notes/` sub-folder is self-contained. Adding a `features/auth/` or `features/settings/` module requires zero changes to existing code. `core/` holds app-wide infrastructure with no dependency on any feature.

---

## Tech Stack

| Layer | Package | Version |
|---|---|---|
| State management | flutter_bloc | ^8.1.6 |
| Equality | equatable | ^2.0.5 |
| Local storage | hive + hive_flutter | ^2.2.3 / ^1.1.0 |
| Backend | cloud_firestore + firebase_core | ^5.4.4 / ^3.6.0 |
| Connectivity | connectivity_plus | ^6.0.5 |
| ID generation | uuid | ^4.4.2 |
| Logging | logger | ^2.4.0 |
| Date formatting | intl | ^0.19.0 |

---

## Key Features

- **Offline-first writes** — create/edit/delete notes with no internet required
- **Auto-sync on reconnect** — queue is replayed automatically when connectivity returns
- **Manual sync button** — badge shows pending count; spinner shows sync in progress
- **Retry with backoff** — each item retried up to 2 times before being marked failed
- **Idempotent queue items** — safe to replay; no duplicate Firestore writes on retry
- **Persistent logs & stats** — survive app restarts via Firestore
- **Connectivity pill** — live Online / Offline badge in the app bar
- **Stale cache banner** — warns when local data is older than 5 minutes
- **Like / Bookmark / Delete** — all operations offline-capable
- **Material 3 UI** — indigo seed color, card borders, action chips, FAB
- **Feature-first architecture** — scalable to multiple features

---

## How the Sync Queue Works

```
1. User creates a note (offline or online)
   └─► Note saved to Hive immediately
   └─► SyncQueueItem(action=addNote, payload=note) enqueued in Hive

2. SyncQueueManager.processQueue() is called
   └─► If offline: returns early, subscribes to connectivity stream
   └─► If online:
       ├─ Sets isSyncing = true → UI shows spinner
       ├─ Iterates queue items in FIFO order
       │   ├─ Calls FirebaseService.addNote / updateNote / deleteNote …
       │   ├─ On success: removes item from queue, increments syncSuccess
       │   └─ On failure: increments retryCount; removes if retryCount > maxRetries
       └─ Sets isSyncing = false → UI hides spinner

3. On connectivity restored (ConnectivityService stream event)
   └─► NotesBloc fires ConnectivityChanged(true)
   └─► SyncQueueManager.processQueue() called automatically
```

---

## Tradeoffs

| Decision | Tradeoff |
|---|---|
| **Hive over SQLite** | Simpler API, no SQL, fast for key-value note storage. Tradeoff: no relational queries, no migrations tooling. |
| **Hand-written .g.dart adapters** | Avoids `build_runner` in CI. Tradeoff: must be manually updated when model fields change. |
| **BLoC over Riverpod/Provider** | Explicit event/state contracts, great testability. Tradeoff: more boilerplate for small features. |
| **Firestore rules `allow read, write: if true`** | Simplifies the demo. Tradeoff: not production-safe — real app needs auth rules. |
| **In-memory log list** | Fast reads and stream updates. Tradeoff: list grows unbounded; no pagination in this version. |
| **`connectivity_plus` stream** | Accurate real-time detection. Tradeoff: on some Android versions, returns `wifi` but device has no actual internet (captive portal). |
| **No optimistic UI rollback** | Simpler state model. Tradeoff: if sync fails after retries, UI still shows the note as synced locally. |

---

## Known Limitations

- **No authentication** — Firestore rules are open. Any user can read/write all notes.
- **No conflict resolution** — last-write-wins. If two devices edit the same note offline, the later sync overwrites silently.
- **No pagination** — all notes and all logs are loaded into memory at once. Degrades at scale (hundreds of notes).
- **Log list unbounded** — logs accumulate in memory and Firestore with no TTL or truncation.
- **Captive portal false-positives** — `connectivity_plus` reports "online" when connected to a Wi-Fi network with no actual internet access.
- **No background sync** — sync only runs when the app is in the foreground. Notes created offline are not synced until the user opens the app while online.
- **iOS alpha channel warning** — the generated app icon contains an alpha channel. Apple App Store submission requires `remove_alpha_ios: true` in the launcher icons config.
- **Single feature** — the architecture supports multiple features but only `notes` is implemented.

---

## Next Steps

1. **Add Firebase Auth** — Google Sign-In, scoped Firestore rules per `uid`
2. **Conflict resolution** — vector clocks or `updatedAt` comparison with a merge dialog
3. **Background sync** — use `workmanager` to sync even when the app is backgrounded
4. **Pagination** — Firestore cursor-based pagination + infinite scroll
5. **Log TTL / rotation** — keep only the last 100 log entries; purge older ones from Firestore
6. **Unit tests** — test `NotesBloc` with `bloc_test`, mock `FirebaseService` and `LocalDatabase`
7. **Widget tests** — `NoteCard`, `SyncButton`, `LogTile` with `flutter_test`
8. **CI/CD** — GitHub Actions: `flutter analyze` + `flutter test` on every PR
9. **Dark mode** — `AppTheme.dark` getter with `ColorScheme.fromSeed(brightness: Brightness.dark)`
10. **Note search / filter** — local full-text search over Hive box

---

## Getting Started

### Prerequisites

- Flutter SDK ^3.8.1
- Dart ^3.0
- A Firebase project with Firestore enabled
- `google-services.json` placed in `android/app/`

### Setup

```bash
# 1. Install dependencies
flutter pub get

# 2. Run the app
flutter run

# 3. (Optional) Regenerate Hive adapters if models change
dart run build_runner build --delete-conflicting-outputs
```

### Firestore Collections

| Collection | Purpose |
|---|---|
| `notes` | All notes documents |
| `sync_logs` | Individual sync event entries |
| `sync_stats/current` | Aggregate counters (synced, failed, pending) |

---

## AI Prompt Log

> Claude Sonnet 4.6 is Used for this Development.

---

### 1. Prompt — Initial app scaffold

**Prompt:**
> Build a Flutter offline-first sync queue app. Notes can be created, edited, and deleted. Operations must be queued when offline and synced to Firebase Firestore when connectivity is restored. Implement Notes list screen and show all notes there, Show the Notes date wise, latest note will be there in the top. Create a Sync Logs & Stats screen where show all the logs and stats with 3 highlited Counts "Pending", "Synced" and "Failed. 
Use BLoC for state management and Hive for local persistence. 

**Key response summary:**
- Scaffolded `NotesBloc`, `NotesEvent`, `NotesState`
- Created `Note` and `SyncQueueItem` Hive models with hand-written `.g.dart` adapters
- Created `LocalDatabase`, `FirebaseService`, `SyncQueueManager`, `ConnectivityService`
- Basic `NotesListScreen`, `AddNoteScreen`, `EditNoteScreen`

**Decision:** Accepted with minor modifications

**Why:** The overall structure matched the intended architecture. Hand-written `.g.dart` adapters were accepted to avoid `build_runner` complexity in the demo. The idempotency key pattern on `SyncQueueItem` was a strong suggestion that was kept.

---

### 2. Prompt — Firebase persistence for logs and stats

**Prompt:**
> The Logs screen clears every time the app restarts. Persist sync logs and stats to Firestore so they survive restarts, store the values in the firebase.

**Key response summary:**
- Added `pushLog()` and `pushStats()` fire-and-forget methods to `FirebaseService`
- Added `fetchLogs()` and `fetchStats()` to restore state on `SyncQueueManager.init()`
- Introduced `sync_logs` collection and `sync_stats/current` document

**Decision:** Accepted

**Why:** Exactly what was needed. Fire-and-forget push (no await) keeps the queue processing fast. Restore on init correctly seeds the in-memory lists before the first stream event.

---

### 3. Prompt — Fix "Processing queue: 0 item(s)" log spam

**Prompt:**
> Every time the app loads it logs "Processing queue: 0 item(s)" even when there is nothing to sync. Fix this.

**Key response summary:**
- Added early return in `processQueue()` before the log statement when the items list is empty

**Decision:** Accepted

**Why:** Simple one-line guard. Cleans up the log screen noise on every cold start.

---

### 4. Prompt — UX polish (snackbar feedback, delete button, offline messages, sync spinner)

**Prompt:**
> Add snackbar feedback when sync is triggered, add a delete button to note cards, improve offline messages, add a sync spinner when syncing is in progress.

**Key response summary:**
- `SyncButton` shows `CircularProgressIndicator` when `isSyncing == true` and disables `onPressed`
- Added `DeleteNote` event and dialog in `NoteCard`
- Snackbar on sync press: "Nothing to sync" or "Syncing N items…"
- Status banner shows contextual offline message

**Decision:** Accepted — spinner guard modified

**Why:** The spinner was initially added with an `if (syncing) return spinner` pattern. Modified to use `onPressed: syncing ? null : onPressed` so the button widget remains in the tree and badge count stays visible during sync.

---

### 5. Prompt — Full UI redesign

**Prompt:**
> Redesign the UI with a modern Material 3 look. Card borders, action chips for like/bookmark/delete, connectivity pill badge in the app bar, indigo color scheme, stat cards for the logs screen.

**Key response summary:**
- Full rewrite of all four screens
- `NoteCard` with `_PendingBadge`, `_ActionChip` private widgets
- Connectivity pill, sync button with badge, status banner
- `StatCard` and `LogTile` for the logs screen
- `AppTheme` with Material 3 `ColorScheme.fromSeed`

**Decision:** Accepted

**Why:** Clean separation of concerns. All hardcoded values were later extracted to constants.

---

### 6. Prompt — Refactor into constants and widgets folders

**Prompt:**
> Create a constants folder and put all colors, texts, styles, and other things there. Create a widgets folder. Make the code organized.

**Key response summary:**
- Created `app_colors.dart`, `app_text_styles.dart`, `app_dimensions.dart`, `app_strings.dart`
- Extracted `ConnectivityPill`, `SyncButton`, `StatusBanner`, `EmptyState`, `NoteCard`, `StatCard`, `LogTile`, `NoteFormBody` into `widgets/`
- Updated all screens to import from constants and widgets

**Decision:** Accepted

**Why:** Eliminated all magic numbers, raw `Colors.*` references, and inline `TextStyle(...)` literals. `NoteFormBody` as a shared widget for `AddNoteScreen` and `EditNoteScreen` was particularly good — removed ~40 lines of duplication.

---

### 7. Prompt — Create AppTheme class

**Prompt:**
> Create a Theme class and call that in main.dart.

**Key response summary:**
- Created `lib/core/theme/app_theme.dart` with `abstract final class AppTheme`
- `AppTheme.light` static getter returns the full `ThemeData`
- Uses `AppDimensions` constants instead of raw `BorderRadius.circular()` calls
- `main.dart` reduced from 50+ lines of inline ThemeData to `theme: AppTheme.light`

**Decision:** Accepted

**Why:** Clean single-responsibility. `abstract final class` (rather than a regular class) signals that the class is never instantiated — the correct pattern for a pure namespace.


---

### 8. Prompt — Android permissions

**Prompt:**
> Put the necessary permissions in the manifest.

**Key response summary:**
- Added `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE` to `AndroidManifest.xml`
- All three are normal permissions (no runtime dialog required)

**Decision:** Accepted

**Why:** All three are required. `INTERNET` for Firebase, `ACCESS_NETWORK_STATE` and `ACCESS_WIFI_STATE` for `connectivity_plus` to function correctly.

---

### 9. Prompt — App icon

**Prompt:**
> Put an app icon.

**Key response summary:**
- Generated 1024×1024 PNG using Python/Pillow: indigo rounded-square background, white cloud + circular sync arrows
- Added `flutter_launcher_icons: ^0.14.3` to `pubspec.yaml` with config for Android, iOS, Web, Windows, macOS
- Ran `dart run flutter_launcher_icons` to generate all platform-specific icon sizes

**Decision:** Accepted

**Why:** The icon visually matches the app's domain (cloud sync) and color scheme (indigo). `flutter_launcher_icons` handles all the required sizes automatically.

---

## Verification Evidence

### dart analyze

```
Analyzing lib...
No issues found!
```

Run at every major milestone. Zero warnings or errors at final state.

---

### Edge Cases Tested

| Scenario | Expected behaviour | Verified |
|---|---|---|
| Create note while offline | Note saved locally, badge count increments | ✅ |
| Restore connectivity | Queue auto-processes, spinner appears then disappears | ✅ |
| Press Sync with 0 pending | Snackbar: "Nothing to sync" | ✅ |
| Press Sync with N pending | Snackbar: "Syncing N items…", spinner shown | ✅ |
| Double-press Sync button | Second press ignored (button disabled while syncing) | ✅ |
| App restart after offline writes | Pending queue preserved, Hive restores queue | ✅ |
| App restart — Logs screen | Logs and stats restored from Firestore on init | ✅ |
| Delete note offline | Note removed from Hive, delete enqueued, synced on reconnect | ✅ |
| Edit note offline | Local update immediate, updateNote enqueued | ✅ |
| Network error during sync | Item retry count incremented; removed after 2 failures | ✅ |
| Empty notes list | `EmptyState` widget shown with prompt to add first note | ✅ |
| Stale cache (> 5 min old) | Yellow warning banner shown below app bar | ✅ |
| Like / Bookmark while offline | Action queued (likeNote / saveNote), reflected instantly in UI | ✅ |

---

### Sync Log Output (sample from Logs screen)

```
[SUCCESS] Note "Meeting agenda" synced to Firestore
[SUCCESS] Note "Shopping list" synced to Firestore
[WARNING] Sync failed for item abc-123, retrying (1/2)
[ERROR]   Sync failed for item abc-123 after 2 retries. Removing.
[INFO]    Queue processed: 3 succeeded, 1 failed
[SUCCESS] Note "Flutter notes" synced to Firestore
```

---

### Stats Persistence Test

1. Create 3 notes offline → pending = 3
2. Force-close the app
3. Re-open the app → Logs screen shows pending = 3, previous synced/failed counts restored ✅

---

### Static Analysis

```bash
flutter analyze
# No issues found!

dart analyze lib
# Analyzing lib... No issues found!
```

No `ignore` comments or suppressed warnings anywhere in the codebase.

