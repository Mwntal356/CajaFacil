import 'package:hive/hive.dart';

part 'sale.g.dart';

@HiveType(typeId: 1)
class Sale extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  List<SoldProduct> products;

  @HiveField(2)
  double total;

  @HiveField(3)
  String paymentMethod; // e.g., 'Efectivo', 'Mercado Pago'

  @HiveField(4)
  double totalUtility;

  @HiveField(5)
  bool? isCancelled; // Opcional para migración

  @HiveField(6)
  String? cancelledBy;

  @HiveField(7)
  int? shiftKey; // ID del turno al que pertenece esta venta

  Sale({
    required this.date,
    required this.products,
    required this.total,
    required this.paymentMethod,
    required this.totalUtility,
    this.isCancelled = false,
    this.cancelledBy,
    this.shiftKey,
  });

  bool get cancelled => isCancelled ?? false;
}

@HiveType(typeId: 2)
class SoldProduct {
  @HiveField(0)
  String productName;

  @HiveField(1)
  double quantity;

  @HiveField(2)
  double priceAtSale;

  @HiveField(3)
  double utilityAtSale;

  SoldProduct({
    required this.productName,
    required this.quantity,
    required this.priceAtSale,
    required this.utilityAtSale,
  });
}
