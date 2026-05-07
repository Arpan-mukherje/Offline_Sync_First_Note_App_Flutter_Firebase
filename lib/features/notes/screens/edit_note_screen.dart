import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_sync_queue_app/core/constants/app_strings.dart';
import 'package:offline_sync_queue_app/core/constants/app_text_styles.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../models/note.dart';
import '../widgets/note_form_body.dart';

class EditNoteScreen extends StatefulWidget {
  final Note note;
  const EditNoteScreen({super.key, required this.note});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final updated = widget.note.copyWith(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      updatedAt: DateTime.now(),
    );
    context.read<NotesBloc>().add(UpdateNote(updated));
    Navigator.pop(context);
  }

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
          AppStrings.editNoteTitle,
          style: AppTextStyles.appBarTitle,
        ),
        actions: [
          TextButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check, color: Colors.white, size: 18),
            label: const Text(
              AppStrings.update,
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Form(
        key: _formKey,
        child: NoteFormBody(
          titleController: _titleController,
          contentController: _contentController,
          buttonLabel: AppStrings.updateNote,
          buttonIcon: Icons.update_outlined,
          onSubmit: _submit,
        ),
      ),
    );
  }
}
