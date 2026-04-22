import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/promotion_provider.dart';
import '../../../data/providers/config_provider.dart';

class PromotionsScreen extends ConsumerStatefulWidget {
  const PromotionsScreen({super.key});

  @override
  ConsumerState<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends ConsumerState<PromotionsScreen> {
  final TextEditingController _promoController = TextEditingController();
  String? _selectedImagePath;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImagePath = image.path);
    }
  }

  void _shareWhatsApp(String text) {
    // Simulación de compartido
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abriendo WhatsApp... (Simulado)'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final promoState = ref.watch(promotionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Promociones con IA')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.blue, Color(0xFF64B5F6)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.sparkles, color: Colors.white, size: 30),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Crea anuncios profesionales en segundos usando Inteligencia Artificial.',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Input de descripción
            TextField(
              controller: _promoController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe tu promoción (ej: 2x1 en manzanas rojas solo hoy)',
                fillColor: AppColors.surface,
              ),
            ),
            const SizedBox(height: 16),

            // Selector de Imagen Opcional
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: _selectedImagePath != null 
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(File(_selectedImagePath!), fit: BoxFit.cover),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.camera, color: AppColors.textSecondary),
                        Text('Agregar foto de producto (opcional)', style: TextStyle(fontSize: 12)),
                      ],
                    ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: promoState.isLoading 
                  ? null 
                  : () => ref.read(promotionProvider.notifier).generateFlyer(_promoController.text),
              icon: promoState.isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(LucideIcons.wand2),
              label: const Text('GENERAR FLYER CON IA'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
            ),

            if (promoState.generatedFlyer.isNotEmpty) ...[
              const SizedBox(height: 32),
              FadeInUp(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('VISTA PREVIA DEL FLYER', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.blue.withOpacity(0.3)),
                      ),
                      child: SelectableText(
                        promoState.generatedFlyer,
                        style: const TextStyle(height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _shareWhatsApp(promoState.generatedFlyer),
                      icon: const Icon(LucideIcons.share2),
                      label: const Text('ENVIAR POR WHATSAPP'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
