import 'package:hive/hive.dart';

part 'shift.g.dart';

@HiveType(typeId: 10)
class Shift extends HiveObject {
  @HiveField(0)
  final String userId; // 'Dueño', 'Cajero 1', 'Cajero 2'

  @HiveField(1)
  final DateTime startTime;

  @HiveField(2)
  DateTime? endTime;

  @HiveField(3)
  final double openingBalance; // Fondo inicial / Base

  @HiveField(4)
  double? closingBalance; // Lo que reporta al final

  @HiveField(5)
  bool isOpen;

  @HiveField(6)
  double salesTotal; // Solo ventas (sin fondo inicial)

  @HiveField(7)
  double expensesTotal; // Suma de salidas de dinero

  Shift({
    required this.userId,
    required this.startTime,
    required this.openingBalance,
    this.endTime,
    this.closingBalance,
    this.isOpen = true,
    this.salesTotal = 0,
    this.expensesTotal = 0,
  });
}
