import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 5)
class CostEntry extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final double quantity;

  @HiveField(2)
  final double cost;

  CostEntry({
    required this.date,
    required this.quantity,
    required this.cost,
  });
}

@HiveType(typeId: 6)
class PriceEntry extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final double price;

  PriceEntry({
    required this.date,
    required this.price,
  });
}

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  String nombre;

  @HiveField(1)
  List<String> aliases;

  @HiveField(2)
  String categoria;

  @HiveField(3)
  String unidadMedida; // pieza, kg, litro, caja, etc.

  @HiveField(4)
  double existencias;

  @HiveField(5)
  double precioCosto;

  @HiveField(6)
  double precioVenta;

  @HiveField(7)
  String? fotoPath;

  @HiveField(8)
  List<CostEntry> costHistory;

  @HiveField(9)
  List<PriceEntry> priceHistory;

  @HiveField(10)
  String? barcode;

  @HiveField(11)
  double stockMinimo;

  Product({
    required this.nombre,
    required this.aliases,
    required this.categoria,
    required this.unidadMedida,
    required this.existencias,
    required this.precioCosto,
    required this.precioVenta,
    this.fotoPath,
    this.barcode,
    this.stockMinimo = 5.0,
    List<CostEntry>? costHistory,
    List<PriceEntry>? priceHistory,
  }) : this.costHistory = costHistory ?? [
    CostEntry(date: DateTime.now(), quantity: existencias, cost: precioCosto)
  ], this.priceHistory = priceHistory ?? [
    PriceEntry(date: DateTime.now(), price: precioVenta)
  ];

  // Cálculo de utilidad porcentual (Solicitado exacto)
  double get utilidadPorcentaje {
    if (precioCosto == 0) return 0;
    return ((precioVenta - precioCosto) / precioCosto) * 100;
  }

  // Valor total del inventario para este producto
  double get valorTotalInventario => existencias * precioCosto;

  // Alerta de stock bajo
  bool get esStockBajo => existencias <= stockMinimo;

  // Recalcular costo promedio ponderado al surtir stock y opcionalmente actualizar precio
  void restock(double newQuantity, double newCost, {double? newSellingPrice}) {
    final currentTotalCost = existencias * precioCosto;
    final addedTotalCost = newQuantity * newCost;
    final totalQty = existencias + newQuantity;
    
    precioCosto = (currentTotalCost + addedTotalCost) / totalQty;
    existencias = totalQty;
    
    costHistory.add(CostEntry(date: DateTime.now(), quantity: newQuantity, cost: newCost));

    if (newSellingPrice != null && newSellingPrice != precioVenta) {
      precioVenta = newSellingPrice;
      priceHistory.add(PriceEntry(date: DateTime.now(), price: newSellingPrice));
    }
  }
}
