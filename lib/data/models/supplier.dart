import 'package:hive/hive.dart';

part 'supplier.g.dart';

@HiveType(typeId: 7)
class Supplier extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String? contactName;

  @HiveField(2)
  String? phone;

  @HiveField(3)
  String? note;

  @HiveField(4)
  List<SupplierPurchase> purchases;

  Supplier({
    required this.name,
    this.contactName,
    this.phone,
    this.note,
    List<SupplierPurchase>? purchases,
  }) : this.purchases = purchases ?? [];
}

@HiveType(typeId: 8)
class SupplierPurchase extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  double amount;

  @HiveField(2)
  List<String> ticketPhotos; // Rutas de las imágenes de las notas

  @HiveField(3)
  String? description;

  SupplierPurchase({
    required this.date,
    required this.amount,
    required this.ticketPhotos,
    this.description,
  });
}
