import 'package:flutter/material.dart';
import 'package:offline_sync_queue_app/core/constants/app_dimensions.dart';
import 'package:offline_sync_queue_app/core/constants/app_strings.dart';
import 'package:offline_sync_queue_app/core/constants/app_text_styles.dart';

class NoteFormBody extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController contentController;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback onSubmit;

  const NoteFormBody({
    super.key,
    required this.titleController,
    required this.contentController,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppDimensions.paddingScreen,
      children: [
        TextFormField(
          controller: titleController,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: AppStrings.titleLabel,
            hintText: AppStrings.titleHint,
            prefixIcon: Icon(Icons.title),
          ),
          style: AppTextStyles.formInput,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? AppStrings.titleValidator
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: contentController,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: AppStrings.contentLabel,
            hintText: AppStrings.contentHint,
            alignLabelWithHint: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 120),
              child: Icon(Icons.notes),
            ),
          ),
          maxLines: 10,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? AppStrings.contentValidator
              : null,
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          icon: Icon(buttonIcon),
          label: Text(buttonLabel, style: const TextStyle(fontSize: 15)),
          onPressed: onSubmit,
          style: FilledButton.styleFrom(
            minimumSize: const Size(
              double.infinity,
              AppDimensions.buttonHeight,
            ),
            shape: RoundedRectangleBorder(borderRadius: AppDimensions.br14),
          ),
        ),
      ],
    );
  }
}
