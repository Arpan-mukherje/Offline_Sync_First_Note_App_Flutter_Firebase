import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../models/sync_queue_item.dart';
import '../services/connectivity_service.dart';
import '../services/firebase_service.dart'; 
import '../services/local_database.dart';
import '../services/sync_queue_manager.dart';
import 'notes_event.dart';
import 'notes_state.dart';

const _uuid = Uuid();

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  StreamSubscription? _connectivitySub;

  NotesBloc() : super(const NotesInitial()) {
    on<LoadNotes>(_onLoadNotes);
    on<RefreshNotes>(_onRefreshNotes);
    on<AddNote>(_onAddNote);
    on<UpdateNote>(_onUpdateNote);
    on<DeleteNote>(_onDeleteNote);
    on<ToggleLike>(_onToggleLike);
    on<ToggleSave>(_onToggleSave);
    on<SyncNow>(_onSyncNow);
    on<ConnectivityChanged>(_onConnectivityChanged);

    // React to connectivity changes
    _connectivitySub = ConnectivityService.onlineStream.listen((isOnline) {
      add(ConnectivityChanged(isOnline));
    });
  }

  // ─── Load notes (local-first) ──────────────────────────────────────────

  Future<void> _onLoadNotes(LoadNotes event, Emitter<NotesState> emit) async {
    final cached = LocalDatabase.getAllNotes();
    final isOnline = ConnectivityService.isOnline;
    final isCacheStale = !LocalDatabase.isCacheFresh();

    // Emit cached data immediately
    emit(NotesLoading(cachedNotes: cached, isOnline: isOnline));

    if (isOnline && (cached.isEmpty || isCacheStale)) {
      // Background refresh
      try {
        final remoteNotes = await FirebaseService.fetchAllNotes();
        await LocalDatabase.saveAllNotes(remoteNotes);
        emit(NotesLoaded(notes: remoteNotes, isOnline: true));
      } catch (e) {
        
        //Added by Arpan
        // Firestore may fail even though the network interface is "up".
        // Mark stale=true so the banner is shown. ConnectivityService will
        // emit true again once internet is confirmed, triggering SyncNow.
        emit(
          NotesLoaded(notes: cached, isOnline: isOnline, isCacheStale: true),
        );
      }
    } else {
      emit(
        NotesLoaded(
          notes: cached,
          isOnline: isOnline,
          isCacheStale: isCacheStale,
        ),
      );
    }
  }

  // ─── Pull-to-refresh ──────────────────────────────────────────────────

  Future<void> _onRefreshNotes(
    RefreshNotes event,
    Emitter<NotesState> emit,
  ) async {
    final cached = LocalDatabase.getAllNotes();
    final isOnline = ConnectivityService.isOnline;

    if (!isOnline) {
      emit(NotesLoaded(notes: cached, isOnline: false, isCacheStale: true));
      return;
    }

    try {
      final remoteNotes = await FirebaseService.fetchAllNotes();
      await LocalDatabase.saveAllNotes(remoteNotes);
      emit(NotesLoaded(notes: remoteNotes, isOnline: true));
    } catch (e) {
      emit(
        NotesError(
          message: 'Refresh failed: $e',
          notes: cached,
          isOnline: isOnline,
        ),
      );
    }
  }

  // ─── Add note ──────────────────────────────────────────────────────────

  Future<void> _onAddNote(AddNote event, Emitter<NotesState> emit) async {
    final now = DateTime.now();
    final note = Note(
      id: _uuid.v4(),
      title: event.title,
      content: event.content,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
      cachedAt: now,
    );

    // 1. Save locally (optimistic – show instantly)
    await LocalDatabase.saveNote(note);
    emit(
      NotesLoaded(
        notes: LocalDatabase.getAllNotes(),
        isOnline: ConnectivityService.isOnline,
      ),
    );

    // 2. Always enqueue – guarantees logging, idempotency, durability
    await _enqueueNote(note, SyncAction.addNote);

    // 3. If online, process the queue immediately
    if (ConnectivityService.isOnline) {
      await SyncQueueManager.processQueue();
      emit(NotesLoaded(notes: LocalDatabase.getAllNotes(), isOnline: true));
    }
  }

  // ─── Update note ───────────────────────────────────────────────────────

  Future<void> _onUpdateNote(UpdateNote event, Emitter<NotesState> emit) async {
    final note = event.note.copyWith(
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    await LocalDatabase.saveNote(note);
    emit(
      NotesLoaded(
        notes: LocalDatabase.getAllNotes(),
        isOnline: ConnectivityService.isOnline,
      ),
    );

    await _enqueueNote(note, SyncAction.updateNote);

    if (ConnectivityService.isOnline) {
      await SyncQueueManager.processQueue();
      emit(NotesLoaded(notes: LocalDatabase.getAllNotes(), isOnline: true));
    }
  }

  // ─── Delete note ───────────────────────────────────────────────────────

  Future<void> _onDeleteNote(DeleteNote event, Emitter<NotesState> emit) async {
    await LocalDatabase.deleteNote(event.noteId);
    emit(
      NotesLoaded(
        notes: LocalDatabase.getAllNotes(),
        isOnline: ConnectivityService.isOnline,
      ),
    );

    await SyncQueueManager.enqueue(
      SyncQueueItem(
        idempotencyKey: 'delete_${event.noteId}',
        action: SyncAction.deleteNote.name,
        payload: {'id': event.noteId},
        createdAt: DateTime.now(),
      ),
    );

    if (ConnectivityService.isOnline) {
      await SyncQueueManager.processQueue();
    }
  }

  // ─── Like ──────────────────────────────────────────────────────────────

  Future<void> _onToggleLike(ToggleLike event, Emitter<NotesState> emit) async {
    final updated = event.note.copyWith(
      isLiked: !event.note.isLiked,
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    await LocalDatabase.saveNote(updated);
    emit(
      NotesLoaded(
        notes: LocalDatabase.getAllNotes(),
        isOnline: ConnectivityService.isOnline,
      ),
    );

    // Idempotency key encodes the target value → toggling twice = two distinct keys
    await SyncQueueManager.enqueue(
      SyncQueueItem(
        idempotencyKey: 'like_${updated.id}_${updated.isLiked}',
        action: SyncAction.likeNote.name,
        payload: {'id': updated.id, 'isLiked': updated.isLiked},
        createdAt: DateTime.now(),
      ),
    );

    if (ConnectivityService.isOnline) {
      await SyncQueueManager.processQueue();
      emit(NotesLoaded(notes: LocalDatabase.getAllNotes(), isOnline: true));
    }
  }

  // ─── Save ──────────────────────────────────────────────────────────────

  Future<void> _onToggleSave(ToggleSave event, Emitter<NotesState> emit) async {
    final updated = event.note.copyWith(
      isSaved: !event.note.isSaved,
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    await LocalDatabase.saveNote(updated);
    emit(
      NotesLoaded(
        notes: LocalDatabase.getAllNotes(),
        isOnline: ConnectivityService.isOnline,
      ),
    );

    await SyncQueueManager.enqueue(
      SyncQueueItem(
        idempotencyKey: 'save_${updated.id}_${updated.isSaved}',
        action: SyncAction.saveNote.name,
        payload: {'id': updated.id, 'isSaved': updated.isSaved},
        createdAt: DateTime.now(),
      ),
    );

    if (ConnectivityService.isOnline) {
      await SyncQueueManager.processQueue();
      emit(NotesLoaded(notes: LocalDatabase.getAllNotes(), isOnline: true));
    }
  }

  // ─── Manual sync ───────────────────────────────────────────────────────

  Future<void> _onSyncNow(SyncNow event, Emitter<NotesState> emit) async {
    // Give exhausted items a fresh chance when user explicitly triggers sync
    await SyncQueueManager.resetExhaustedItems();
    await SyncQueueManager.processQueue();
    if (ConnectivityService.isOnline) {
      try {
        final remoteNotes = await FirebaseService.fetchAllNotes();
        await LocalDatabase.saveAllNotes(remoteNotes);
        emit(NotesLoaded(notes: LocalDatabase.getAllNotes(), isOnline: true));
      } catch (_) {
        emit(
          NotesLoaded(
            notes: LocalDatabase.getAllNotes(),
            isOnline: ConnectivityService.isOnline,
          ),
        );
      }
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  Future<void> _enqueueNote(Note note, SyncAction action) async {
    // Idempotency key: <action>_<noteId>_<updatedAt millis>
    // Same note + same action + same timestamp = same key → dedup
    final key =
        '${action.name}_${note.id}_${note.updatedAt.millisecondsSinceEpoch}';
    await SyncQueueManager.enqueue(
      SyncQueueItem(
        idempotencyKey: key,
        action: action.name,
        payload: note.toMap(),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<NotesState> emit,
  ) async {
    final notes = state.notes;
    if (event.isOnline) {
      
      await FirebaseService.enableNetwork();
      emit(NotesLoaded(notes: notes, isOnline: true, isCacheStale: false));
      add(const SyncNow());
    } else {
      emit(NotesLoaded(notes: notes, isOnline: false));
    }
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    return super.close();
  }
}
