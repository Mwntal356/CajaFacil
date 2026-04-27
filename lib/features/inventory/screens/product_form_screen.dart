import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/product_provider.dart';
import '../../../data/models/product.dart';

const List<String> categorias = ['Abarrotes', 'Frutería', 'Lácteos', 'Limpieza', 'Botanas', 'Refrescos', 'Panadería', 'Otros'];
const List<String> unidades = ['pieza', 'kg', 'litro', 'gramo', 'paquete', 'caja'];

class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? productToEdit;
  const ProductFormScreen({super.key, this.productToEdit});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _costController;
  late TextEditingController _saleController;
  late TextEditingController _stockController;
  late TextEditingController _aliasesController;
  late TextEditingController _barcodeController;
  late TextEditingController _stockMinimoController;

  String _categoria = 'Abarrotes';
  String _unidadMedida = 'pieza';
  String? _fotoPath;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    
    // Aseguramos que la categoría cargada exista en la lista, si no la agregamos
    final List<String> categoriasMutable = List.from(categorias);
    if (p != null && !categoriasMutable.contains(p.categoria)) {
      categoriasMutable.add(p.categoria);
    }
    
    _nameController = TextEditingController(text: p?.nombre ?? '');
    _costController = TextEditingController(text: p?.precioCosto != null ? p!.precioCosto.toString() : '');
    _saleController = TextEditingController(text: p?.precioVenta != null ? p!.precioVenta.toString() : '');
    _stockController = TextEditingController(text: p?.existencias != null ? p!.existencias.toString() : '');
    _aliasesController = TextEditingController(text: p?.aliases?.join(', ') ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _stockMinimoController = TextEditingController(text: p?.stockMinimo != null ? p!.stockMinimo.toString() : '5.0');
    
    _categoria = p?.categoria ?? categorias.first;
    _unidadMedida = p?.unidadMedida ?? unidades.first;
    _fotoPath = p?.fotoPath;
  }

  Future<void> _scanBarcode() async {
    final String? result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text('Escaneando Código...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      Navigator.pop(context, barcodes.first.rawValue);
                    }
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCELAR'),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _barcodeController.text = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Código detectado: $result'), backgroundColor: AppColors.green),
      );
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera, color: AppColors.green),
              title: const Text('Tomar Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.image, color: AppColors.blue),
              title: const Text('Elegir de Galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Optimizar para la demo
        maxWidth: 800,
      );
      if (image != null) {
        setState(() {
          _fotoPath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al capturar la imagen')),
      );
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final product = widget.productToEdit ?? Product(
      nombre: '', aliases: [], categoria: '', unidadMedida: '', existencias: 0, precioCosto: 0, precioVenta: 0
    );

    product.nombre = _nameController.text.trim();
    product.aliases = _aliasesController.text.isNotEmpty 
          ? _aliasesController.text.split(',').map((e) => e.trim()).toList() 
          : [];
    product.categoria = _categoria;
    product.unidadMedida = _unidadMedida;
    product.existencias = double.tryParse(_stockController.text) ?? 0;
    product.precioCosto = double.tryParse(_costController.text) ?? 0.0;
    product.precioVenta = double.tryParse(_saleController.text) ?? 0.0;
    product.fotoPath = _fotoPath;
    product.barcode = _barcodeController.text.trim();
    product.stockMinimo = double.tryParse(_stockMinimoController.text) ?? 5.0;

    await ref.read(productSourceProvider.notifier).saveProduct(product);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.productToEdit == null ? 'Nuevo Producto' : 'Editar Producto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ... (Imagen igual)
              GestureDetector(
                onTap: () => _showImageSourceActionSheet(context),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.green.withOpacity(0.2)),
                  ),
                  child: _fotoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _fotoPath!.startsWith('http')
                              ? Image.network(
                                  _fotoPath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.imagePlus, size: 50, color: AppColors.green),
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green));
                                  },
                                )
                              : File(_fotoPath!).existsSync()
                                  ? Image.file(File(_fotoPath!), fit: BoxFit.cover)
                                  : const Icon(LucideIcons.imagePlus, size: 50, color: AppColors.green),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.imagePlus, size: 50, color: AppColors.green),
                            SizedBox(height: 8),
                            Text('Añadir imagen del producto'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              
              // CÓDIGO DE BARRAS (Nuevo)
              TextFormField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  labelText: 'Código de Barras',
                  prefixIcon: const Icon(LucideIcons.scan),
                  suffixIcon: IconButton(
                    icon: const Icon(LucideIcons.scan, color: AppColors.blue),
                    onPressed: _scanBarcode,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController, 
                decoration: const InputDecoration(labelText: 'Nombre del Producto', prefixIcon: Icon(LucideIcons.shoppingBag)),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(child: DropdownButtonFormField<String>(
                    value: _categoria,
                    items: categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _categoria = v!),
                    decoration: const InputDecoration(labelText: 'Categoría'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: DropdownButtonFormField<String>(
                    value: unidades.contains(_unidadMedida) ? _unidadMedida : unidades.first,
                    items: unidades.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setState(() => _unidadMedida = v!),
                    decoration: const InputDecoration(labelText: 'Unidad'),
                  )),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _costController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Costo Unitario', prefixText: r'$ '))),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _saleController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio Venta', prefixText: r'$ '))),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Actual', prefixIcon: Icon(LucideIcons.package)))),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _stockMinimoController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Mínimo', prefixIcon: Icon(LucideIcons.alertTriangle), hintText: 'Avisar en...'))),
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _aliasesController, 
                decoration: const InputDecoration(
                  labelText: 'Búsqueda rápida (Aliases)', 
                  helperText: 'Separa por comas: coca, refresco, soda',
                  prefixIcon: Icon(LucideIcons.search),
                )
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: _saveProduct, 
                  child: Text(widget.productToEdit == null ? 'REGISTRAR PRODUCTO' : 'GUARDAR CAMBIOS', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}