import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/config_provider.dart';
import '../../../core/theme/app_theme.dart';

class DynamicLogo extends ConsumerWidget {
  final double size;

  const DynamicLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configProvider);
    final logoPath = config.logoPath;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
        border: Border.all(
          color: AppColors.green.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: logoPath != null && File(logoPath).existsSync()
            ? Image.file(
                File(logoPath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Icon(
      Icons.rocket_launch_rounded,
      size: 60,
      color: AppColors.green,
    );
  }
}
