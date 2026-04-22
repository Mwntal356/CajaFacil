import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 4)
class Expense extends HiveObject {
  @HiveField(0)
  String description;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String category; // e.g., 'Renta', 'Sueldos', 'Servicios', 'Otros'

  Expense({
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
  });
}
