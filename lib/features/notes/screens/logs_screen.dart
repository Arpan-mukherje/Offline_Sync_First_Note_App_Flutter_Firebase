import 'package:flutter/material.dart';

import 'package:offline_sync_queue_app/core/constants/app_colors.dart';
import 'package:offline_sync_queue_app/core/constants/app_dimensions.dart';
import 'package:offline_sync_queue_app/core/constants/app_strings.dart';
import 'package:offline_sync_queue_app/core/constants/app_text_styles.dart';
import '../models/sync_log.dart';
import '../services/sync_queue_manager.dart';
import '../widgets/log_tile.dart';
import '../widgets/stat_card.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        title: const Text(
          AppStrings.logsTitle,
          style: AppTextStyles.appBarTitle,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat cards
          StreamBuilder<SyncStats>(
            stream: SyncQueueManager.statsStream,
            initialData: SyncQueueManager.currentStats,
            builder: (context, snap) {
              final s = snap.data!;
              return Padding(
                padding: AppDimensions.paddingStatRow,
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: AppStrings.pending,
                        value: s.pendingQueue,
                        icon: Icons.pending_actions_outlined,
                        color: AppColors.pending,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: AppStrings.synced,
                        value: s.syncSuccess,
                        icon: Icons.cloud_done_outlined,
                        color: AppColors.synced,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: AppStrings.failed,
                        value: s.syncFail,
                        icon: Icons.cloud_off_outlined,
                        color: AppColors.failed,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Section label
          Padding(
            padding: AppDimensions.paddingSection,
            child: Row(
              children: [
                Icon(
                  Icons.list_alt_outlined,
                  size: AppDimensions.iconXS,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 6),
                Text(
                  AppStrings.activityLogLabel,
                  style: AppTextStyles.sectionLabel.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          // Log list
          Expanded(
            child: StreamBuilder<List<SyncLog>>(
              stream: SyncQueueManager.logsStream,
              initialData: SyncQueueManager.currentLogs,
              builder: (context, snap) {
                final logs = snap.data ?? [];
                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: AppDimensions.iconEmptyLogs,
                          color: cs.onSurface.withValues(alpha: 0.18),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.emptyLogsText,
                          style: AppTextStyles.emptyActivityText.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.38),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: AppDimensions.paddingLogList,
                  itemCount: logs.length,
                  itemBuilder: (context, i) => LogTile(log: logs[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
