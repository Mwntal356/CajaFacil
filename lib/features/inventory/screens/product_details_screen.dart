import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/product_image_widget.dart';
import '../../../data/models/product.dart';
import '../../auth/providers/auth_provider.dart';
import '../../sales/providers/sales_history_provider.dart';

class ProductDetailsScreen extends ConsumerWidget {
  final Product product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
    final auth = ref.watch(authProvider);
    final isDueno = auth.role == UserRole.dueno;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ficha Técnica'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cabecera con Foto y Stock
            _buildHeader(product),
            const SizedBox(height: 24),

            // 2. KPIs de Rendimiento Histórico (WOW para el dueño)
            _buildLifetimeStats(ref, product, fmt),
            const SizedBox(height: 24),

            // 3. Bloque Financiero Actual
            _buildFinancialBlock(isDueno, product, fmt),
            const SizedBox(height: 32),

            // 4. Historial Detallado de Movimientos
            if (isDueno) ...[
               const Text('HISTORIAL DE SURTIDOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1.1)),
               const SizedBox(height: 12),
               _buildRestockHistory(product, fmt),
               const SizedBox(height: 32),
               const Text('CAMBIOS DE PRECIO AL PÚBLICO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1.1)),
               const SizedBox(height: 12),
               _buildPriceHistory(product, fmt),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Product product) {
    return Row(
      children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
          child: ProductImageWidget(product.fotoPath, size: 90),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(product.categoria, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text('${product.existencias} ${product.unidadMedida} en stock', style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLifetimeStats(WidgetRef ref, Product product, NumberFormat fmt) {
    // Calculamos estadísticas basadas en todas las ventas reales
    final allSales = ref.watch(salesProvider);
    double totalUnits = 0;
    double totalRevenue = 0;
    double totalUtility = 0;

    for (var sale in allSales) {
      if (sale.cancelled) continue;
      for (var item in sale.products) {
        if (item.productName == product.nombre) {
          totalUnits += item.quantity;
          totalRevenue += (item.priceAtSale * item.quantity);
          totalUtility += (item.utilityAtSale * item.quantity);
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.blue.withOpacity(0.2))),
      child: Column(
        children: [
          const Text('RENDIMIENTO DE VIDA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.blue, letterSpacing: 1.2)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('VENDIDAS', totalUnits.toStringAsFixed(0), LucideIcons.shoppingCart, Colors.white),
              _buildStatItem('RECAUDADO', fmt.format(totalRevenue), LucideIcons.banknote, AppColors.green),
              _buildStatItem('GANANCIA', fmt.format(totalUtility), LucideIcons.coins, AppColors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color.withOpacity(0.5)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 8, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFinancialBlock(bool isDueno, Product p, NumberFormat fmt) {
    if (!isDueno) return _buildMiniCard('PRECIO AL PÚBLICO', fmt.format(p.precioVenta), LucideIcons.tag, AppColors.green);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          _buildKpiRow('Costo Promedio', fmt.format(p.precioCosto), LucideIcons.trendingDown, AppColors.orange),
          const Divider(height: 32, color: Colors.white10),
          _buildKpiRow('Precio Venta', fmt.format(p.precioVenta), LucideIcons.tag, AppColors.green),
          const Divider(height: 32, color: Colors.white10),
          _buildKpiRow('Utilidad x Unidad', fmt.format(p.precioVenta - p.precioCosto), LucideIcons.plusCircle, AppColors.blue),
        ],
      ),
    );
  }

  Widget _buildRestockHistory(Product p, NumberFormat fmt) {
    if (p.costHistory.isEmpty) return const Text('Sin registros de carga', style: TextStyle(color: Colors.white24, fontSize: 12));
    return Column(
      children: p.costHistory.reversed.map((e) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const Icon(LucideIcons.plusCircle, color: AppColors.green, size: 14),
            const SizedBox(width: 12),
            Text(DateFormat('dd/MM/yy').format(e.date), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('+${e.quantity} pzas', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Text('a ${fmt.format(e.cost)}', style: const TextStyle(fontSize: 12, color: AppColors.orange)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildPriceHistory(Product p, NumberFormat fmt) {
    if (p.priceHistory.isEmpty) return const Text('Sin cambios de precio', style: TextStyle(color: Colors.white24, fontSize: 12));
    return Column(
      children: p.priceHistory.reversed.map((e) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const Icon(LucideIcons.tag, color: AppColors.blue, size: 14),
            const SizedBox(width: 12),
            Text(DateFormat('dd/MM/yy').format(e.date), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('Precio: ${fmt.format(e.price)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.green)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildKpiRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  Widget _buildMiniCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
