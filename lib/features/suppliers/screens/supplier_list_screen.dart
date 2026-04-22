import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/supplier.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SupplierListScreen extends ConsumerWidget {
  const SupplierListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Supplier>('suppliers').listenable(),
      builder: (context, Box<Supplier> box, _) {
        final suppliers = box.values.toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mis Proveedores'),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.plusCircle),
                onPressed: () => _showAddSupplierDialog(context, box),
              ),
            ],
          ),
          body: suppliers.isEmpty
              ? _buildEmptyState(context, box)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: suppliers.length,
                  itemBuilder: (context, index) {
                    final s = suppliers[index];
                    final lastPurchase = s.purchases.isNotEmpty ? s.purchases.last : null;
                    
                    return FadeInDown(
                      delay: Duration(milliseconds: index * 50),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.blue.withOpacity(0.1),
                            child: const Icon(LucideIcons.truck, color: AppColors.blue),
                          ),
                          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (s.contactName != null) Text('Vendedor: ${s.contactName}'),
                              if (lastPurchase != null) 
                                Text('Última compra: \$${lastPurchase.amount.toStringAsFixed(2)}', 
                                  style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          trailing: const Icon(LucideIcons.chevronRight),
                          onTap: () => _showSupplierDetails(context, s),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, Box<Supplier> box) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.truck, size: 80, color: AppColors.textSecondary.withOpacity(0.2)),
          const SizedBox(height: 24),
          const Text('Aún no tienes proveedores', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Registra a quienes te surten mercancía', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddSupplierDialog(context, box),
            icon: const Icon(LucideIcons.plus),
            label: const Text('AGREGAR PROVEEDOR'),
          ),
        ],
      ),
    );
  }

  void _showAddSupplierDialog(BuildContext context, Box<Supplier> box) {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Proveedor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre del Negocio (ej: Bimbo)')),
            const SizedBox(height: 12),
            TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Nombre del Vendedor')),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Teléfono de Pedidos'), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                final s = Supplier(
                  name: nameCtrl.text,
                  contactName: contactCtrl.text.isEmpty ? null : contactCtrl.text,
                  phone: phoneCtrl.text.isEmpty ? null : phoneCtrl.text,
                );
                box.add(s);
                Navigator.pop(context);
              }
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  void _showSupplierDetails(BuildContext context, Supplier supplier) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SupplierDetailScreen(supplier: supplier)),
    );
  }
}

class SupplierDetailScreen extends StatelessWidget {
  final Supplier supplier;
  const SupplierDetailScreen({super.key, required this.supplier});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(supplier.name)),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Supplier>('suppliers').listenable(),
        builder: (context, Box<Supplier> box, _) {
          final s = box.get(supplier.key) ?? supplier;
          
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: AppColors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (s.contactName != null) ...[
                      const Text('CONTACTO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      Text(s.contactName!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                    ],
                    if (s.phone != null) ...[
                      const Text('TELÉFONO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      Row(
                        children: [
                          Text(s.phone!, style: const TextStyle(fontSize: 16)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(LucideIcons.phone, color: AppColors.blue),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.messageCircle, color: Color(0xFF25D366)),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text('HISTORIAL DE NOTAS / COMPRAS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: s.purchases.isEmpty
                    ? const Center(child: Text('No hay compras registradas'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: s.purchases.length,
                        itemBuilder: (context, index) {
                          final p = s.purchases.reversed.toList()[index];
                          final dateStr = DateFormat('dd MMM yyyy', 'es').format(p.date);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text('\$${p.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(dateStr),
                              trailing: p.ticketPhotos.isNotEmpty
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Text('${p.ticketPhotos.length} fotos', style: const TextStyle(fontSize: 10, color: AppColors.blue, fontWeight: FontWeight.bold)),
                                    )
                                  : const Icon(LucideIcons.imageOff, size: 16, color: Colors.grey),
                              onTap: () => _viewPurchaseTicket(context, p),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPurchaseDialog(context),
        icon: const Icon(LucideIcons.camera),
        label: const Text('REGISTRAR COMPRA'),
      ),
    );
  }

  void _showAddPurchaseDialog(BuildContext context) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final List<String> tempPhotos = [];
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Registrar Compra / Nota', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              // Selector de Fecha
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setModalState(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 20, color: AppColors.blue),
                      const SizedBox(width: 12),
                      Text('Fecha: ${DateFormat('dd/MM/yyyy').format(selectedDate)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      const Icon(LucideIcons.edit2, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(labelText: 'Monto de la Nota', prefixText: r'$ '),
              ),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción (opcional)')),
              const SizedBox(height: 24),
              const Text('FOTOS DEL TICKET / NOTA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...tempPhotos.asMap().entries.map((entry) {
                      final index = entry.key;
                      final path = entry.value;
                      return Stack(
                        children: [
                          Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(File(path), fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.red))),
                            ),
                          ),
                          Positioned(
                            top: -4,
                            right: 4,
                            child: IconButton(
                              icon: const CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.red,
                                child: Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                              onPressed: () => setModalState(() => tempPhotos.removeAt(index)),
                            ),
                          ),
                        ],
                      );
                    }),
                    GestureDetector(
                      onTap: () async {
                        if (Platform.isWindows) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cámara no disponible en Windows. Usa la Galería o el APK de Android.'))
                          );
                          return;
                        }
                        final picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 70,
                        );
                        if (image != null) {
                          setModalState(() => tempPhotos.add(image.path));
                        }
                      },
                      child: Container(
                        width: 80,
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(LucideIcons.camera, color: AppColors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: tempPhotos.isEmpty ? Colors.grey : AppColors.blue,
                ),
                onPressed: tempPhotos.isEmpty 
                  ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, toma al menos una foto de la nota')))
                  : () {
                  final amount = double.tryParse(amountCtrl.text) ?? 0;
                  if (amount > 0) {
                    final p = SupplierPurchase(
                      date: selectedDate,
                      amount: amount,
                      ticketPhotos: List.from(tempPhotos),
                      description: descCtrl.text,
                    );
                    supplier.purchases.add(p);
                    supplier.save();
                    Navigator.pop(context);
                  }
                },
                child: const Text('GUARDAR COMPRA'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _viewPurchaseTicket(BuildContext context, SupplierPurchase purchase) {
    if (purchase.ticketPhotos.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              title: Text('Nota de \$${purchase.amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
              leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
            ),
            Expanded(
              child: PageView.builder(
                itemCount: purchase.ticketPhotos.length,
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    child: Image.file(File(purchase.ticketPhotos[index])),
                  );
                },
              ),
            ),
            if (purchase.ticketPhotos.length > 1)
               Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Desliza para ver más (${purchase.ticketPhotos.length})', style: const TextStyle(color: Colors.white54)),
              ),
          ],
        ),
      ),
    );
  }
}
