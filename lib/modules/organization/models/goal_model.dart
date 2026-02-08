import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'goal_model.g.dart';

@HiveType(typeId: 5)
class Goal extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  double targetAmount;

  @HiveField(3)
  double currentAmount;

  @HiveField(4)
  DateTime? deadline;

  @HiveField(5)
  String description;

  @HiveField(6)
  bool isCompleted;

  Goal({
    String? id,
    required this.title,
    this.targetAmount = 0,
    this.currentAmount = 0,
    this.deadline,
    this.description = '',
    this.isCompleted = false,
  }) : id = id ?? const Uuid().v4();

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
}
