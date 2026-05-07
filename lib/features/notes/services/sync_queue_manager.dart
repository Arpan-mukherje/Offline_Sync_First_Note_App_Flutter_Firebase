import 'dart:async';
import 'package:logger/logger.dart';
import '../models/note.dart';
import '../models/sync_log.dart';
import '../models/sync_queue_item.dart';
import 'connectivity_service.dart';
import 'firebase_service.dart';
import 'local_database.dart';

/// Observability counters exposed to the UI
class SyncStats {
  int syncSuccess = 0;
  int syncFail = 0;
  int pendingQueue = 0;
  bool isSyncing = false;

  SyncStats copyWith({
    int? syncSuccess,
    int? syncFail,
    int? pendingQueue,
    bool? isSyncing,
  }) {
    return SyncStats()
      ..syncSuccess = syncSuccess ?? this.syncSuccess
      ..syncFail = syncFail ?? this.syncFail
      ..pendingQueue = pendingQueue ?? this.pendingQueue
      ..isSyncing = isSyncing ?? this.isSyncing;
  }
}

class SyncQueueManager {
  static final Logger _log = Logger(printer: PrettyPrinter(methodCount: 0));

  static const int _maxRetries = 2;

  static final StreamController<List<SyncLog>> _logsController =
      StreamController<List<SyncLog>>.broadcast();
  static Stream<List<SyncLog>> get logsStream => _logsController.stream;

  static final StreamController<SyncStats> _statsController =
      StreamController<SyncStats>.broadcast();
  static Stream<SyncStats> get statsStream => _statsController.stream;

  static final List<SyncLog> _logs = [];
  static final SyncStats _stats = SyncStats();

  static StreamSubscription? _connectivitySub;
  static bool _isSyncing = false;

  static Future<void> init() async {
    // ── Seed local stats immediately so the UI has data before Firestore ──
    _stats.pendingQueue = LocalDatabase.getQueueSize();
    _statsController.add(_stats.copyWith(pendingQueue: _stats.pendingQueue));


    unawaited(_restoreRemoteObservability());

    // Process any items left in queue from a previous session
    if (ConnectivityService.isOnline && LocalDatabase.getQueueSize() > 0) {
      _addLog(
        'App started online with ${LocalDatabase.getQueueSize()} queued item(s) – syncing',
        SyncLogLevel.info,
      );
      processQueue(); // fire-and-forget; runs in background
    }

    _connectivitySub = ConnectivityService.onlineStream.listen((isOnline) {
      if (isOnline) {
        _addLog('Network restored – starting sync', SyncLogLevel.info);
        processQueue();
      } else {
        _addLog('Network lost – queuing writes', SyncLogLevel.warning);
      }
    });
  }

  static Future<void> _restoreRemoteObservability() async {
    final savedStats = await FirebaseService.fetchStats();
    if (savedStats != null) {
      _stats.syncSuccess = (savedStats['synced'] as num?)?.toInt() ?? 0;
      _stats.syncFail = (savedStats['failed'] as num?)?.toInt() ?? 0;
      _stats.pendingQueue = LocalDatabase.getQueueSize();
      _statsController.add(_stats.copyWith(pendingQueue: _stats.pendingQueue));
    }

    final savedLogs = await FirebaseService.fetchLogs();
    for (final entry in savedLogs) {
      final level = _parseSyncLogLevel(entry['level'] as String? ?? '');
      final timestamp =
          DateTime.tryParse(entry['timestamp'] as String? ?? '') ??
          DateTime.now();
      _logs.add(
        SyncLog(
          message: entry['message'] as String? ?? '',
          timestamp: timestamp,
          level: level,
        ),
      );
    }
    if (_logs.isNotEmpty) {
      _logsController.add(List.unmodifiable(_logs));
    }
  }

  static SyncLogLevel _parseSyncLogLevel(String value) {
    switch (value) {
      case 'warning':
        return SyncLogLevel.warning;
      case 'error':
        return SyncLogLevel.error;
      case 'success':
        return SyncLogLevel.success;
      default:
        return SyncLogLevel.info;
    }
  }

  // ─── Enqueue ──────────────────────────────────────────────────────────────

  static Future<void> enqueue(SyncQueueItem item) async {
    if (LocalDatabase.isAlreadyQueued(item.idempotencyKey)) {
      _addLog(
        'Duplicate skipped – key: ${item.idempotencyKey}',
        SyncLogLevel.warning,
      );
      return;
    }
    await LocalDatabase.enqueue(item);
    _stats.pendingQueue = LocalDatabase.getQueueSize();
    _emitStats();
    _addLog(
      'Enqueued [${item.action}] key=${item.idempotencyKey} | queue size=${_stats.pendingQueue}',
      SyncLogLevel.info,
    );
  }

  // ─── Process queue ────────────────────────────────────────────────────────

  static Future<void> processQueue() async {
    if (_isSyncing) return;
    if (!ConnectivityService.isOnline) {
      _addLog(
        'Offline – added to queue, will sync when back online',
        SyncLogLevel.warning,
      );
      return;
    }

    _isSyncing = true;
    _stats.isSyncing = true;
    _statsController.add(_stats.copyWith());
    // Only process items that have retries remaining.
    // Exhausted items stay in queue until the user manually resets them.
    final items = LocalDatabase.getQueueItems()
        .where((i) => i.retryCount <= _maxRetries)
        .toList();
    if (items.isEmpty) {
      _stats.isSyncing = false;
      _isSyncing = false;
      _emitStats();
      return;
    }
    _addLog('Processing queue: ${items.length} item(s)', SyncLogLevel.info);

    for (final item in items) {
      await _processItem(item);
    }

    _stats.pendingQueue = LocalDatabase.getQueueSize();
    _stats.isSyncing = false;
    _isSyncing = false;
    _emitStats();
  }

  static Future<void> _processItem(SyncQueueItem item) async {
    item.isProcessing = true;
    item.lastAttemptAt = DateTime.now();
    await LocalDatabase.updateQueueItem(item);

    try {
      await _dispatch(item);
      await LocalDatabase.removeFromQueue(item.idempotencyKey);
      _stats.syncSuccess++;
      _emitStats();
      _addLog(
        'Synced [${item.action}] key=${item.idempotencyKey}',
        SyncLogLevel.success,
      );
    } catch (e) {
      item.retryCount++;
      item.isProcessing = false;

      if (item.retryCount <= _maxRetries) {
        // Exponential backoff: 2^retryCount seconds
        final delay = Duration(seconds: 1 << item.retryCount);
        _addLog(
          'Failed [${item.action}] retry ${item.retryCount}/$_maxRetries – backoff ${delay.inSeconds}s | error: $e',
          SyncLogLevel.error,
        );
        await LocalDatabase.updateQueueItem(item);
        await Future.delayed(delay);
        await _processItem(item); // retry
      } else {
        // Max retries exceeded – leave in queue for manual resolution
        _stats.syncFail++;
        _emitStats();
        await LocalDatabase.updateQueueItem(item);
        _addLog(
          'Giving up [${item.action}] key=${item.idempotencyKey} after $_maxRetries retries',
          SyncLogLevel.error,
        );
      }
    }
  }

  static Future<void> _dispatch(SyncQueueItem item) async {
    switch (item.syncAction) {
      case SyncAction.addNote:
        final note = _noteFromPayload(item.payload);
        await FirebaseService.addNote(note);
        // Mark synced in Hive so the cloud-off icon disappears
        await LocalDatabase.saveNote(
          note.copyWith(isSynced: true, cachedAt: DateTime.now()),
        );
        break;
      case SyncAction.updateNote:
        final note = _noteFromPayload(item.payload);
        await FirebaseService.updateNote(note);
        await LocalDatabase.saveNote(
          note.copyWith(isSynced: true, cachedAt: DateTime.now()),
        );
        break;
      case SyncAction.deleteNote:
        await FirebaseService.deleteNote(item.payload['id'] as String);
        // Note is already removed from Hive – nothing to update
        break;
      case SyncAction.likeNote:
        await FirebaseService.likeNote(
          item.payload['id'] as String,
          item.payload['isLiked'] as bool,
        );
        final likedNote = LocalDatabase.getNoteById(
          item.payload['id'] as String,
        );
        if (likedNote != null) {
          await LocalDatabase.saveNote(likedNote.copyWith(isSynced: true));
        }
        break;
      case SyncAction.saveNote:
        await FirebaseService.saveNote(
          item.payload['id'] as String,
          item.payload['isSaved'] as bool,
        );
        final savedNote = LocalDatabase.getNoteById(
          item.payload['id'] as String,
        );
        if (savedNote != null) {
          await LocalDatabase.saveNote(savedNote.copyWith(isSynced: true));
        }
        break;
    }
  }

  static Note _noteFromPayload(Map<String, dynamic> payload) {
    return Note(
      id: payload['id'] as String,
      title: payload['title'] as String,
      content: payload['content'] as String,
      isLiked: payload['isLiked'] as bool? ?? false,
      isSaved: payload['isSaved'] as bool? ?? false,
      createdAt: DateTime.parse(payload['createdAt'] as String),
      updatedAt: DateTime.parse(payload['updatedAt'] as String),
    );
  }

  // ─── Observability ────────────────────────────────────────────────────────

  static void _addLog(String message, SyncLogLevel level) {
    final entry = SyncLog(
      message: message,
      timestamp: DateTime.now(),
      level: level,
    );
    _logs.insert(0, entry);
    if (_logs.length > 100) _logs.removeLast();
    _log.i(message);
    _logsController.add(List.unmodifiable(_logs));

    // Persist to Firestore (fire-and-forget)
    FirebaseService.pushLog(
      message: message,
      level: level.name,
      timestamp: entry.timestamp,
    );
  }

  static void _emitStats() {
    final pending = LocalDatabase.getQueueSize();
    _statsController.add(_stats.copyWith(pendingQueue: pending));

    // Persist to Firestore (fire-and-forget)
    FirebaseService.pushStats(
      pending: pending,
      synced: _stats.syncSuccess,
      failed: _stats.syncFail,
    );
  }

  static Future<void> resetExhaustedItems() async {
    final exhausted = LocalDatabase.getQueueItems()
        .where((i) => i.retryCount > _maxRetries)
        .toList();
    for (final item in exhausted) {
      item.retryCount = 0;
      item.isProcessing = false;
      await LocalDatabase.updateQueueItem(item);
    }
    if (exhausted.isNotEmpty) {
      _addLog(
        'Reset ${exhausted.length} exhausted item(s) for manual retry',
        SyncLogLevel.info,
      );
    }
  }

  static List<SyncLog> get currentLogs => List.unmodifiable(_logs);
  static SyncStats get currentStats => _stats;

  static void dispose() {
    _connectivitySub?.cancel();
    _logsController.close();
    _statsController.close();
  }
}
