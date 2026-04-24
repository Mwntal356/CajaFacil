import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

class AssetManager {
  // Mapa en memoria para evitar consultas constantes al sistema de archivos
  static final Map<String, String> _imageCache = {};

  static String? getProductImagePath(String productName) {
    final fileName = productName.replaceAll(' ', '_') + '.jfif';
    final assetPath = 'assets/images/$fileName';
    return assetPath;
  }
}
