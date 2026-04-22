import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../sales/providers/sales_history_provider.dart';
import '../../inventory/providers/product_provider.dart';
import '../../../data/models/sale.dart';
import '../../../data/providers/hive_providers.dart';

enum DashboardTimeRange { hoy, semana, mes, todo }

class DashboardStats {
  final double utility;
  final double revenue;
  final double previousUtility;
  final double changePercentage;
  final int salesCount;
  final DashboardTimeRange timeRange;

  DashboardStats({
    this.utility = 0,
    this.revenue = 0,
    this.previousUtility = 0,
    this.changePercentage = 0,
    this.salesCount = 0,
    this.timeRange = DashboardTimeRange.hoy,
  });

  DashboardStats copyWith({
    double? utility,
    double? revenue,
    double? previousUtility,
    double? changePercentage,
    int? salesCount,
    DashboardTimeRange? timeRange,
  }) {
    return DashboardStats(
      utility: utility ?? this.utility,
      revenue: revenue ?? this.revenue,
      previousUtility: previousUtility ?? this.previousUtility,
      changePercentage: changePercentage ?? this.changePercentage,
      salesCount: salesCount ?? this.salesCount,
      timeRange: timeRange ?? this.timeRange,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardStats> {
  final List<Sale> _allSales;

  DashboardNotifier(this._allSales) : super(DashboardStats()) {
    updateRange(DashboardTimeRange.hoy);
  }

  void updateRange(DashboardTimeRange range) {
    final now = DateTime.now();
    List<Sale> currentSales = [];
    List<Sale> previousSales = [];

    switch (range) {
      case DashboardTimeRange.hoy:
        currentSales = _allSales.where((s) => 
          s.date.year == now.year && s.date.month == now.month && s.date.day == now.day).toList();
        final yesterday = now.subtract(const Duration(days: 1));
        previousSales = _allSales.where((s) => 
          s.date.year == yesterday.year && s.date.month == yesterday.month && s.date.day == yesterday.day).toList();
        break;
      case DashboardTimeRange.semana:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfToday = DateTime(now.year, now.month, now.day);
        currentSales = _allSales.where((s) => s.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))).toList();
        final startOfPrevWeek = startOfWeek.subtract(const Duration(days: 7));
        previousSales = _allSales.where((s) => s.date.isAfter(startOfPrevWeek.subtract(const Duration(seconds: 1))) && s.date.isBefore(startOfWeek)).toList();
        break;
      case DashboardTimeRange.mes:
        currentSales = _allSales.where((s) => s.date.year == now.year && s.date.month == now.month).toList();
        final startOfPrevMonth = DateTime(now.year, now.month - 1, 1);
        previousSales = _allSales.where((s) => s.date.year == startOfPrevMonth.year && s.date.month == startOfPrevMonth.month).toList();
        break;
      case DashboardTimeRange.todo:
        currentSales = _allSales;
        previousSales = [];
        break;
    }

    double currentUtil = currentSales.fold(0, (sum, s) => sum + s.totalUtility);
    double prevUtil = previousSales.fold(0, (sum, s) => sum + s.totalUtility);
    double revenue = currentSales.fold(0, (sum, s) => sum + s.total);
    
    // Cálculo de MARGEN DE UTILIDAD REAL (Proporción sobre la venta)
    double margin = 0;
    if (revenue > 0) {
      margin = (currentUtil / revenue) * 100;
    }

    state = state.copyWith(
      utility: currentUtil,
      revenue: revenue,
      previousUtility: prevUtil,
      changePercentage: margin, // Ahora es el MARGEN, no el cambio vs periodo previo
      salesCount: currentSales.length,
      timeRange: range,
    );
  }
}

final dashboardStatsProvider = StateNotifierProvider<DashboardNotifier, DashboardStats>((ref) {
  final allSales = ref.watch(salesProvider);
  return DashboardNotifier(allSales);
});

// Valor del inventario en tiempo real
final inventoryStatsProvider = Provider((ref) {
  final products = ref.watch(productSourceProvider);

  final totalInversion = products.fold<double>(0, (sum, p) => sum + (p.existencias * p.precioCosto));
  final totalVentaPotencial = products.fold<double>(0, (sum, p) => sum + (p.existencias * p.precioVenta));

  return {
    'inversion': totalInversion,
    'venta': totalVentaPotencial,
    'utilidad_esperada': totalVentaPotencial - totalInversion,
  };
});
