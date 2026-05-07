class SyncLog {
  final String message;
  final DateTime timestamp;
  final SyncLogLevel level;

  SyncLog({
    required this.message,
    required this.timestamp,
    this.level = SyncLogLevel.info,
  });

  @override
  String toString() =>
      '[${level.name.toUpperCase()}] ${timestamp.toIso8601String()} - $message';
}

enum SyncLogLevel { info, warning, error, success }
