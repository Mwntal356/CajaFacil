import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/shift_provider.dart';
import '../../sales/providers/sales_history_provider.dart';
import '../../../data/local/demo_data_seeder.dart';
import '../../inventory/providers/product_provider.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/shift.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);
    final expenses = ref.watch(expenseProvider);
    final fmt = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CONTROL TOTAL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(LucideIcons.logOut, color: Colors.redAccent),
          onPressed: () => _confirmLogout(context, ref),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.rotateCcw, size: 18),
            tooltip: 'Reiniciar Demo (Modo Promotor)',
            onPressed: () => _showResetDemoDialog(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Salud Financiera (KPIs)
            FadeInDown(
              child: _buildFinancialHealthBlock(stats, fmt),
            ),
            const SizedBox(height: 24),

            // 2. Monitor de Operación (Turnos)
            const Row(
              children: [
                Icon(LucideIcons.monitor, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Text('MONITOR DE TURNOS (HOY)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1.1)),
              ],
            ),
            const SizedBox(height: 12),
            _buildShiftMonitor(ref, fmt),
            const SizedBox(height: 24),

            // 3. Accesos Directos Estratégicos
            Row(
              children: [
                Expanded(child: _buildActionCard(context, 'HISTORIAL GLOBAL', LucideIcons.history, AppColors.blue, () => context.push('/admin/history'))),
                const SizedBox(width: 12),
                Expanded(child: _buildActionCard(context, 'REGISTRAR GASTO', LucideIcons.minusCircle, Colors.redAccent, () => _showAddExpenseDialog(context, ref))),
              ],
            ),
            
            const SizedBox(height: 32),

            // 4. Lista de Gastos Recientes
            const Text('GASTOS RECIENTES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1.1)),
            const SizedBox(height: 12),
            if (expenses.isEmpty)
              _buildEmptyExpenses()
            else
              _buildExpensesList(expenses, fmt, ref),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialHealthBlock(dynamic stats, NumberFormat fmt) {
    // Cálculo de porcentaje de utilidad real (Margen)
    final marginPercent = stats.monthlySales > 0 ? (stats.netProfit / stats.monthlySales) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Text('TOTAL VENTAS DEL MES', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(fmt.format(stats.monthlySales), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text('UTILIDAD NETA', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
                   Row(
                     children: [
                       Text(fmt.format(stats.netProfit), style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                       const SizedBox(width: 6),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                         decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                         child: Text('${marginPercent.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                       ),
                     ],
                   ),
                ],
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildKpiMini('GASTOS TOTALES', fmt.format(stats.totalExpenses), Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMini(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildShiftMonitor(WidgetRef ref, NumberFormat fmt) {
    final shiftsBox = ref.watch(shiftBoxProvider);
    final now = DateTime.now();
    final todayShifts = shiftsBox.values.where((s) => 
      s.startTime.year == now.year && s.startTime.month == now.month && s.startTime.day == now.day
    ).toList().reversed.toList();

    if (todayShifts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
        child: const Center(child: Text('Sin actividad de cajas hoy', style: TextStyle(color: Colors.white24, fontSize: 13))),
      );
    }

    return Column(
      children: todayShifts.map((s) => _buildShiftCard(ref, s, fmt)).toList(),
    );
  }

  Widget _buildShiftCard(WidgetRef ref, Shift s, NumberFormat fmt) {
    final allSales = ref.read(salesProvider);
    final shiftSales = allSales.where((sale) => sale.shiftKey == s.key && !sale.cancelled).toList();
    final totalExpected = (s.openingBalance + shiftSales.where((v) => v.paymentMethod == 'Efectivo').fold(0.0, (sum, v) => sum + v.total)) - s.expensesTotal;
    final diff = s.isOpen ? 0.0 : (s.closingBalance ?? 0) - totalExpected;

    return Consumer(builder: (context, ref, child) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: s.isOpen ? AppColors.green.withOpacity(0.3) : Colors.white.withOpacity(0.05))),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Stack(
            children: [
              CircleAvatar(backgroundColor: s.isOpen ? AppColors.green.withOpacity(0.1) : Colors.white10, child: Icon(LucideIcons.user, color: s.isOpen ? AppColors.green : Colors.grey, size: 20)),
              if (s.isOpen) Positioned(right: 0, bottom: 0, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: AppColors.surface, width: 2))))),
            ],
          ),
          title: Text(s.userId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(s.isOpen ? 'VENDIENDO: ${fmt.format(shiftSales.fold(0.0, (sum, v) => sum + v.total))}' : 'CIERRE: ${fmt.format(s.closingBalance ?? 0)}', style: TextStyle(color: s.isOpen ? AppColors.green : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!s.isOpen) 
                Text(diff == 0 ? 'OK' : (diff > 0 ? 'SOBRÓ' : 'FALTÓ'), style: TextStyle(color: diff == 0 ? AppColors.green : (diff > 0 ? AppColors.blue : Colors.redAccent), fontWeight: FontWeight.bold, fontSize: 10)),
              Text(s.isOpen ? 'BASE: ${fmt.format(s.openingBalance)}' : 'DIF: ${fmt.format(diff)}', style: TextStyle(color: s.isOpen ? AppColors.textSecondary : (diff >= 0 ? AppColors.textSecondary : Colors.redAccent), fontWeight: FontWeight.bold)),
            ],
          ),
          onTap: () => _showShiftDetailAudit(context, ref, s, fmt, totalExpected, diff, shiftSales),
        ),
      );
    });
  }

  void _showShiftDetailAudit(BuildContext context, WidgetRef ref, Shift shift, NumberFormat fmt, double expected, double diff, List sales) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AUDITORÍA DE TURNO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
                      Text(shift.userId, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: shift.isOpen ? AppColors.green.withOpacity(0.1) : Colors.white10, borderRadius: BorderRadius.circular(10)),
                    child: Text(shift.isOpen ? 'ACTIVO' : 'CERRADO', style: TextStyle(color: shift.isOpen ? AppColors.green : Colors.grey, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildAuditRow('Base Inicial', fmt.format(shift.openingBalance), icon: LucideIcons.banknote),
              _buildAuditRow('Ventas Efectivo', fmt.format(sales.where((v) => v.paymentMethod == 'Efectivo').fold(0.0, (sum, v) => sum + v.total)), icon: LucideIcons.trendingUp, color: AppColors.green),
              _buildAuditRow('Salidas / Gastos', fmt.format(shift.expensesTotal), icon: LucideIcons.minusCircle, color: Colors.redAccent),
              const Divider(height: 40, color: Colors.white10),
              _buildAuditRow('DEBE HABER:', fmt.format(expected), isBold: true),
              if (!shift.isOpen) ...[
                const Divider(color: Colors.white10),
                _buildAuditRow('EFECTIVO REPORTADO:', fmt.format(shift.closingBalance ?? 0), color: AppColors.blue, isBold: true),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (shift.closingBalance ?? 0) >= expected ? AppColors.green.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text((shift.closingBalance ?? 0) >= expected ? 'SOBRANTE / OK' : 'FALTANTE EN CAJA', 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: (shift.closingBalance ?? 0) >= expected ? AppColors.green : Colors.redAccent)),
                          Text(fmt.format((shift.closingBalance ?? 0) - expected), 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: (shift.closingBalance ?? 0) >= expected ? AppColors.green : Colors.redAccent)),
                        ],
                      ),
                      if (diff < 0) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                            onPressed: () {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faltante marcado como cobrado al empleado'), backgroundColor: Colors.blueAccent));
                               Navigator.pop(context);
                            },
                            icon: const Icon(LucideIcons.userCheck, size: 14),
                            label: const Text('CONDONAR / COBRAR FALTANTE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              
              const SizedBox(height: 32),
              const Text('TICKETS DEL TURNO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Expanded(
                child: sales.isEmpty 
                  ? const Center(child: Text('Sin ventas en este turno', style: TextStyle(color: Colors.white24, fontSize: 12)))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: sales.length,
                      itemBuilder: (context, index) {
                        final s = sales[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            dense: true,
                            title: Text('Ticket \$${s.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(DateFormat('HH:mm').format(s.date)),
                            trailing: s.cancelled 
                              ? const Text('CANCELADO', style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold))
                              : const Icon(LucideIcons.chevronRight, size: 14),
                          ),
                        );
                      },
                    ),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('CERRAR REVISIÓN'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuditRow(String label, String value, {bool isBold = false, Color? color, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 16, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : null, color: isBold ? Colors.white : AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color, fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.1), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyExpenses() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: const Center(child: Text('Sin gastos registrados hoy', style: TextStyle(color: Colors.white24, fontSize: 13))),
    );
  }

  Widget _buildExpensesList(List expenses, NumberFormat fmt, WidgetRef ref) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final e = expenses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(LucideIcons.minusCircle, color: Colors.redAccent, size: 20),
            title: Text(e.description, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(e.category, style: const TextStyle(fontSize: 12)),
            trailing: Text('-${fmt.format(e.amount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
            onLongPress: () => ref.read(expenseProvider.notifier).deleteExpense(e),
          ),
        );
      },
    );
  }

  void _showResetDemoDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reiniciar Demo'),
        content: const Text('Esto borrará TODA la información actual y cargará el "Escenario Perfecto" de 7 días (ventas, turnos y productos). ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Llamar al seeder de reinicio maestro
              await DemoDataSeeder.resetAndSeed();
              // Forzar refresco global de datos
              ref.read(productSourceProvider.notifier).refresh();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escenario Perfecto Cargado con Éxito'), backgroundColor: Colors.blueAccent));
              }
            },
            child: const Text('SÍ, REINICIAR'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir al menú principal?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pop(context);
            },
            child: const Text('SÍ, SALIR', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, WidgetRef ref) {
    final descController = TextEditingController();
    final amntController = TextEditingController();
    String selectedCat = 'Operativo';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Registrar Gasto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Descripción')),
              TextField(controller: amntController, decoration: const InputDecoration(labelText: 'Monto'), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: selectedCat,
                isExpanded: true,
                items: ['Operativo', 'Sueldos', 'Mercancía', 'Otros'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => selectedCat = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amntController.text) ?? 0;
                if (amount > 0) {
                  ref.read(expenseProvider.notifier).addExpense(Expense(
                    description: descController.text,
                    amount: amount,
                    date: DateTime.now(),
                    category: selectedCat,
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('GUARDAR'),
            ),
          ],
        ),
      ),
    );
  }
}
