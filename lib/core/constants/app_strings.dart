class AppStrings {
  AppStrings._();

  // ── App ───────────────────────────────────────────────────────────────────
  static const String appTitle = 'Offline Sync Queue';

  // ── Screen titles ─────────────────────────────────────────────────────────
  static const String notesTitle = 'My Notes';
  static const String logsTitle = 'Sync Logs & Stats';
  static const String addNoteTitle = 'New Note';
  static const String editNoteTitle = 'Edit Note';

  // ── Buttons & actions ─────────────────────────────────────────────────────
  static const String save = 'Save';
  static const String update = 'Update';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String newNote = 'New Note';
  static const String saveNote = 'Save Note';
  static const String updateNote = 'Update Note';

  // ── Connectivity ──────────────────────────────────────────────────────────
  static const String online = 'Online';
  static const String offline = 'Offline';

  // ── Sync stat labels ──────────────────────────────────────────────────────
  static const String pending = 'Pending';
  static const String synced = 'Synced';
  static const String failed = 'Failed';

  // ── Snackbar messages ─────────────────────────────────────────────────────
  static const String noPendingToSync = 'No pending items to sync.';
  static String syncingItems(int count) =>
      'Syncing $count pending item${count == 1 ? '' : 's'}…';

  // ── Empty / placeholder ───────────────────────────────────────────────────
  static const String emptyNotesTitle = 'No notes yet';
  static const String emptyNotesSubtitle =
      'Tap "New Note" below to create your first note';
  static const String emptyLogsText = 'No activity yet';
  static const String activityLogLabel = 'ACTIVITY LOG';

  // ── Status banners ────────────────────────────────────────────────────────
  static const String cacheStale = 'Cache is stale – pull down to refresh';

  // ── Form fields ───────────────────────────────────────────────────────────
  static const String titleLabel = 'Title';
  static const String titleHint = 'Enter note title…';
  static const String contentLabel = 'Content';
  static const String contentHint = 'Write your note here…';
  static const String titleValidator = 'Enter a title';
  static const String contentValidator = 'Enter content';

  // ── Delete dialog ─────────────────────────────────────────────────────────
  static const String deleteNoteTitle = 'Delete Note';
  static String deleteNoteContent(String title) => 'Delete "$title"?';

  // ── Tooltips ──────────────────────────────────────────────────────────────
  static const String tooltipSync = 'Retry sync';
  static const String tooltipLogs = 'Logs & Stats';
}
