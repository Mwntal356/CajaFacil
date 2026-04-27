import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../admin/providers/admin_provider.dart'; // Importar adminProvider
import '../providers/product_provider.dart';
import 'product_form_screen.dart';
import 'product_details_screen.dart';
import 'report_screen.dart';
import '../../../core/widgets/product_image_widget.dart';
import '../../../core/utils/inventory_report_generator.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _searchQuery = '';
  
  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productProvider);
    final auth = ref.watch(authProvider);
    final isDueno = auth.role == UserRole.dueno;
    final adminStats = ref.watch(adminStatsProvider);
    
    final filteredProducts = products.where((p) => 
      p.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) || 
      (p.barcode?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isDueno ? 'Inventario Central' : 'Consulta de Precios'),
        actions: [
          if (isDueno)
            IconButton(
              icon: const Icon(LucideIcons.fileText, color: AppColors.blue),
              tooltip: 'Generar Reporte',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(products: products))),
            ),
          if (isDueno)
            IconButton(
              icon: const Icon(LucideIcons.plusCircle, color: AppColors.blue),
              tooltip: 'Agregar Producto',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductFormScreen())),
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
              onChanged: (query) => setState(() => _searchQuery = query),
              decoration: const InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: Icon(LucideIcons.search),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Lista de Inventario
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(child: Text('No hay productos coincidentes'))
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final p = filteredProducts[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            onTap: () => Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: p))
                            ),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: p.esStockBajo 
                                    ? Border.all(color: Colors.red, width: 2)
                                    : null,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: ProductImageWidget(p.fotoPath, size: 48),
                              ),
                            ),
                            title: Text(
                              p.nombre, 
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                color: p.esStockBajo ? Colors.red : null
                              )
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Stock: ${p.existencias.toStringAsFixed(0)} ${p.unidadMedida} | Venta: \$${p.precioVenta.toStringAsFixed(2)}'),
                                if (isDueno) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Costo: \$${p.precioCosto.toStringAsFixed(2)} | Margen: ${p.utilidadPorcentaje.toStringAsFixed(1)}% | Inv: \$${p.valorTotalInventario.toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 11, color: p.utilidadPorcentaje < 10 ? Colors.red : AppColors.textSecondary),
                                  ),
                                ],
                              ],
                            ),
                            trailing: isDueno ? PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'surtir') _showRestockDialog(context, ref, p);
                                if (value == 'editar') Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(productToEdit: p)));
                                if (value == 'ajuste') _showAdjustmentDialog(context, ref, p);
                                if (value == 'eliminar') _confirmDelete(context, ref, p);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'surtir', 
                                  child: Row(children: [Icon(LucideIcons.packagePlus, size: 18), SizedBox(width: 8), Text('Resurtido')]),
                                ),
                                const PopupMenuItem(
                                  value: 'editar', 
                                  child: Row(children: [Icon(LucideIcons.edit, size: 18), SizedBox(width: 8), Text('Editar')]),
                                ),
                                const PopupMenuItem(
                                  value: 'ajuste', 
                                  child: Row(children: [Icon(LucideIcons.scissors, size: 18), SizedBox(width: 8), Text('Merma / Consumo')]),
                                ),
                                const PopupMenuItem(
                                  value: 'eliminar', 
                                  child: Row(children: [Icon(LucideIcons.trash2, size: 18, color: Colors.red), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: Colors.red))]),
                                ),
                              ],
                            ) : const Icon(LucideIcons.chevronRight),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

}
