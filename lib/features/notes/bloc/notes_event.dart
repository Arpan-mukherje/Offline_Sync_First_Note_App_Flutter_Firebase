import 'package:equatable/equatable.dart';
import '../models/note.dart';

abstract class NotesEvent extends Equatable {
  const NotesEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotes extends NotesEvent {
  const LoadNotes();
}

class RefreshNotes extends NotesEvent {
  const RefreshNotes();
}

class AddNote extends NotesEvent {
  final String title;
  final String content;
  const AddNote({required this.title, required this.content});
  @override
  List<Object?> get props => [title, content];
}

class UpdateNote extends NotesEvent {
  final Note note;
  const UpdateNote(this.note);
  @override
  List<Object?> get props => [note];
}

class DeleteNote extends NotesEvent {
  final String noteId;
  const DeleteNote(this.noteId);
  @override
  List<Object?> get props => [noteId];
}

class ToggleLike extends NotesEvent {
  final Note note;
  const ToggleLike(this.note);
  @override
  List<Object?> get props => [note];
}

class ToggleSave extends NotesEvent {
  final Note note;
  const ToggleSave(this.note);
  @override
  List<Object?> get props => [note];
}

class SyncNow extends NotesEvent {
  const SyncNow();
}

class ConnectivityChanged extends NotesEvent {
  final bool isOnline;
  const ConnectivityChanged(this.isOnline);
  @override
  List<Object?> get props => [isOnline];
}
