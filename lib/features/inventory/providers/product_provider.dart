import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/models/product.dart';
import '../../../data/providers/hive_providers.dart';

// 1. Proveedor base que contiene la fuente de verdad (la caja de Hive)
class ProductSourceNotifier extends StateNotifier<List<Product>> {
  final Box<Product> _box;

  ProductSourceNotifier(this._box) : super(_box.values.toList());

  Future<void> saveProduct(Product product) async {
    if (product.isInBox) {
      await product.save();
    } else {
      await _box.add(product);
    }
    state = _box.values.toList();
  }

  Future<void> deleteProduct(Product product) async {
    await product.delete();
    state = _box.values.toList();
  }

  void refresh() {
    state = _box.values.toList();
  }

  Future<void> loadDemoData() async {
    final demoProducts = [
      Product(nombre: 'Jitomate Saladet', aliases: ['tomate', 'jitomate'], categoria: 'Frutería', unidadMedida: 'kg', existencias: 15.5, precioCosto: 18.0, precioVenta: 28.5),
      Product(nombre: 'Coca Cola 600ml', aliases: ['coca', 'refresco'], categoria: 'Abarrotes', unidadMedida: 'pieza', existencias: 48, precioCosto: 12.5, precioVenta: 18.0),
      Product(nombre: 'Sabritas Sal 45g', aliases: ['papas', 'botana'], categoria: 'Abarrotes', unidadMedida: 'pieza', existencias: 20, precioCosto: 11.0, precioVenta: 17.0),
      Product(nombre: 'Leche Alpura 1L', aliases: ['leche'], categoria: 'Abarrotes', unidadMedida: 'pieza', existencias: 3, precioCosto: 22.0, precioVenta: 27.5),
    ];
    
    for (var p in demoProducts) {
      await _box.add(p);
    }
    state = _box.values.toList();
  }
}

final productSourceProvider = StateNotifierProvider<ProductSourceNotifier, List<Product>>((ref) {
  final box = ref.watch(productsBoxProvider);
  return ProductSourceNotifier(box);
});

// 2. Notificadores de búsqueda independientes
class SearchNotifier extends StateNotifier<List<Product>> {
  final List<Product> _allProducts;
  String _query = '';

  SearchNotifier(this._allProducts) : super(_allProducts);

  void search(String query) {
    _query = query;
    if (_query.isEmpty) {
      state = _allProducts;
    } else {
      final q = _query.toLowerCase();
      state = _allProducts.where((p) {
        return p.nombre.toLowerCase().contains(q) ||
               p.categoria.toLowerCase().contains(q) ||
               p.aliases.any((a) => a.toLowerCase().contains(q));
      }).toList();
    }
  }
}

// 3. Proveedores específicos para cada pantalla
final inventoryProductProvider = StateNotifierProvider<SearchNotifier, List<Product>>((ref) {
  final allProducts = ref.watch(productSourceProvider);
  return SearchNotifier(allProducts);
});

final salesProductProvider = StateNotifierProvider<SearchNotifier, List<Product>>((ref) {
  final allProducts = ref.watch(productSourceProvider);
  return SearchNotifier(allProducts);
});

// Para compatibilidad con código antiguo mientras migramos
final productProvider = inventoryProductProvider;
