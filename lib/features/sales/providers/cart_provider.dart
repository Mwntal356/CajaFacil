import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../data/models/product.dart';
import '../../../data/models/sale.dart';
import '../../../data/models/shift.dart';
import '../../../data/providers/hive_providers.dart';
import '../../inventory/providers/product_provider.dart';
import '../../auth/providers/shift_provider.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.precioVenta * quantity;
  double get totalUtility => (product.precioVenta - product.precioCosto) * quantity;
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  final Ref ref;
  CartNotifier(this.ref) : super([]);

  void addProduct(Product product) {
    final index = state.indexWhere((item) => item.product.nombre == product.nombre);
    if (index != -1) {
      state[index].quantity++;
      state = [...state];
    } else {
      state = [...state, CartItem(product: product)];
    }
  }

  void removeProduct(Product product) {
    state = state.where((item) => item.product.nombre != product.nombre).toList();
  }

  void updateQuantity(Product product, int qty) {
    if (qty <= 0) {
      removeProduct(product);
    } else {
      final index = state.indexWhere((item) => item.product.nombre == product.nombre);
      if (index != -1) {
        state[index].quantity = qty;
        state = [...state];
      }
    }
  }

  void clear() => state = [];

  double get totalRevenue => state.fold(0.0, (sum, item) => sum + item.total);
  double get totalUtility => state.fold(0.0, (sum, item) => sum + item.totalUtility);

  Future<Sale> checkout(String paymentMethod, Box<Sale> salesBox, List<Product> allProducts, Shift? activeShift) async {
    final List<SoldProduct> soldProducts = state.map((item) => SoldProduct(
      productName: item.product.nombre,
      quantity: item.quantity.toDouble(),
      priceAtSale: item.product.precioVenta,
      utilityAtSale: item.product.precioVenta - item.product.precioCosto,
    )).toList();

    final sale = Sale(
      date: DateTime.now(),
      products: soldProducts,
      total: totalRevenue,
      paymentMethod: paymentMethod,
      totalUtility: totalUtility,
      isCancelled: false, 
      cancelledBy: null,
      shiftKey: activeShift?.key as int?,
    );

    // 1. Guardar venta
    final int saleKey = await salesBox.add(sale);
    final savedSale = salesBox.get(saleKey) ?? sale;

    // 2. Actualizar stock físicamente y notificar
    for (var item in state) {
      final product = item.product;
      if (product.isInBox) {
        product.existencias = product.existencias - item.quantity;
        await product.save();
      }
    }

    // Refrescar el inventario para que el dueño vea el cambio real
    ref.read(productSourceProvider.notifier).refresh();

    return savedSale;
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier(ref);
});
