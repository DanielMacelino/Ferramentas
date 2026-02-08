import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'calendar_event_model.g.dart';

@HiveType(typeId: 4)
class CalendarEvent extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String description;

  CalendarEvent({
    String? id,
    required this.title,
    required this.date,
    this.description = '',
  }) : id = id ?? const Uuid().v4();
}
