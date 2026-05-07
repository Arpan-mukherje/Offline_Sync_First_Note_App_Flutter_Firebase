import 'package:flutter/material.dart';
import 'package:offline_sync_queue_app/core/constants/app_dimensions.dart';
import 'package:offline_sync_queue_app/core/constants/app_strings.dart';
import 'package:offline_sync_queue_app/core/constants/app_text_styles.dart';

/// Shown on the notes list when there are no notes yet.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: AppDimensions.iconEmptyState,
              color: cs.primary.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 20),
            Text(
              AppStrings.emptyNotesTitle,
              style: AppTextStyles.emptyTitle.copyWith(
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.emptyNotesSubtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.emptySubtitle.copyWith(
                color: cs.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
