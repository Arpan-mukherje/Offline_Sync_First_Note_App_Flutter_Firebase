import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note.dart';

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'notes';

  // ─── Fetch all notes ──────────────────────────────────────────────────────

  static Future<List<Note>> fetchAllNotes() async {
    final snapshot = await _db
        .collection(_collection)
        .orderBy('updatedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Note.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ─── Add note ─────────────────────────────────────────────────────────────
  static Future<void> addNote(Note note) async {
    await _db.collection(_collection).doc(note.id).set(note.toMap());
  }

  // ─── Update note ──────────────────────────────────────────────────────────
  static Future<void> updateNote(Note note) async {
    final docRef = _db.collection(_collection).doc(note.id);
    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      if (snapshot.exists) {
        final remoteUpdatedAt =
            DateTime.tryParse(snapshot.data()?['updatedAt'] ?? '') ??
            DateTime(0);
        if (note.updatedAt.isBefore(remoteUpdatedAt)) {
          // Remote is newer – skip (conflict resolved: last-write-wins)
          return;
        }
      }
      tx.set(docRef, note.toMap());
    });
  }

  // ─── Delete note ──────────────────────────────────────────────────────────

  static Future<void> deleteNote(String noteId) async {
    await _db.collection(_collection).doc(noteId).delete();
  }

  // ─── Like / Save (merge partial update) ──────────────────────────────────

  static Future<void> likeNote(String noteId, bool isLiked) async {
    await _db.collection(_collection).doc(noteId).update({
      'isLiked': isLiked,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> saveNote(String noteId, bool isSaved) async {
    await _db.collection(_collection).doc(noteId).update({
      'isSaved': isSaved,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // ─── Observability: logs & stats ──────────────────────────────────────────

  static const String _logsCollection = 'sync_logs';
  static const String _statsDoc = 'sync_stats/current';

  static void pushLog({
    required String message,
    required String level,
    required DateTime timestamp,
  }) {
    unawaited(() async {
      try {
        await _db.collection(_logsCollection).add({
          'message': message,
          'level': level,
          'timestamp': timestamp.toIso8601String(),
        });
      } catch (_) {}
    }());
  }

  /// Overwrites the single stats document with the latest counters.
  static void pushStats({
    required int pending,
    required int synced,
    required int failed,
  }) {
    unawaited(() async {
      try {
        await _db.doc(_statsDoc).set({
          'pending': pending,
          'synced': synced,
          'failed': failed,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }());
  }

  static Future<List<Map<String, dynamic>>> fetchLogs({int limit = 100}) async {
    try {
      final snap = await _db
          .collection(_logsCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetches the persisted stats. Returns null on error / no data.
  static Future<Map<String, dynamic>?> fetchStats() async {
    try {
      final doc = await _db.doc(_statsDoc).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }


  static Future<void> enableNetwork() async {
    try {
      await _db.enableNetwork();
    } catch (_) {}
  }
}
