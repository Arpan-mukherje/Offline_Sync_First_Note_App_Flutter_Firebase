import 'package:flutter/material.dart';
import 'package:offline_sync_queue_app/core/constants/app_colors.dart';
import 'package:offline_sync_queue_app/core/constants/app_strings.dart';
import 'package:offline_sync_queue_app/core/constants/app_text_styles.dart';

/// Pill-shaped badge showing current connectivity status.
class ConnectivityPill extends StatelessWidget {
  final bool isOnline;
  const ConnectivityPill({super.key, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final bg = isOnline ? AppColors.online : AppColors.offline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bg.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.wifi : Icons.wifi_off,
            size: 13,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            isOnline ? AppStrings.online : AppStrings.offline,
            style: AppTextStyles.connectivityLabel,
          ),
        ],
      ),
    );
  }
}
