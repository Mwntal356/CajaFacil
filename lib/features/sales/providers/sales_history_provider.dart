import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/models/sale.dart';
import '../../../data/models/product.dart';
import '../../../data/providers/hive_providers.dart';

class SalesNotifier extends StateNotifier<List<Sale>> {
  final Box<Sale> _box;
  final Box<Product> _productBox;

  SalesNotifier(this._box, this._productBox) : super(_box.values.toList()) {
    _box.listenable().addListener(() {
      state = _box.values.toList();
    });
  }

  // MÉTODO PARA CANCELAR VENTA AUDITADA
  Future<void> cancelSale(Sale sale, String authorizedBy) async {
    if (sale.cancelled) return;

    // 1. Revertir inventario
    for (var soldProduct in sale.products) {
      final product = _productBox.values.firstWhere(
        (p) => p.nombre == soldProduct.productName,
        orElse: () => Product(nombre: '', aliases: [], categoria: '', unidadMedida: '', existencias: 0, precioCosto: 0, precioVenta: 0),
      );
      
      if (product.nombre.isNotEmpty) {
        product.existencias += soldProduct.quantity;
        await product.save();
      }
    }

    // 2. Marcar como cancelada
    sale.isCancelled = true;
    sale.cancelledBy = authorizedBy;
    await sale.save();
    
    // El estado se actualiza por el listener de Hive
  }

  // Método para obtener ventas de hoy
  List<Sale> get todaySales {
    final now = DateTime.now();
    return state.where((s) => 
      s.date.year == now.year && s.date.month == now.month && s.date.day == now.day && !s.cancelled
    ).toList();
  }

  double get todayTotalRevenue => todaySales.fold(0, (sum, s) => sum + s.total);
  double get todayTotalUtility => todaySales.fold(0, (sum, s) => sum + s.totalUtility);
}

final salesProvider = StateNotifierProvider<SalesNotifier, List<Sale>>((ref) {
  final box = ref.watch(salesBoxProvider);
  final pBox = ref.watch(productsBoxProvider);
  return SalesNotifier(box, pBox);
});
