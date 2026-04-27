import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../data/models/product.dart';
import '../../../core/theme/app_theme.dart';
import '../../inventory/providers/product_provider.dart';
import '../providers/cart_provider.dart';

class ContinuousScannerView extends ConsumerStatefulWidget {
  const ContinuousScannerView({super.key});

  @override
  ConsumerState<ContinuousScannerView> createState() => _ContinuousScannerViewState();
}

class _ContinuousScannerViewState extends ConsumerState<ContinuousScannerView> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  String? lastCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear Productos'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final code = barcodes.first.rawValue;
                  if (code != null && code != lastCode) {
                    setState(() => lastCode = code);
                    
                    final products = ref.read(productProvider);
                    final cartNotifier = ref.read(cartProvider.notifier);
                    
                    final product = products.firstWhere(
                      (p) => p.barcode == code,
                      orElse: () => Product(nombre: 'Error', barcode: '', precioVenta: 0, precioCosto: 0, existencias: 0, stockMinimo: 0, unidadMedida: '', categoria: '', aliases: []),
                    );
                    
                    if (product.barcode != null && product.barcode!.isNotEmpty) {
                      cartNotifier.addProduct(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Añadido: ${product.nombre}'),
                          duration: const Duration(milliseconds: 800),
                          backgroundColor: AppColors.green,
                        ),
                      );
                      // Resetear lastCode después de un breve tiempo para permitir escanear el mismo de nuevo
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) setState(() => lastCode = null);
                      });
                    }
                  }
                }
              },
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              color: AppColors.surface,
              child: Consumer(
                builder: (context, ref, child) {
                  final cart = ref.watch(cartProvider);
                  final cartNotifier = ref.read(cartProvider.notifier);
                  
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return Row(
                        children: [
                          Expanded(child: Text(item.product.nombre, style: const TextStyle(fontWeight: FontWeight.bold))),
                          IconButton(
                            icon: const Icon(LucideIcons.minus),
                            onPressed: () => cartNotifier.updateQuantity(item.product, (item.quantity - 1).toInt()),
                          ),
                          Text('${item.quantity.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(LucideIcons.plus),
                            onPressed: () => cartNotifier.addProduct(item.product),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
