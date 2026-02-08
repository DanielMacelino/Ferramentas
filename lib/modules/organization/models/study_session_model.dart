import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'study_session_model.g.dart';

@HiveType(typeId: 6)
class StudySession extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String subject;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  int durationMinutes;

  @HiveField(4)
  String notes;

  StudySession({
    String? id,
    required this.subject,
    required this.date,
    required this.durationMinutes,
    this.notes = '',
  }) : id = id ?? const Uuid().v4();
}
