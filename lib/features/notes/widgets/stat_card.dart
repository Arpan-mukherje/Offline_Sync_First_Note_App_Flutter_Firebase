import 'package:flutter/material.dart';
import 'package:offline_sync_queue_app/core/constants/app_dimensions.dart';
import 'package:offline_sync_queue_app/core/constants/app_text_styles.dart';

class StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppDimensions.br16,
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: AppDimensions.iconXL),
          const SizedBox(height: 8),
          Text('$value', style: AppTextStyles.statValue.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.statLabel.copyWith(
              color: color.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
