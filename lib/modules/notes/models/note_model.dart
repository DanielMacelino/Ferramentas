import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'note_model.g.dart';

@HiveType(typeId: 1)
enum NoteType {
  @HiveField(0)
  text,
  @HiveField(1)
  checklist,
}

@HiveType(typeId: 2)
class ChecklistItem {
  @HiveField(0)
  String id;

  @HiveField(1)
  String text;

  @HiveField(2)
  bool isDone;

  ChecklistItem({
    String? id,
    required this.text,
    this.isDone = false,
  }) : id = id ?? const Uuid().v4();
}

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  @HiveField(5)
  bool isPinned;

  @HiveField(6)
  NoteType type;

  @HiveField(7)
  List<ChecklistItem> checklistItems;

  @HiveField(8)
  DateTime? reminderDateTime;

  @HiveField(9)
  int? colorValue; // Store color as int

  Note({
    String? id,
    this.title = '',
    this.content = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isPinned = false,
    this.type = NoteType.text,
    List<ChecklistItem>? checklistItems,
    this.reminderDateTime,
    this.colorValue,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        checklistItems = checklistItems ?? [];

  Note copyWith({
    String? title,
    String? content,
    bool? isPinned,
    NoteType? type,
    List<ChecklistItem>? checklistItems,
    DateTime? reminderDateTime,
    int? colorValue,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isPinned: isPinned ?? this.isPinned,
      type: type ?? this.type,
      checklistItems: checklistItems ?? this.checklistItems,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
