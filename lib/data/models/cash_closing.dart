import 'package:hive/hive.dart';

part 'cash_closing.g.dart';

@HiveType(typeId: 9)
class CashClosing extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final double openingBalance; // Saldo inicial (base)

  @HiveField(2)
  final double salesEfectivo;

  @HiveField(3)
  final double salesTarjeta;

  @HiveField(4)
  final double expenses;

  @HiveField(5)
  final double expectedCash; // openingBalance + salesEfectivo - expenses

  @HiveField(6)
  final double actualCash; // Lo que el usuario contó físically

  @HiveField(7)
  final String? notes;

  CashClosing({
    required this.date,
    required this.openingBalance,
    required this.salesEfectivo,
    required this.salesTarjeta,
    required this.expenses,
    required this.expectedCash,
    required this.actualCash,
    this.notes,
  });

  double get difference => actualCash - expectedCash;
}
