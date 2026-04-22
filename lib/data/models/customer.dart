import 'package:hive/hive.dart';

part 'customer.g.dart';

@HiveType(typeId: 9)
class Customer extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String? phone;

  @HiveField(2)
  double debt;

  @HiveField(3)
  List<DebtEntry> debtHistory;

  Customer({
    required this.name,
    this.phone,
    this.debt = 0.0,
    List<DebtEntry>? debtHistory,
  }) : this.debtHistory = debtHistory ?? [];

  void addDebt(double amount, String concept) {
    debt += amount;
    debtHistory.add(DebtEntry(
      date: DateTime.now(),
      amount: amount,
      concept: concept,
      isPayment: false,
    ));
  }

  void recordPayment(double amount) {
    debt -= amount;
    debtHistory.add(DebtEntry(
      date: DateTime.now(),
      amount: amount,
      concept: 'Abono a cuenta',
      isPayment: true,
    ));
  }
}

@HiveType(typeId: 10)
class DebtEntry {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String concept;

  @HiveField(3)
  bool isPayment;

  DebtEntry({
    required this.date,
    required this.amount,
    required this.concept,
    required this.isPayment,
  });
}
