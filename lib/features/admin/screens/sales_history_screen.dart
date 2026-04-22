import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../sales/providers/sales_history_provider.dart';
import '../../auth/providers/shift_provider.dart';
import '../../../data/models/sale.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  DateTime? selectedMonth;
  DateTime? selectedDay;

  @override
  Widget build(BuildContext context) {
    final allSales = ref.watch(salesProvider);
    final currencyFormat = NumberFormat.currency(symbol: r'$', decimalDigits: 0);

    if (selectedDay != null) {
      return _buildDayView(allSales, currencyFormat);
    }

    if (selectedMonth != null) {
      return _buildMonthView(allSales, currencyFormat);
    }

    return _buildYearlyOverview(allSales, currencyFormat);
  }

  // NIVEL 1: Vista Anual / Agrupado por Meses
  Widget _buildYearlyOverview(List<Sale> sales, NumberFormat format) {
    final monthsMap = <String, List<Sale>>{};
    for (var s in sales) {
      final key = DateFormat('MMMM yyyy', 'es').format(s.date);
      monthsMap.putIfAbsent(key, () => []).add(s);
    }

    final sortedKeys = monthsMap.keys.toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Historial por Meses')),
      body: sales.isEmpty
          ? const Center(child: Text('Sin registros'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                final key = sortedKeys[index];
                final monthSales = monthsMap[key]!;
                final total = monthSales.fold(0.0, (sum, s) => sum + s.total);
                final util = monthSales.fold(0.0, (sum, s) => sum + s.totalUtility);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(20),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(LucideIcons.calendar, color: AppColors.blue),
                    ),
                    title: Text(key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text('${monthSales.length} ventas realizadas'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(format.format(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.green)),
                        Text('Utilidad: ${format.format(util)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    onTap: () => setState(() => selectedMonth = monthSales.first.date),
                  ),
                );
              },
            ),
    );
  }

  // NIVEL 2: Vista del Mes / Agrupado por Días
  Widget _buildMonthView(List<Sale> sales, NumberFormat format) {
    final monthName = DateFormat('MMMM yyyy', 'es').format(selectedMonth!);
    final monthSales = sales.where((s) => s.date.year == selectedMonth!.year && s.date.month == selectedMonth!.month).toList();
    
    final daysMap = <int, List<Sale>>{};
    for (var s in monthSales) {
      daysMap.putIfAbsent(s.date.day, () => []).add(s);
    }

    final sortedDays = daysMap.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: Text(monthName.toUpperCase()),
        leading: IconButton(icon: const Icon(LucideIcons.chevronLeft), onPressed: () => setState(() => selectedMonth = null)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedDays.length,
        itemBuilder: (context, index) {
          final day = sortedDays[index];
          final daySales = daysMap[day]!;
          final total = daySales.fold(0.0, (sum, s) => sum + s.total);
          final dateStr = DateFormat('EEEE dd', 'es').format(daySales.first.date);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${daySales.length} ventas'),
              trailing: Text(format.format(total), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.blue)),
              onTap: () => setState(() => selectedDay = daySales.first.date),
            ),
          );
        },
      ),
    );
  }

  // NIVEL 3: Vista del Día / Lista de Ventas
  Widget _buildDayView(List<Sale> sales, NumberFormat format) {
    final dayName = DateFormat('EEEE dd MMMM', 'es').format(selectedDay!);
    final daySales = sales.where((s) => 
      s.date.year == selectedDay!.year && 
      s.date.month == selectedDay!.month && 
      s.date.day == selectedDay!.day).toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(dayName),
        leading: IconButton(icon: const Icon(LucideIcons.chevronLeft), onPressed: () => setState(() => selectedDay = null)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: daySales.length,
        itemBuilder: (context, index) {
          final sale = daySales[index];
          final time = DateFormat('HH:mm').format(sale.date);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: sale.cancelled ? const BorderSide(color: Colors.redAccent, width: 2) : BorderSide.none,
            ),
            child: ListTile(
              leading: Icon(LucideIcons.shoppingBag, color: sale.cancelled ? Colors.redAccent : AppColors.green),
              title: Row(
                children: [
                  Text('Venta #${daySales.length - index}'),
                  if (sale.cancelled) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)),
                      child: const Text('CANCELADA', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              subtitle: Text(time),
              trailing: Text(format.format(sale.total), style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: sale.cancelled ? TextDecoration.lineThrough : null,
                color: sale.cancelled ? Colors.grey : null,
              )),
              onTap: () => _showSaleDetail(context, sale, format),
            ),
          );
        },
      ),
    );
  }

  void _showSaleDetail(BuildContext context, Sale sale, NumberFormat format) {
    final shiftBox = ref.read(shiftBoxProvider);
    final shift = shiftBox.get(sale.shiftKey);
    final sellerName = shift?.userId ?? 'Sistema';
    final date = DateFormat('dd/MM/yyyy HH:mm').format(sale.date);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DETALLE DE VENTA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Text(date, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 4),
            Text('ATENDIDO POR: $sellerName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.blue)),
            if (sale.cancelled) ...[
               const SizedBox(height: 12),
               Text('CANCELADA POR: ${sale.cancelledBy}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
            const Divider(height: 40),
            ...sale.products.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${p.quantity.toInt()}x ${p.productName}', style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(format.format(p.priceAtSale * p.quantity)),
                ],
              ),
            )),
            const Divider(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                Text(format.format(sale.total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.green)),
              ],
            ),
            const SizedBox(height: 32),
            
            if (!sale.cancelled)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.1),
                  foregroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Colors.redAccent),
                ),
                onPressed: () => _confirmCancellation(context, sale),
                icon: const Icon(LucideIcons.trash2),
                label: const Text('CANCELAR VENTA (PIN DUEÑO)'),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmCancellation(BuildContext context, Sale sale) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Autorizar Cancelación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Se requiere el PIN del dueño para cancelar esta venta y devolver productos al inventario.', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'PIN del Dueño'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('VOLVER')),
          ElevatedButton(
            onPressed: () {
              if (pinController.text == '0000') {
                ref.read(salesProvider.notifier).cancelSale(sale, 'Dueño');
                Navigator.pop(context); // Cerrar dialogo
                Navigator.pop(context); // Cerrar modal detalle
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venta cancelada exitosamente')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN Incorrecto')));
              }
            },
            child: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );
  }

}
