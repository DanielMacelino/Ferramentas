import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../notes/models/note_model.dart';
import '../../notes/services/notification_service.dart';
import '../../../services/local_storage_service.dart';

final notesProvider = StateNotifierProvider<NotesNotifier, List<Note>>((ref) {
  return NotesNotifier();
});

class NotesNotifier extends StateNotifier<List<Note>> {
  NotesNotifier() : super([]) {
    _loadNotes();
  }

  Box<Note>? _box;

  Future<void> _loadNotes() async {
    _box = await LocalStorageService.openBox<Note>('notes');
    state = _box!.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> addNote(Note note) async {
    if (_box == null) await _loadNotes();
    await _box!.put(note.id, note);
    state = [...state, note]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    
    if (note.reminderDateTime != null) {
      await NotificationService().scheduleNotification(
        id: note.id.hashCode,
        title: note.title.isNotEmpty ? note.title : 'Lembrete de Nota',
        body: note.content.isNotEmpty ? note.content : 'Você tem um lembrete pendente.',
        scheduledDate: note.reminderDateTime!,
      );
    }
  }

  Future<void> updateNote(Note note) async {
    if (_box == null) await _loadNotes();
    note.updatedAt = DateTime.now();
    await _box!.put(note.id, note);
    
    // Update state
    state = [
      for (final n in state)
        if (n.id == note.id) note else n
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // Update notification
    if (note.reminderDateTime != null) {
       await NotificationService().scheduleNotification(
        id: note.id.hashCode,
        title: note.title.isNotEmpty ? note.title : 'Lembrete de Nota',
        body: note.content.isNotEmpty ? note.content : 'Você tem um lembrete pendente.',
        scheduledDate: note.reminderDateTime!,
      );
    } else {
      await NotificationService().cancelNotification(note.id.hashCode);
    }
  }

  Future<void> deleteNote(String id) async {
    if (_box == null) await _loadNotes();
    await _box!.delete(id);
    state = state.where((n) => n.id != id).toList();
    await NotificationService().cancelNotification(id.hashCode);
  }

  Future<void> togglePin(String id) async {
    final note = state.firstWhere((n) => n.id == id);
    final updatedNote = note.copyWith(isPinned: !note.isPinned);
    await updateNote(updatedNote);
  }
}
