import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';
import '../models/sync_queue_item.dart';

/// Hive boxes
const String notesBoxName = 'notes';
const String syncQueueBoxName = 'sync_queue';

/// Cache TTL: cached data older than this is considered stale
const Duration cacheTtl = Duration(minutes: 5);

class LocalDatabase {
  static late Box<Note> _notesBox;
  static late Box<SyncQueueItem> _syncQueueBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(NoteAdapter());
    Hive.registerAdapter(SyncQueueItemAdapter());
    _notesBox = await Hive.openBox<Note>(notesBoxName);
    _syncQueueBox = await Hive.openBox<SyncQueueItem>(syncQueueBoxName);
  }

  // ─── Notes ────────────────────────────────────────────────────────────────

  static List<Note> getAllNotes() {
    final notes = _notesBox.values.toList();
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  static Note? getNoteById(String id) => _notesBox.get(id);

  static Future<void> saveNote(Note note) async {
    await _notesBox.put(note.id, note);
  }

  static Future<void> deleteNote(String id) async {
    await _notesBox.delete(id);
  }


  static Future<void> saveAllNotes(List<Note> notes) async {
    // Remove notes that were previously synced – they will be
    // replaced by the fresh remote copy.
    final syncedIds = _notesBox.values
        .where((n) => n.isSynced)
        .map((n) => n.id)
        .toList();
    await _notesBox.deleteAll(syncedIds);

    // Write fresh remote notes (mark them as synced + update cachedAt)
    final now = DateTime.now();
    final map = {
      for (final n in notes) n.id: n.copyWith(isSynced: true, cachedAt: now),
    };
    await _notesBox.putAll(map);
  }

  /// Returns true if the cache is fresh (within TTL)
  static bool isCacheFresh() {
    final notes = _notesBox.values.toList();
    if (notes.isEmpty) return false;
    final oldest = notes
        .where((n) => n.cachedAt != null)
        .map((n) => n.cachedAt!)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return DateTime.now().difference(oldest) < cacheTtl;
  }

  // ─── Sync Queue ───────────────────────────────────────────────────────────

  static List<SyncQueueItem> getQueueItems() =>
      _syncQueueBox.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  static Future<void> enqueue(SyncQueueItem item) async {
    // Idempotency: skip if same key already queued
    if (_syncQueueBox.containsKey(item.idempotencyKey)) return;
    await _syncQueueBox.put(item.idempotencyKey, item);
  }

  static Future<void> removeFromQueue(String idempotencyKey) async {
    await _syncQueueBox.delete(idempotencyKey);
  }

  static Future<void> updateQueueItem(SyncQueueItem item) async {
    await _syncQueueBox.put(item.idempotencyKey, item);
  }

  static int getQueueSize() => _syncQueueBox.length;

  static bool isAlreadyQueued(String idempotencyKey) =>
      _syncQueueBox.containsKey(idempotencyKey);
}
