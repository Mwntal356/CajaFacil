import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../admin/providers/admin_provider.dart'; // Importar adminProvider
import '../providers/product_provider.dart';
import 'product_form_screen.dart';
import 'product_details_screen.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productProvider);
    final auth = ref.watch(authProvider);
    final isDueno = auth.role == UserRole.dueno;
    final adminStats = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isDueno ? 'Inventario Central' : 'Consulta de Precios'),
        actions: [
          if (isDueno)
            IconButton(
              icon: const Icon(LucideIcons.plusCircle, color: AppColors.blue),
              tooltip: 'Agregar Producto',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductFormScreen())),
            ),
          if (isDueno)
            IconButton(
              icon: const Icon(LucideIcons.settings),
              tooltip: 'Configuración',
              onPressed: () {},
            ),
        ],
      ),
      body: Column(
        children: [
          // Resumen de Inversión (Solo Dueño)
          if (isDueno)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(LucideIcons.boxes, color: AppColors.blue),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Inversión en Stock', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      Text('\$${adminStats.inventoryValueAtCost.toStringAsFixed(2)}', 
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.blue)),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Utilidad Proyectada', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      Text('\$${adminStats.projectedInventoryUtility.toStringAsFixed(2)}', 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.green)),
                    ],
                  ),
                ],
              ),
            ),

          // Buscador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (query) => ref.read(inventoryProductProvider.notifier).search(query),
              decoration: const InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: Icon(LucideIcons.search),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Tabla de inventario
          Expanded(
            child: products.isEmpty
                ? const Center(child: Text('No hay productos registrados'))
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 24,
                        headingRowColor: MaterialStateProperty.all(AppColors.surface),
                        columns: isDueno 
                          ? const [
                              DataColumn(label: Text('Producto', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('P. Costo', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('P. Venta', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Utilidad', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Inversión', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                            ]
                          : const [
                              DataColumn(label: Text('Producto', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Precio Público', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.green))),
                            ],
                        rows: products.map((p) {
                          final utilidadMoney = p.precioVenta - p.precioCosto;
                          final inversion = p.existencias * p.precioCosto;

                          return DataRow(
                            cells: isDueno ? [
                              DataCell(
                                InkWell(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: p))),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.blue)),
                                      Text(p.categoria, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(Text('${p.existencias} ${p.unidadMedida}', style: TextStyle(color: p.esStockBajo ? Colors.orange : null, fontWeight: p.esStockBajo ? FontWeight.bold : null))),
                              DataCell(Text('\$${p.precioCosto.toStringAsFixed(2)}')),
                              DataCell(Text('\$${p.precioVenta.toStringAsFixed(2)}')),
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('\$${utilidadMoney.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                                    Text('${p.utilidadPorcentaje.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              DataCell(Text('\$${inversion.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11))),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(icon: const Icon(LucideIcons.packagePlus, size: 16, color: AppColors.green), onPressed: () => _showRestockDialog(context, ref, p)),
                                    IconButton(icon: const Icon(LucideIcons.minusSquare, size: 16, color: Colors.orangeAccent), onPressed: () => _showAdjustmentDialog(context, ref, p)),
                                    IconButton(icon: const Icon(LucideIcons.edit2, size: 16, color: AppColors.blue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(productToEdit: p)))),
                                  ],
                                ),
                              ),
                            ] : [
                              DataCell(Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text('${p.existencias} ${p.unidadMedida}')),
                              DataCell(Text('\$${p.precioVenta.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.green))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showRestockDialog(BuildContext context, WidgetRef ref, dynamic p) {
    final qtyController = TextEditingController();
    final costController = TextEditingController(text: p.precioCosto.toString());
    final salePriceController = TextEditingController(text: p.precioVenta.toString());
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              const Icon(LucideIcons.packagePlus, color: AppColors.green),
              const SizedBox(width: 12),
              Expanded(child: Text('Surtir ${p.nombre}')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stock actual: ${p.existencias} ${p.unidadMedida} (Costo prom: \$${p.precioCosto.toStringAsFixed(2)})', 
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 16),
              TextField(
                controller: qtyController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Cantidad a añadir',
                  suffixText: p.unidadMedida,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Costo unitario de esta compra',
                  prefixText: r'$ ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: salePriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: '¿Nuevo precio de venta?',
                  prefixText: r'$ ',
                  hintText: 'Dejar igual para no cambiar',
                ),
              ),
              const SizedBox(height: 16),
              Builder(builder: (context) {
                final c = double.tryParse(costController.text) ?? 0;
                final s = double.tryParse(salePriceController.text) ?? 0;
                final margin = (c > 0 && s > 0) ? ((s - c) / c) * 100 : 0.0;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: margin > 0 ? AppColors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Margen Proyectado:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('${margin.toStringAsFixed(1)}%', 
                        style: TextStyle(color: margin > 10 ? AppColors.green : AppColors.orange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () {
                final newQty = double.tryParse(qtyController.text) ?? 0;
                final newCost = double.tryParse(costController.text) ?? p.precioCosto;
                final newPrice = double.tryParse(salePriceController.text);

                if (newQty > 0) {
                  p.restock(newQty, newCost, newSellingPrice: newPrice);
                  ref.read(productSourceProvider.notifier).saveProduct(p);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Inventario actualizado con éxito'), backgroundColor: AppColors.green),
                  );
                }
              },
              child: const Text('SURTIR Y ACTUALIZAR'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdjustmentDialog(BuildContext context, WidgetRef ref, dynamic p) {
    final qtyController = TextEditingController();
    String reason = 'Merma / Daño';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Ajuste de Salida'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sacar del stock de "${p.nombre}" sin registrar venta.', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: qtyController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad a sacar'),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: reason,
                isExpanded: true,
                items: ['Merma / Daño', 'Caducado', 'Consumo Interno', 'Error de Inventario']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => reason = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () {
                final qty = double.tryParse(qtyController.text) ?? 0;
                if (qty > 0 && qty <= p.existencias) {
                  p.existencias -= qty;
                  p.save();
                  ref.read(productSourceProvider.notifier).refresh();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ajuste de $qty registrado como $reason')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cantidad no válida o insuficiente')));
                }
              },
              child: const Text('REGISTRAR SALIDA'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Estás seguro de eliminar "${p.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () {
              ref.read(productSourceProvider.notifier).deleteProduct(p);
              Navigator.pop(context);
            },
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
