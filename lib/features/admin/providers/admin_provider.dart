import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/models/sale.dart';
import '../../../data/models/expense.dart';
import '../../../data/providers/hive_providers.dart';
import '../../inventory/providers/product_provider.dart';

class AdminStats {
  final double totalUtility;
  final double totalExpenses;
  final double netProfit;
  final double inventoryValueAtCost;
  final double projectedInventoryUtility;
  final double monthlySales;
  final Map<String, double> salesByDay;
  final List<SoldProduct> topProducts;

  AdminStats({
    this.totalUtility = 0,
    this.totalExpenses = 0,
    this.netProfit = 0,
    this.inventoryValueAtCost = 0,
    this.projectedInventoryUtility = 0,
    this.monthlySales = 0,
    this.salesByDay = const {},
    this.topProducts = const [],
  });
}

final adminStatsProvider = Provider<AdminStats>((ref) {
  final sales = ref.watch(salesBoxProvider).values.toList();
  final expenses = ref.watch(expensesBoxProvider).values.toList();
  final products = ref.watch(productProvider);
  
  final now = DateTime.now();
  final firstDayOfMonth = DateTime(now.year, now.month, 1);

  // 1. Utilidad de ventas
  final totalSalesUtility = sales.fold(0.0, (sum, s) => sum + s.totalUtility);

  // 2. Gastos
  final totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);

  // 3. Valor de inventario (Costo)
  final invValue = products.fold(0.0, (sum, p) => sum + (p.existencias * p.precioCosto));

  // 4. Utilidad proyectada en inventario
  final projUtility = products.fold(0.0, (sum, p) => sum + ((p.precioVenta - p.precioCosto) * p.existencias));

  // 5. Ventas del mes
  final monthlySalesItems = sales.where((s) => s.date.isAfter(firstDayOfMonth)).toList();
  final monthlyTotal = monthlySalesItems.fold(0.0, (sum, s) => sum + s.total);

  return AdminStats(
    totalUtility: totalSalesUtility,
    totalExpenses: totalExpenses,
    netProfit: totalSalesUtility - totalExpenses,
    inventoryValueAtCost: invValue,
    projectedInventoryUtility: projUtility,
    monthlySales: monthlyTotal,
    salesByDay: {}, // Simplificado para demo
    topProducts: [], // Simplificado para demo
  );
});

// NUEVO: Proveedor para el arqueo del día actual
class DayClosingStats {
  final double salesEfectivo;
  final double salesTarjeta;
  final double dailyExpenses;
  final double totalExpected;

  DayClosingStats({
    required this.salesEfectivo,
    required this.salesTarjeta,
    required this.dailyExpenses,
    required this.totalExpected,
  });
}

final currentDayStatsProvider = Provider<DayClosingStats>((ref) {
  final salesBox = ref.watch(salesBoxProvider);
  final expensesBox = ref.watch(expensesBoxProvider);
  
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  
  final todaySales = salesBox.values.where((s) => s.date.isAfter(todayStart)).toList();
  final todayExpenses = expensesBox.values.where((e) => e.date.isAfter(todayStart)).toList();
  
  final efectivo = todaySales
      .where((s) => s.paymentMethod == 'Efectivo')
      .fold(0.0, (sum, s) => sum + s.total);
      
  final tarjeta = todaySales
      .where((s) => s.paymentMethod == 'Tarjeta')
      .fold(0.0, (sum, s) => sum + s.total);
      
  final expenses = todayExpenses.fold(0.0, (sum, e) => sum + e.amount);
  
  return DayClosingStats(
    salesEfectivo: efectivo,
    salesTarjeta: tarjeta,
    dailyExpenses: expenses,
    totalExpected: efectivo - expenses, // Lo que debería haber en efectivo
  );
});

class ExpenseNotifier extends StateNotifier<List<Expense>> {
  final Box<Expense> _box;
  ExpenseNotifier(this._box) : super(_box.values.toList());

  Future<void> addExpense(Expense expense) async {
    await _box.add(expense);
    state = _box.values.toList();
  }

  Future<void> deleteExpense(Expense expense) async {
    await expense.delete();
    state = _box.values.toList();
  }
}

final expenseProvider = StateNotifierProvider<ExpenseNotifier, List<Expense>>((ref) {
  final box = ref.watch(expensesBoxProvider);
  return ExpenseNotifier(box);
});
