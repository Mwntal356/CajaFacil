import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../models/sale.dart';
import '../models/shift.dart';
import '../models/expense.dart';

class DemoDataSeeder {
  static Future<void> resetAndSeed() async {
    await Hive.box<Product>('products').clear();
    await Hive.box<Sale>('sales').clear();
    await Hive.box<Shift>('shifts').clear();
    await Hive.box<Supplier>('suppliers').clear();
    await Hive.box<Expense>('expenses').clear();
    await Hive.box<SupplierPurchase>('supplier_purchases').clear();

    final productBox = Hive.box<Product>('products');
    final supplierBox = Hive.box<Supplier>('suppliers');
    final salesBox = Hive.box<Sale>('sales');
    final shiftBox = Hive.box<Shift>('shifts');

    final List<Product> catalog = [
      _p('Leche Alpura Entera 1L', '750100000001', 28, 22, 10, 10, 'pza', 'Abarrotes', null),
      _p('Coca Cola 600ml', '7501031302753', 18, 13, 48, 24, 'pza', 'Bebidas', null),
      _p('Maseca Maíz 1kg', '750100011121', 24, 18.5, 20, 10, 'pza', 'Abarrotes', null),
      _p('Aceite Nutrioli 946ml', '750100000002', 45, 34, 15, 8, 'pza', 'Abarrotes', null),
      _p('Arroz Verde Valle 1kg', '750100000003', 35, 26, 30, 15, 'pza', 'Abarrotes', null),
      _p('Frijol Negro 1kg', '750100000004', 42, 32, 25, 10, 'pza', 'Abarrotes', null),
      _p('Atún Herdez Agua 130g', '750100000005', 23, 16.5, 40, 20, 'pza', 'Enlatados', null),
      _p('Sopa La Moderna Fideo', '750100000006', 12, 8.5, 50, 30, 'pza', 'Abarrotes', null),
      _p('Jabón Zote Blanco 400g', '750100000007', 25, 17, 12, 10, 'pza', 'Limpieza', null),
      _p('Detergente Ariel 1kg', '750100000008', 44, 32, 15, 10, 'pza', 'Limpieza', null),
      _p('Regio 4 Rollos', '750100000009', 36, 24, 18, 12, 'pza', 'Limpieza', null),
      _p('Pan Blanco Bimbo Gde', '750100011120', 52, 39.5, 3, 10, 'pza', 'Panadería', null),
      _p('Sabritas Sal 42g', '750100000010', 18, 11.5, 35, 20, 'pza', 'Botanas', null),
      _p('Marias Gamesa 140g', '750100000011', 21, 14, 25, 15, 'pza', 'Galletas', null),
      _p('Mayonesa McCormick 390g', '750100000012', 58, 42, 12, 8, 'pza', 'Abarrotes', null),
      _p('Chocolate Abuelita 540g', '750100000013', 98, 75, 10, 5, 'pza', 'Abarrotes', null),
      _p('Cloro Los Girasoles 1L', '750100000014', 16, 10, 20, 10, 'pza', 'Limpieza', null),
      _p('Huevo Blanco (Kg)', '001', 48, 36, 12, 20, 'kg', 'Abarrotes', null),
      _p('Tomate Saladet (Kg)', '002', 24, 14, 15, 10, 'kg', 'Frutería', null),
      _p('Queso Sopero Tabasco (Kg)', '003', 160, 115, 5, 10, 'kg', 'Lácteos', null),
    ];
    
    for (var p in catalog) {
      await productBox.add(p);
    }

    final supplier1 = Supplier(name: 'Distribuidora Bimbo', contactName: 'Raúl Torres', phone: '993-123-4567');
    supplier1.purchases.add(SupplierPurchase(
      date: DateTime.now().subtract(const Duration(days: 1)),
      amount: 1250.50,
      description: 'Compra de pan y galletas',
      ticketPhotos: [],
    ));
    await supplierBox.add(supplier1);

    final now = DateTime.now();
    final cajeros = ['Juan', 'Maritza'];

    for (int i = 30; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final cajero = cajeros[i % 2];
      final bool isToday = (i == 0);
      
      final shift = Shift(
        userId: cajero,
        startTime: DateTime(date.year, date.month, date.day, 8, 0),
        endTime: isToday ? null : DateTime(date.year, date.month, date.day, 20, 0),
        openingBalance: 500,
        isOpen: isToday,
        closingBalance: isToday ? null : 2000.0,
        salesTotal: 1500.0,
      );
      
      final key = await shiftBox.add(shift);
      await _simSales(salesBox, date, 8, 20, key, catalog);
    }
  }

  static Product _p(String n, String b, double pv, double pc, double e, double sm, String u, String c, String? img) {
    return Product(
      nombre: n, barcode: b, precioVenta: pv, precioCosto: pc, 
      existencias: e, stockMinimo: sm, unidadMedida: u, categoria: c,
      fotoPath: img,
      aliases: [n.split(' ').first]
    );
  }

  static Future<void> _simSales(Box<Sale> box, DateTime date, int startH, int endH, int sKey, List<Product> catalog) async {
    final random = DateTime.now().microsecondsSinceEpoch;
    for (int h = startH; h <= endH; h++) {
      for (int j = 0; j < 4; j++) {
        final p = catalog[(random + h + j) % catalog.length];
        final double price = p.precioVenta;
        final double qty = 1 + (random % 2);
        
        await box.add(Sale(
          date: DateTime(date.year, date.month, date.day, h, j * 15),
          products: [
            SoldProduct(
              productName: p.nombre, 
              quantity: qty, 
              priceAtSale: price, 
              utilityAtSale: (price - p.precioCosto)
            ),
          ],
          total: price * qty,
          paymentMethod: (random % 5 == 0) ? 'Tarjeta' : 'Efectivo',
          totalUtility: (price - p.precioCosto) * qty,
          shiftKey: sKey,
        ));
      }
    }
  }

  static Future<void> seedIfEmpty() async {
    if (Hive.box<Product>('products').isEmpty) await resetAndSeed();
  }
}
