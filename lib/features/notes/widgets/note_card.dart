import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:offline_sync_queue_app/core/constants/app_colors.dart';
import 'package:offline_sync_queue_app/core/constants/app_dimensions.dart';
import 'package:offline_sync_queue_app/core/constants/app_strings.dart';
import 'package:offline_sync_queue_app/core/constants/app_text_styles.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../models/note.dart';
import '../screens/edit_note_screen.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  const NoteCard({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: AppDimensions.br16,
        side: BorderSide(
          color: cs.outline.withValues(alpha: 0.25),
          width: AppDimensions.cardBorderWidth,
        ),
      ),
      child: InkWell(
        borderRadius: AppDimensions.br16,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EditNoteScreen(note: note)),
        ),
        child: Padding(
          padding: AppDimensions.paddingCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title row ──────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: AppTextStyles.noteTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                 
                ],
              ),
              const SizedBox(height: 8),
              // ── Content preview ────────────────────────────────────────
              Text(
                note.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.noteContent.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              // ── Footer ─────────────────────────────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: AppDimensions.iconSM,
                    color: cs.onSurface.withValues(alpha: 0.38),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, y · HH:mm').format(note.updatedAt),
                    style: AppTextStyles.noteTimestamp.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.38),
                    ),
                  ),
                  const Spacer(),
                  _ActionChip(
                    icon: note.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: AppColors.like,
                    active: note.isLiked,
                    onTap: () =>
                        context.read<NotesBloc>().add(ToggleLike(note)),
                  ),
                  const SizedBox(width: 6),
                  _ActionChip(
                    icon: note.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: AppColors.bookmark,
                    active: note.isSaved,
                    onTap: () =>
                        context.read<NotesBloc>().add(ToggleSave(note)),
                  ),
                  const SizedBox(width: 6),
                  _ActionChip(
                    icon: Icons.delete_outline,
                    color: AppColors.delete,
                    active: false,
                    onTap: () => _confirmDelete(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppDimensions.br20),
        title: const Text(AppStrings.deleteNoteTitle),
        content: Text(AppStrings.deleteNoteContent(note.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.delete),
            onPressed: () {
              Navigator.pop(context);
              context.read<NotesBloc>().add(DeleteNote(note.id));
            },
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}



class _ActionChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppDimensions.br10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.12)
              : color.withValues(alpha: 0.01),
          borderRadius: AppDimensions.br10,
          border: Border.all(
            color: active
                ? color.withValues(alpha: 0.45)
                : color.withValues(alpha: 0.18),
          ),
        ),
        child: Icon(
          icon,
          size: AppDimensions.iconLG,
          color: active ? color : color.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}
