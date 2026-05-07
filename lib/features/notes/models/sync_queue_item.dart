import 'package:hive/hive.dart';

part 'sync_queue_item.g.dart';

/// Action types for queued offline operations
enum SyncAction { addNote, updateNote, deleteNote, likeNote, saveNote }

@HiveType(typeId: 1)
class SyncQueueItem extends HiveObject {
  /// Idempotency key: unique per logical operation so retries never duplicate
  @HiveField(0)
  String idempotencyKey;

  @HiveField(1)
  String action; // serialized SyncAction name

  @HiveField(2)
  Map<String, dynamic> payload;

  @HiveField(3)
  int retryCount;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime? lastAttemptAt;

  @HiveField(6)
  bool isProcessing;

  SyncQueueItem({
    required this.idempotencyKey,
    required this.action,
    required this.payload,
    this.retryCount = 0,
    required this.createdAt,
    this.lastAttemptAt,
    this.isProcessing = false,
  });

  SyncAction get syncAction => SyncAction.values.firstWhere(
    (e) => e.name == action,
    orElse: () => SyncAction.updateNote,
  );

  @override
  String toString() =>
      'SyncQueueItem(key: $idempotencyKey, action: $action, retries: $retryCount)';
}
