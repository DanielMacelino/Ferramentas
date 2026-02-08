import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/notes_provider.dart';
import '../models/note_model.dart';
import 'note_editor_screen.dart';

enum NotesFilter { all, text, checklist, reminders, pinned }

class NotesScreen extends ConsumerWidget {
  final NotesFilter filter;

  const NotesScreen({super.key, this.filter = NotesFilter.all});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final filtered = _filterNotes(notes, filter);
    final pinnedNotes = filtered.where((n) => n.isPinned).toList();
    final otherNotes = filtered.where((n) => !n.isPinned).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForFilter(filter)),
      ),
      body: notes.isEmpty
          ? const Center(
              child: Text('Nenhuma nota criada. Toque no + para começar!'),
            )
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (pinnedNotes.isNotEmpty) ...[
                  const Text(
                    'Fixadas',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ...pinnedNotes.map((note) => NoteCard(note: note)),
                  const SizedBox(height: 24),
                if (otherNotes.isNotEmpty) ...[
                  const Text(
                    'Outras',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                ],
                ],
                ...otherNotes.map((note) => NoteCard(note: note)),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NoteEditorScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Note> _filterNotes(List<Note> notes, NotesFilter filter) {
    switch (filter) {
      case NotesFilter.text:
        return notes.where((n) => n.type == NoteType.text).toList();
      case NotesFilter.checklist:
        return notes.where((n) => n.type == NoteType.checklist).toList();
      case NotesFilter.reminders:
        return notes.where((n) => n.reminderDateTime != null).toList();
      case NotesFilter.pinned:
        return notes.where((n) => n.isPinned).toList();
      case NotesFilter.all:
      default:
        return notes;
    }
  }

  String _titleForFilter(NotesFilter filter) {
    switch (filter) {
      case NotesFilter.text:
        return 'Notas Simples';
      case NotesFilter.checklist:
        return 'Lista de Tarefas';
      case NotesFilter.reminders:
        return 'Lembretes';
      case NotesFilter.pinned:
        return 'Notas Fixadas';
      case NotesFilter.all:
      default:
        return 'Todas as Notas';
    }
  }
}

class NoteCard extends StatelessWidget {
  final Note note;

  const NoteCard({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteEditorScreen(note: note),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: note.colorValue != null ? Color(note.colorValue!) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      note.title.isNotEmpty ? note.title : 'Sem Título',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (note.isPinned)
                    const Icon(Icons.push_pin, size: 16, color: Colors.orange),
                  if (note.reminderDateTime != null)
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.alarm, size: 16, color: Colors.blue),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (note.type == NoteType.text)
                Text(
                  note.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8)),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: note.checklistItems.take(3).map((item) {
                    return Row(
                      children: [
                        Icon(
                          item.isDone ? Icons.check_box : Icons.check_box_outline_blank,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              decoration: item.isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              const SizedBox(height: 8),
              Text(
                dateFormat.format(note.updatedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
