import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'continuous_scanner_view.dart';
import '../../../core/widgets/product_image_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../inventory/providers/product_provider.dart';
import '../../inventory/screens/product_form_screen.dart';
import '../providers/cart_provider.dart';
import '../providers/sales_history_provider.dart';
import '../../../data/providers/hive_providers.dart';
import '../../../data/models/product.dart';
import '../../../data/models/sale.dart';
import '../../../data/models/shift.dart';
import '../../auth/providers/shift_provider.dart';
import '../../auth/providers/auth_provider.dart';

import '../../../data/models/expense.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  bool _isProcessingPayment = false;

  final TextEditingController _searchController = TextEditingController();

  void _onSearchChanged(String query, WidgetRef ref) {
    final products = ref.read(salesProductProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    // Búsqueda inteligente por código de barras exacto
    final exactMatch = products.where((p) => p.barcode == query.trim()).toList();
    if (exactMatch.isNotEmpty && query.length >= 8) { // Mínimo de dígitos para evitar falsos positivos
       final p = exactMatch.first;
       if (p.existencias > 0) {
         cartNotifier.addProduct(p);
         _searchController.clear();
         ref.read(salesProductProvider.notifier).search(''); // Resetear búsqueda
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Añadido: ${p.nombre}'), duration: const Duration(seconds: 1), backgroundColor: AppColors.green),
         );
         return;
       }
    }
    
    ref.read(salesProductProvider.notifier).search(query);
    
    // Si es un código largo y no hay coincidencias, sugerir registro
    if (query.trim().length >= 8 && products.isEmpty) {
       _suggestNewProduct(context, query.trim());
    }
  }

  void _suggestNewProduct(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Producto Nuevo'),
        content: Text('El código "$code" no está registrado. ¿Quieres darlo de alta ahora?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _searchController.clear();
              ref.read(salesProductProvider.notifier).search('');
              // Navegar al formulario con el código precargado
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => ProductFormScreen(
                  productToEdit: Product(
                    nombre: '', 
                    barcode: code, 
                    aliases: [], 
                    categoria: 'Otros', 
                    unidadMedida: 'pieza', 
                    existencias: 10, 
                    precioCosto: 0, 
                    precioVenta: 0
                  ),
                ))
              );
            },
            child: const Text('SÍ, REGISTRAR'),
          ),
        ],
      ),
    );
  }

  void _showQuantityDialog(BuildContext context, Product p, int currentQty) {
    final TextEditingController qtyController = TextEditingController(text: currentQty.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cantidad: ${p.nombre}'),
        content: TextField(
          controller: qtyController,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Piezas / Cantidad'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              final int newQty = int.tryParse(qtyController.text) ?? currentQty;
              ref.read(cartProvider.notifier).updateQuantity(p, newQty);
              Navigator.pop(context);
            },
            child: const Text('ACEPTAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(salesProductProvider);
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final activeShift = ref.watch(shiftProvider);

    // GUARDIA DE TURNO
    if (activeShift == null) {
      return const _ShiftOpeningGuard();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caja'),
        leading: IconButton(
          icon: const Icon(LucideIcons.logOut, color: Colors.redAccent),
          onPressed: () => _confirmLogout(context, ref),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.minusCircle, color: Colors.orangeAccent),
            tooltip: 'Registrar Gasto / Salida',
            onPressed: () => _showAddExpenseDialog(context, ref, activeShift),
          ),
          IconButton(
            icon: const Icon(LucideIcons.lock, color: Colors.orangeAccent),
            tooltip: 'Cerrar Turno',
            onPressed: () => _showCloseShiftDialog(context, ref, activeShift),
          ),
          IconButton(
            icon: const Icon(LucideIcons.scan, color: AppColors.blue),
            tooltip: 'Escanear',
            onPressed: () => _scanBarcode(context),
          ),
          if (cart.isNotEmpty)
            FadeIn(
              child: IconButton(
                icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
                onPressed: () => cartNotifier.clear(),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => _onSearchChanged(v, ref),
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Buscar o Escanear Código...',
                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty 
                        ? IconButton(icon: const Icon(LucideIcons.x, size: 16), onPressed: () { _searchController.clear(); ref.read(salesProductProvider.notifier).search(''); })
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),

              Expanded(
                child: products.isEmpty
                    ? const Center(child: Text('No hay productos coincidentes'))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = constraints.maxWidth > 900 ? 5 : (constraints.maxWidth > 600 ? 3 : 2);
                          return InteractiveViewer(
                            panEnabled: false, // Solo permitir zoom, no desplazamiento libre
                            boundaryMargin: const EdgeInsets.all(20),
                            minScale: 1.0,
                            maxScale: 2.0,
                            child: GridView.builder(
                              padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 150),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final p = products[index];
                                final cartItemIndex = cart.indexWhere((item) => item.product.nombre == p.nombre);
                                final quantity = cartItemIndex != -1 ? cart[cartItemIndex].quantity : 0;

                                return FadeInUp(
                                  delay: Duration(milliseconds: index * 20),
                                  child: Card(
                                    clipBehavior: Clip.antiAlias,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: ProductImageWidget(p.fotoPath),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              Text('\$${p.precioVenta.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 8),
                                              Container(
                                                height: 36,
                                                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(20)),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                  children: [
                                                    IconButton(
                                                      padding: EdgeInsets.zero,
                                                      icon: const Icon(LucideIcons.minus, size: 14),
                                                      onPressed: quantity > 0 ? () => cartNotifier.updateQuantity(p, quantity - 1) : null,
                                                    ),
                                                    InkWell(
                                                      onTap: () => _showQuantityDialog(context, p, quantity),
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                                        child: Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      padding: EdgeInsets.zero,
                                                      icon: const Icon(LucideIcons.plus, size: 14, color: AppColors.green),
                                                      onPressed: p.existencias > quantity ? () => cartNotifier.addProduct(p) : null,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // BARRA INFERIOR DE COBRO (CARRITO)
          if (cart.isNotEmpty)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: FadeInUp(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20)],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _showCartDetails(context, ref),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            width: double.infinity,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.shoppingCart, size: 14, color: AppColors.blue),
                                const SizedBox(width: 8),
                                Text('VER DETALLE (${cart.length} ITEMS)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.blue)),
                                const Icon(LucideIcons.chevronUp, size: 14, color: AppColors.blue),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TOTAL A PAGAR', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                Text('\$${cartNotifier.totalRevenue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.green)),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.green,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                ),
                                onPressed: () => _showPaymentModal(context, cartNotifier),
                                child: const Text('COBRAR AHORA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCartDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final currentCart = ref.watch(cartProvider);
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DETALLE DEL CARRITO', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                const SizedBox(height: 16),
                if (currentCart.isEmpty)
                   const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('El carrito está vacío')))
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: currentCart.length,
                      separatorBuilder: (_, __) => const Divider(height: 16, color: Colors.white10),
                      itemBuilder: (context, index) {
                        final item = currentCart[index];
                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text('${item.quantity.toInt()}x', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(item.product.nombre, style: const TextStyle(fontWeight: FontWeight.w500))),
                            Text('\$${(item.product.precioVenta * item.quantity).toStringAsFixed(2)}'),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(LucideIcons.x, size: 18, color: Colors.redAccent),
                              onPressed: () {
                                ref.read(cartProvider.notifier).updateQuantity(item.product, 0);
                                if (currentCart.length <= 1) Navigator.pop(context);
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPaymentModal(BuildContext context, CartNotifier notifier) {
    final TextEditingController receivedController = TextEditingController();
    final salesBox = ref.read(salesBoxProvider);
    final allProducts = ref.read(productSourceProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final total = notifier.totalRevenue;
          final received = double.tryParse(receivedController.text) ?? 0;
          final change = received - total;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 24),
                  Text('TOTAL A RECIBIR: \$${total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: receivedController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    onChanged: (_) => setModalState(() {}),
                    decoration: const InputDecoration(
                      hintText: '0.00', 
                      hintStyle: TextStyle(color: Colors.white38),
                      prefixText: r'$ ', 
                      prefixStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (change >= 0 && received > 0)
                    FadeIn(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            const Text('CAMBIO A ENTREGAR', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                            Text('\$${change.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontSize: 32, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  if (_isProcessingPayment)
                    const CircularProgressIndicator()
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _buildPaymentButton(
                            label: 'EFECTIVO',
                            icon: LucideIcons.banknote,
                            color: Colors.green,
                            onTap: () async {
                              if (received < total) return;
                              setModalState(() => _isProcessingPayment = true);
                              final activeShift = ref.read(shiftProvider);
                              final sale = await notifier.checkout('Efectivo', salesBox, allProducts, activeShift);
                              if (mounted) Navigator.pop(context);
                              if (mounted) _showFinalTicket(context, notifier, received, sale);
                              setModalState(() => _isProcessingPayment = false);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildPaymentButton(
                            label: 'TARJETA',
                            icon: LucideIcons.creditCard,
                            color: Colors.blue,
                            onTap: () async {
                              setModalState(() => _isProcessingPayment = true);
                              final activeShift = ref.read(shiftProvider);
                              final sale = await notifier.checkout('Tarjeta', salesBox, allProducts, activeShift);
                              if (mounted) Navigator.pop(context);
                              if (mounted) _showFinalTicket(context, notifier, total, sale);
                              setModalState(() => _isProcessingPayment = false);
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _showFinalTicket(BuildContext context, CartNotifier notifier, double received, Sale sale) {
    final change = received - sale.total;
    final date = DateFormat('dd/MM HH:mm').format(sale.date);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.checkCircle2, color: Colors.green, size: 60),
            const SizedBox(height: 12),
            const Text('VENTA EXITOSA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18)),
            const Divider(),
            if (change > 0) ...[
               const Text('CAMBIO:', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
               Text('\$${change.toStringAsFixed(2)}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.green)),
               const Divider(),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ...sale.products.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${p.quantity.toInt()}x ${p.productName}', style: const TextStyle(color: Colors.black87, fontSize: 13)),
                        Text('\$${(p.priceAtSale * p.quantity).toStringAsFixed(2)}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      Text('\$${sale.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(LucideIcons.messageCircle),
              label: const Text('ENVIAR POR WHATSAPP'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { notifier.clear(); Navigator.pop(context); },
            child: const Text('NUEVA VENTA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Future<void> _scanBarcode(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ContinuousScannerView()),
    );
  }

  void _showAddExpenseDialog(BuildContext context, WidgetRef ref, Shift shift) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salida de Dinero / Gasto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Se restará del total esperado en caja.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto', prefixText: r'$ ')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Motivo / Descripción (ej: Pago a Bimbo)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount > 0) {
                 final expense = Expense(description: descCtrl.text, amount: amount, date: DateTime.now(), category: 'Turno / Caja');
                 await ref.read(expensesBoxProvider).add(expense);
                 
                 // Actualizar el turno con el gasto
                 shift.expensesTotal += amount;
                 await shift.save();
                 
                 if (mounted) Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Salida de \$${amount.toStringAsFixed(2)} registrada'), backgroundColor: Colors.orangeAccent));
              }
            },
            child: const Text('REGISTRAR'),
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
        content: const Text('¿Deseas salir al menú principal?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          TextButton(onPressed: () { ref.read(authProvider.notifier).logout(); Navigator.pop(context); }, child: const Text('SÍ, SALIR', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  void _showCloseShiftDialog(BuildContext context, WidgetRef ref, Shift shift) {
    final amountCtrl = TextEditingController();
    final allSales = ref.read(salesProvider);
    final shiftSales = allSales.where((s) => s.shiftKey == shift.key && !s.cancelled).toList();
    
    final totalCashSales = shiftSales.where((s) => s.paymentMethod == 'Efectivo').fold(0.0, (sum, s) => sum + s.total);
    final totalSales = shiftSales.fold(0.0, (sum, s) => sum + s.total);
    final expectedCash = (shift.openingBalance + totalCashSales) - shift.expensesTotal;
    double actualCashCount = 0.0; // Variable para el conteo real

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final diff = actualCashCount - expectedCash;
          return AlertDialog(
            title: const Text('Cierre de Turno / Caja', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceRow('Fondo Inicial', '+ \$${shift.openingBalance.toStringAsFixed(2)}', Colors.grey),
                _buildBalanceRow('Ventas Efectivo', '+ \$${totalCashSales.toStringAsFixed(2)}', Colors.green),
                _buildBalanceRow('Gastos / Salidas', '- \$${shift.expensesTotal.toStringAsFixed(2)}', Colors.red),
                const Divider(),
                _buildBalanceRow('DEBE HABER EN CAJA', '\$${expectedCash.toStringAsFixed(2)}', AppColors.blue, bold: true),
                const SizedBox(height: 24),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(labelText: 'Contado en Caja (Efectivo)', prefixText: r'$ '),
                  onChanged: (value) => setState(() => actualCashCount = double.tryParse(value) ?? 0),
                ),
                if (diff != 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildBalanceRow(
                      diff > 0 ? 'SOBRANTE' : 'FALTANTE',
                      '\$${diff.abs().toStringAsFixed(2)}',
                      diff > 0 ? AppColors.green : Colors.redAccent,
                      bold: true,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
              if (diff > 0) // Si hay sobrante, mostrar botón de Resguardo
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
                  onPressed: () async {
                    if (actualCashCount > 0) {
                      // await ref.read(shiftProvider.notifier).resguardarSobrante(shift, actualCashCount, expectedCash, totalSales);
                      if (context.mounted) Navigator.pop(context);
                      // No mostrar resumen si se resguarda, el estado de caja es diferente
                    }
                  },
                  child: const Text('RESGUARDAR SOBRANTE'),
                ),
              ElevatedButton(
                onPressed: () async {
                   if (actualCashCount > 0) {
                     await ref.read(shiftProvider.notifier).closeShift(actualCashCount);
                     if (context.mounted) Navigator.pop(context);
                     _showShiftResultSummary(context, expectedCash, actualCashCount, actualCashCount - expectedCash);
                   }
                },
                child: const Text('CERRAR TURNO'),
              ),
            ],
          );
        },
      ),
    );
  }


  Widget _buildBalanceRow(String label, String value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  void _showShiftResultSummary(BuildContext context, double expected, double actual, double diff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resumen de Cierre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(diff == 0 ? '¡CAJA PERFECTA!' : (diff > 0 ? 'SOBRANTE' : 'FALTANTE'), 
                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: diff == 0 ? Colors.green : (diff > 0 ? Colors.blue : Colors.red))),
            const SizedBox(height: 12),
            Text('Diferencia: \$${diff.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Text('Efectivo Esperado: \$${expected.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text('Efectivo Reportado: \$${actual.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('FINALIZAR')),
        ],
      ),
    );
  }
}

class _ShiftOpeningGuard extends ConsumerStatefulWidget {
  const _ShiftOpeningGuard();
  @override
  ConsumerState<_ShiftOpeningGuard> createState() => _ShiftOpeningGuardState();
}

class _ShiftOpeningGuardState extends ConsumerState<_ShiftOpeningGuard> {
  final TextEditingController _amountController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.lock, size: 64, color: AppColors.blue),
              const SizedBox(height: 24),
              Text('Hola, ${auth.userName}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Registra tu fondo inicial (base) para empezar a vender.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 40),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(labelText: 'Fondo Inicial', prefixText: r'$ '),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () => ref.read(shiftProvider.notifier).openShift(double.tryParse(_amountController.text) ?? 0),
                child: const Text('ABRIR TURNO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              TextButton(onPressed: () => ref.read(authProvider.notifier).logout(), child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        ),
      ),
    );
  }
}
