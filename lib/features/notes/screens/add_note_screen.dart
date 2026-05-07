import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_sync_queue_app/core/constants/app_strings.dart';
import 'package:offline_sync_queue_app/core/constants/app_text_styles.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../widgets/note_form_body.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<NotesBloc>().add(
      AddNote(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
      ),
    );
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
          AppStrings.addNoteTitle,
          style: AppTextStyles.appBarTitle,
        ),
        actions: [
          TextButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check, color: Colors.white, size: 18),
            label: const Text(
              AppStrings.save,
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
          buttonLabel: AppStrings.saveNote,
          buttonIcon: Icons.save_outlined,
          onSubmit: _submit,
        ),
      ),
    );
  }
}
