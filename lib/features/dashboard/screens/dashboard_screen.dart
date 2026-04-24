import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../inventory/providers/product_provider.dart';
import '../../auth/providers/shift_provider.dart';
import '../../sales/providers/sales_history_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../core/widgets/product_image_widget.dart';
import '../widgets/sales_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final products = ref.watch(productProvider);
    final recentSales = ref.watch(salesProvider).reversed.take(5).toList();
    final currencyFormat = NumberFormat.currency(symbol: r'$', decimalDigits: 0);
    
    // Filtrar productos con stock bajo (ej. <= 5)
    final lowStockProducts = products.where((p) => p.existencias <= 5).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Estratégico
              _buildHeader(context, ref),
              const SizedBox(height: 24),

              // Selector de Tiempo (Gamificado)
              _buildTimeSelector(ref),
              const SizedBox(height: 16),
              
              // 2. Bloque de Salud Financiera (KPIs)
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: _buildFinancialHealthBlock(stats, currencyFormat),
              ),
              const SizedBox(height: 24),

              // 3. Bloque de Alertas Críticas (Solo si hay stock bajo)
              if (lowStockProducts.isNotEmpty)
                _buildAlertsBlock(context, lowStockProducts),
              
              const SizedBox(height: 24),

              // 4. Bloque de Patrimonio e Inventario
              _buildInventoryEquityBlock(ref, currencyFormat),
              
              const SizedBox(height: 24),

              // 5. Bloque de Productos Estrella (Dinamismo visual)
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: _buildTrendsBlock(),
              ),
              const SizedBox(height: 24),

              // 6. Bloque de Tendencia (Gráfica regresa)
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: _buildChartContainer(),
              ),
              const SizedBox(height: 24),

              // 7. Bloque de Ventas Recientes
              if (recentSales.isNotEmpty)
                _buildRecentSalesBlock(context, recentSales, currencyFormat),

              const SizedBox(height: 100), // Espacio para no chocar con el nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final userName = auth.userName ?? 'Usuario';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panel de Control',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              '¡Hola, $userName!',
              style: const TextStyle(
                color: AppColors.textPrimary, 
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(LucideIcons.logOut, color: Colors.redAccent),
          onPressed: () => ref.read(authProvider.notifier).logout(),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final auth = ref.watch(authProvider);

    // Los cajeros solo ven el día de hoy, no cambian rangos
    if (auth.role != UserRole.dueno) return const SizedBox.shrink();

    return Row(
      children: [
        _buildTimePill(ref, 'HOY', DashboardTimeRange.hoy, stats.timeRange == DashboardTimeRange.hoy),
        const SizedBox(width: 8),
        _buildTimePill(ref, 'SEMANA', DashboardTimeRange.semana, stats.timeRange == DashboardTimeRange.semana),
        const SizedBox(width: 8),
        _buildTimePill(ref, 'MES', DashboardTimeRange.mes, stats.timeRange == DashboardTimeRange.mes),
      ],
    );
  }

  Widget _buildTimePill(WidgetRef ref, String label, DashboardTimeRange range, bool isSelected) {
    return GestureDetector(
      onTap: () => ref.read(dashboardStatsProvider.notifier).updateRange(range),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.blue : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialHealthBlock(DashboardStats stats, NumberFormat format) {
    return Consumer(builder: (context, ref, child) {
      final auth = ref.watch(authProvider);
      final isDueno = auth.role == UserRole.dueno;

      final rangeText = stats.timeRange == DashboardTimeRange.hoy ? 'HOY' : 
                       stats.timeRange == DashboardTimeRange.semana ? 'ESTA SEMANA' : 'ESTE MES';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDueno ? [AppColors.blue, Color(0xFF1E88E5)] : [AppColors.green, Color(0xFF388E3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: (isDueno ? AppColors.blue : AppColors.green).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isDueno ? 'VENTA TOTAL $rangeText' : 'MIS VENTAS DE HOY',
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2),
                ),
                const Icon(LucideIcons.trendingUp, color: Colors.white70, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              format.format(stats.revenue),
              style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // SOLO EL DUEÑO VE LA UTILIDAD NETA
            if (isDueno)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GANANCIA REAL', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text(format.format(stats.utility), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: stats.changePercentage >= 0 ? AppColors.green : Colors.redAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${stats.changePercentage >= 0 ? '+' : ''}${stats.changePercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildAlertsBlock(BuildContext context, List products) {
    final showCount = products.length > 4 ? 3 : products.length;
    final hasMore = products.length > 4;

    return FadeInRight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: AppColors.orange, size: 20),
              SizedBox(width: 8),
              Text('ALERTAS DEL NEGOCIO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: showCount + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == showCount && hasMore) {
                  return _buildMoreAlertsCard(context, products.length - showCount);
                }
                
                final p = products[index];
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('Quedan: ${p.existencias} ${p.unidadMedida}', style: const TextStyle(color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreAlertsCard(BuildContext context, int remaining) {
    return InkWell(
      onTap: () => context.go('/inventory'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.orange.withOpacity(0.5), style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.plus, color: AppColors.orange),
            Text('$remaining más', style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryEquityBlock(WidgetRef ref, NumberFormat format) {
    final invStats = ref.watch(inventoryStatsProvider);
    final auth = ref.watch(authProvider);

    // Los cajeros no deben ver el capital invertido ni la utilidad en stock
    if (auth.role != UserRole.dueno) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'CAPITAL INVERTIDO', 
            format.format(invStats['inversion']), 
            LucideIcons.database, 
            AppColors.blue
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'UTILIDAD EN STOCK', 
            format.format(invStats['utilidad_esperada']), 
            LucideIcons.layers, 
            AppColors.green
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsBlock() {
    return Consumer(builder: (context, ref, child) {
      final products = ref.watch(productProvider);
      // Simulación de productos estrella basados en stock bajo (señal de que se venden más)
      final topProducts = products.where((p) => p.existencias < 10).take(3).toList();

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('PRODUCTOS ESTRELLA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.1)),
                Icon(LucideIcons.award, size: 18, color: Colors.orangeAccent),
              ],
            ),
            const SizedBox(height: 24),
            if (topProducts.isEmpty)
              const Center(child: Text('Sin datos de ventas aún', style: TextStyle(color: Colors.white24, fontSize: 12)))
            else
              ...topProducts.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40, 
                      decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: ProductImageWidget(p.fotoPath, size: 40)
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('${p.categoria}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                        ],
                      ),
                    ),
                    const Text('MÁS VENDIDO', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 9)),
                  ],
                ),
              )),
          ],
        ),
      );
    });
  }

  Widget _buildRecentSalesBlock(BuildContext context, List sales, NumberFormat format) {
    return Consumer(builder: (context, ref, child) {
      final shifts = ref.watch(shiftBoxProvider).values.toList();
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('VENTAS RECIENTES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
              TextButton(
                onPressed: () => context.push('/admin/history'),
                child: const Text('Ver todo', style: TextStyle(color: AppColors.blue, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sales.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final sale = sales[index];
              final time = DateFormat('HH:mm').format(sale.date);
              
              // Buscar quién hizo la venta a través del turno
              String seller = 'Sistema';
              try {
                final shift = shifts.firstWhere((s) => s.key == sale.shiftKey);
                seller = shift.userId;
              } catch (_) {}

              return InkWell(
                onTap: () => _showSaleDetail(context, sale, format),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.green.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(LucideIcons.shoppingBag, color: AppColors.green, size: 18),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Venta por ${format.format(sale.total)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('$time • Por $seller', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, color: AppColors.textSecondary, size: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      );
    });
  }

  void _showSaleDetail(BuildContext context, dynamic sale, NumberFormat format) {
    final date = DateFormat('dd/MM/yyyy HH:mm').format(sale.date);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              const Text('DETALLE DE VENTA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text(date, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: sale.products.length,
                  itemBuilder: (context, index) {
                    final p = sale.products[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${p.quantity}x ${p.productName}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text(format.format(p.priceAtSale * p.quantity)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  Text(format.format(sale.total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.green)),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartContainer() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('FLUJO DE VENTAS (ÚLTIMOS 7 DÍAS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1)),
              Icon(LucideIcons.activity, size: 18, color: AppColors.blue),
            ],
          ),
          SizedBox(height: 24),
          SalesChart(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, {bool badge = false}) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
        if (badge)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
