import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late NoteType _type;
  late bool _isPinned;
  DateTime? _reminderDateTime;
  late List<ChecklistItem> _checklistItems;
  int? _colorValue;

  final List<Color> _colors = [
    Colors.white,
    Colors.red.shade100,
    Colors.orange.shade100,
    Colors.yellow.shade100,
    Colors.green.shade100,
    Colors.blue.shade100,
    Colors.indigo.shade100,
    Colors.purple.shade100,
  ];

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _type = note?.type ?? NoteType.text;
    _isPinned = note?.isPinned ?? false;
    _reminderDateTime = note?.reminderDateTime;
    _checklistItems = note?.checklistItems.map((e) => ChecklistItem(id: e.id, text: e.text, isDone: e.isDone)).toList() ?? [];
    _colorValue = note?.colorValue;
    
    // If opening a new note, add one empty checklist item if switching to checklist
    if (_checklistItems.isEmpty && _type == NoteType.checklist) {
      _checklistItems.add(ChecklistItem(text: ''));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    
    // Remove empty checklist items
    final cleanChecklist = _checklistItems.where((item) => item.text.trim().isNotEmpty).toList();

    if (title.isEmpty && content.isEmpty && cleanChecklist.isEmpty) {
      return; // Don't save empty notes
    }

    final newNote = Note(
      id: widget.note?.id,
      title: title,
      content: content,
      type: _type,
      isPinned: _isPinned,
      reminderDateTime: _reminderDateTime,
      checklistItems: cleanChecklist,
      colorValue: _colorValue,
      createdAt: widget.note?.createdAt,
    );

    if (widget.note == null) {
      ref.read(notesProvider.notifier).addNote(newNote);
    } else {
      ref.read(notesProvider.notifier).updateNote(newNote);
    }
    Navigator.pop(context);
  }

  void _deleteNote() {
    if (widget.note != null) {
      ref.read(notesProvider.notifier).deleteNote(widget.note!.id);
    }
    Navigator.pop(context);
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderDateTime ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderDateTime ?? now),
    );

    if (time == null) return;

    setState(() {
      _reminderDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorValue != null ? Color(_colorValue!) : null,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: () => setState(() => _isPinned = !_isPinned),
            tooltip: 'Fixar',
          ),
          IconButton(
            icon: Icon(_reminderDateTime != null ? Icons.notifications_active : Icons.notifications_none),
            onPressed: _pickReminder,
            tooltip: 'Lembrete',
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  height: 100,
                  padding: const EdgeInsets.all(16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colors.length,
                    itemBuilder: (context, index) {
                      final color = _colors[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() => _colorValue = color.value);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
            tooltip: 'Cor',
          ),
          if (widget.note != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteNote,
              tooltip: 'Excluir',
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveNote,
            tooltip: 'Salvar',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_reminderDateTime != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Chip(
                label: Text(
                  'Lembrete: ${DateFormat('dd/MM/yyyy HH:mm').format(_reminderDateTime!)}',
                ),
                onDeleted: () => setState(() => _reminderDateTime = null),
                deleteIcon: const Icon(Icons.close, size: 18),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Título',
                border: InputBorder.none,
              ),
            ),
          ),
          // Toggle Type
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('Tipo: '),
                DropdownButton<NoteType>(
                  value: _type,
                  underline: Container(),
                  items: const [
                    DropdownMenuItem(value: NoteType.text, child: Text('Texto')),
                    DropdownMenuItem(value: NoteType.checklist, child: Text('Checklist')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _type = value;
                        if (_type == NoteType.checklist && _checklistItems.isEmpty) {
                          _checklistItems.add(ChecklistItem(text: ''));
                        }
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _type == NoteType.text
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        hintText: 'Comece a digitar...',
                        border: InputBorder.none,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _checklistItems.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _checklistItems.length) {
                        return ListTile(
                          leading: const Icon(Icons.add),
                          title: const Text('Adicionar item'),
                          onTap: () {
                            setState(() {
                              _checklistItems.add(ChecklistItem(text: ''));
                            });
                          },
                        );
                      }

                      final item = _checklistItems[index];
                      return Row(
                        children: [
                          Checkbox(
                            value: item.isDone,
                            onChanged: (val) {
                              setState(() {
                                item.isDone = val ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: TextFormField(
                              initialValue: item.text,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Item',
                              ),
                              onChanged: (val) {
                                item.text = val;
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _checklistItems.removeAt(index);
                              });
                            },
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
