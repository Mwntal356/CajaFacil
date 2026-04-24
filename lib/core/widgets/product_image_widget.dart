import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';

class ProductImageWidget extends StatelessWidget {
  final String? fotoPath;
  final double size;
  final BoxFit fit;

  const ProductImageWidget(this.fotoPath, {super.key, this.size = double.infinity, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppColors.green.withOpacity(0.05),
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    if (fotoPath == null || fotoPath!.isEmpty) {
      return const Icon(LucideIcons.package, size: 40, color: AppColors.green);
    }

    if (fotoPath!.startsWith('http')) {
      return Image.network(
        fotoPath!,
        fit: fit,
        errorBuilder: (_, __, ___) => const Icon(LucideIcons.package, size: 40, color: AppColors.green),
      );
    }

    if (fotoPath!.startsWith('assets/')) {
      return Image.asset(
        fotoPath!,
        fit: fit,
        errorBuilder: (_, __, ___) => const Icon(LucideIcons.package, size: 40, color: AppColors.green),
      );
    }

    final file = File(fotoPath!);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: fit,
        errorBuilder: (_, __, ___) => const Icon(LucideIcons.package, size: 40, color: AppColors.green),
      );
    }

    return const Icon(LucideIcons.package, size: 40, color: AppColors.green);
  }
}
