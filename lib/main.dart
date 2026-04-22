import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/models/product.dart';
import 'data/models/sale.dart';
import 'data/models/business_config.dart';
import 'data/models/expense.dart';
import 'data/models/supplier.dart';
import 'data/models/cash_closing.dart';
import 'data/models/shift.dart';
import 'core/routing/app_router.dart';
import 'data/local/demo_data_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  await Hive.initFlutter();

  // Registro completo de adapters
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(SaleAdapter());
  Hive.registerAdapter(SoldProductAdapter());
  Hive.registerAdapter(CostEntryAdapter());
  Hive.registerAdapter(PriceEntryAdapter());
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(BusinessConfigAdapter());
  Hive.registerAdapter(SupplierAdapter());
  Hive.registerAdapter(SupplierPurchaseAdapter());
  Hive.registerAdapter(CashClosingAdapter());
  Hive.registerAdapter(ShiftAdapter());

  // Abrir cajas
  await Hive.openBox<Product>(AppConstants.productsBox);
  await Hive.openBox<Sale>(AppConstants.salesBox);
  await Hive.openBox<BusinessConfig>(AppConstants.settingsBox);
  await Hive.openBox<Expense>(AppConstants.expensesBox);
  await Hive.openBox<Supplier>(AppConstants.suppliersBox);
  await Hive.openBox<SupplierPurchase>('supplier_purchases');
  await Hive.openBox<CashClosing>(AppConstants.closingBox);
  await Hive.openBox<Shift>('shifts');
  await Hive.openBox<double>(AppConstants.mainCashBox); // Abrir la caja de saldo principal

  // Forzado de reseteo para asegurar la integridad de la demo con nuevas imágenes y simulaciones
  await DemoDataSeeder.resetAndSeed();

  runApp(
    const ProviderScope(
      child: CajaFacilApp(),
    ),
  );
}

class CajaFacilApp extends ConsumerWidget {
  const CajaFacilApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'CajaFácil',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
