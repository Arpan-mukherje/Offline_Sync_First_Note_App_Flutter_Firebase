import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:offline_sync_queue_app/core/constants/app_colors.dart';
import 'package:offline_sync_queue_app/core/constants/app_dimensions.dart';
import 'package:offline_sync_queue_app/core/constants/app_strings.dart';
import 'package:offline_sync_queue_app/core/constants/app_text_styles.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';
import '../services/sync_queue_manager.dart';
import '../widgets/connectivity_pill.dart';
import '../widgets/empty_state.dart';
import '../widgets/note_card.dart';
import '../widgets/status_banner.dart';
import '../widgets/sync_button.dart';
import 'add_note_screen.dart';
import 'logs_screen.dart';

class NotesListScreen extends StatelessWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<NotesBloc, NotesState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: cs.surfaceContainerLow,
          appBar: AppBar(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            elevation: 0,
            title: const Text(
              AppStrings.notesTitle,
              style: AppTextStyles.appBarTitle,
            ),
            actions: [
              ConnectivityPill(isOnline: state.isOnline),
              const SizedBox(width: 10),
              StreamBuilder<SyncStats>(
                stream: SyncQueueManager.statsStream,
                initialData: SyncQueueManager.currentStats,
                builder: (context, snap) {
                  final pending = snap.data?.pendingQueue ?? 0;
                  final syncing = snap.data?.isSyncing ?? false;
                  return SyncButton(
                    pending: pending,
                    syncing: syncing,
                    onPressed: () => _onSyncPressed(context, pending),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.analytics_outlined),
                tooltip: AppStrings.tooltipLogs,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LogsScreen()),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: RefreshIndicator(
            color: cs.primary,
            onRefresh: () async =>
                context.read<NotesBloc>().add(const RefreshNotes()),
            child: Builder(
              builder: (_) {
                if (state is NotesLoading && state.notes.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.notes.isEmpty) {
                  return ListView(
                    children: const [SizedBox(height: 80), EmptyState()],
                  );
                }
                return Column(
                  children: [
                    if (state is NotesLoaded && state.isCacheStale)
                      const StatusBanner(
                        message: AppStrings.cacheStale,
                        color: AppColors.warningBanner,
                        icon: Icons.refresh,
                      ),
                    if (state is NotesError)
                      StatusBanner(
                        message: state.message,
                        color: AppColors.errorBanner,
                        icon: Icons.error_outline,
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: AppDimensions.paddingListView,
                        itemCount: state.notes.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: NoteCard(note: state.notes[index]),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddNoteScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text(AppStrings.newNote),
          ),
        );
      },
    );
  }

  void _onSyncPressed(BuildContext context, int pending) {
    if (pending == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.noPendingToSync),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.syncingItems(pending)),
          duration: const Duration(seconds: 2),
        ),
      );
      context.read<NotesBloc>().add(const SyncNow());
    }
  }
}
