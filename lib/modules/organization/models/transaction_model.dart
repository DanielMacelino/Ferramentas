import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 3)
class Transaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  bool isIncome;

  @HiveField(5)
  String category;

  Transaction({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isIncome,
    this.category = 'Geral',
  }) : id = id ?? const Uuid().v4();
}
