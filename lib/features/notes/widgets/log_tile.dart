import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:offline_sync_queue_app/core/constants/app_colors.dart';
import 'package:offline_sync_queue_app/core/constants/app_dimensions.dart';
import 'package:offline_sync_queue_app/core/constants/app_text_styles.dart';
import '../models/sync_log.dart';

/// Single log entry tile with a colored left border and level icon.
class LogTile extends StatelessWidget {
  final SyncLog log;
  const LogTile({super.key, required this.log});

  Color get _color {
    switch (log.level) {
      case SyncLogLevel.success:
        return AppColors.logSuccess;
      case SyncLogLevel.error:
        return AppColors.logError;
      case SyncLogLevel.warning:
        return AppColors.logWarning;
      case SyncLogLevel.info:
        return AppColors.logInfo;
    }
  }

  IconData get _icon {
    switch (log.level) {
      case SyncLogLevel.success:
        return Icons.check_circle_outline;
      case SyncLogLevel.error:
        return Icons.error_outline;
      case SyncLogLevel.warning:
        return Icons.warning_amber_outlined;
      case SyncLogLevel.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.05),
          borderRadius: AppDimensions.br12,
          border: Border(
            left: BorderSide(
              color: _color,
              width: AppDimensions.logBorderWidth,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(_icon, color: _color, size: AppDimensions.iconMD),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.message,
                    style: AppTextStyles.logMessage.copyWith(color: _color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM d · HH:mm:ss').format(log.timestamp),
                    style: AppTextStyles.logTimestamp.copyWith(
                      color: _color.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
