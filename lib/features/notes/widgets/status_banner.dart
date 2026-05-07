import 'package:flutter/material.dart';
import 'package:offline_sync_queue_app/core/constants/app_text_styles.dart';

class StatusBanner extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;

  const StatusBanner({
    super.key,
    required this.message,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.statusBannerText.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
