import 'package:equatable/equatable.dart';
import '../models/note.dart';

abstract class NotesState extends Equatable {
  final List<Note> notes;
  final bool isOnline;
  const NotesState({required this.notes, required this.isOnline});
  @override
  List<Object?> get props => [notes, isOnline];
}

class NotesInitial extends NotesState {
  const NotesInitial() : super(notes: const [], isOnline: true);
}

class NotesLoading extends NotesState {
  final List<Note> cachedNotes;
  const NotesLoading({required this.cachedNotes, required super.isOnline})
    : super(notes: cachedNotes);
}

class NotesLoaded extends NotesState {
  final bool isCacheStale;
  const NotesLoaded({
    required super.notes,
    required super.isOnline,
    this.isCacheStale = false,
  });

  @override
  List<Object?> get props => [notes, isOnline, isCacheStale];
}

class NotesError extends NotesState {
  final String message;
  const NotesError({
    required this.message,
    required super.notes,
    required super.isOnline,
  });

  @override
  List<Object?> get props => [message, notes, isOnline];
}
