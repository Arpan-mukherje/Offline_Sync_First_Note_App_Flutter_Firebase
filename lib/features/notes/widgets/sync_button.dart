import 'package:flutter/material.dart';
import 'package:offline_sync_queue_app/core/constants/app_colors.dart';
import 'package:offline_sync_queue_app/core/constants/app_strings.dart';
import 'package:offline_sync_queue_app/core/constants/app_text_styles.dart';

class SyncButton extends StatelessWidget {
  final int pending;
  final bool syncing;
  final VoidCallback onPressed;

  const SyncButton({
    super.key,
    required this.pending,
    required this.syncing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          tooltip: AppStrings.tooltipSync,
          onPressed: syncing ? null : onPressed,
          icon:const Icon(Icons.sync),
        ),
        if (pending > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppColors.pending,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('$pending', style: AppTextStyles.badgeCount),
              ),
            ),
          ),
      ],
    );
  }
}
