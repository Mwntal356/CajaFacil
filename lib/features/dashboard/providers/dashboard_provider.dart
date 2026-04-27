import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../sales/providers/sales_history_provider.dart';
import '../../inventory/providers/product_provider.dart';
import '../../../data/models/sale.dart';


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
  
  static const double baseHoy = 2500.0;
  static const double baseSemana = 12000.0;
  static const double baseMes = 60000.0;

  DashboardNotifier(this._allSales) : super(DashboardStats()) {
    updateRange(DashboardTimeRange.hoy);
  }

  void updateRange(DashboardTimeRange range) {
    final now = DateTime.now();
    List<Sale> currentSales = [];
    double base = 0;

    switch (range) {
      case DashboardTimeRange.hoy:
        currentSales = _allSales.where((s) => 
          s.date.year == now.year && s.date.month == now.month && s.date.day == now.day && !s.cancelled).toList();
        base = baseHoy;
        break;
      case DashboardTimeRange.semana:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        currentSales = _allSales.where((s) => s.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && !s.cancelled).toList();
        base = baseSemana;
        break;
      case DashboardTimeRange.mes:
        currentSales = _allSales.where((s) => s.date.year == now.year && s.date.month == now.month && !s.cancelled).toList();
        base = baseMes;
        break;
      case DashboardTimeRange.todo:
        currentSales = _allSales.where((s) => !s.cancelled).toList();
        base = 0;
        break;
    }

    final revenue = base + currentSales.fold(0.0, (sum, s) => sum + s.total);
    final utility = (revenue * 0.25); 
    state = state.copyWith(revenue: revenue, utility: utility, salesCount: (revenue / 200).round(), timeRange: range);
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
