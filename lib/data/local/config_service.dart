import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/business_config.dart';

class ConfigService {
  final Box<BusinessConfig> _configBox;

  ConfigService(this._configBox);

  // Obtener la configuración actual
  BusinessConfig getConfig() {
    return _configBox.get('current') ?? BusinessConfig(name: 'Mi Negocio');
  }

  // Guardar configuración
  Future<void> saveConfig(BusinessConfig config) async {
    await _configBox.put('current', config);
  }

  // Lógica para subir y persistir el logo
  Future<String?> pickAndSaveLogo(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );

    if (image == null) return null;

    // Copiar la imagen a la carpeta de documentos de la app para que persista
    final directory = await getApplicationDocumentsDirectory();
    final String fileName = 'business_logo${p.extension(image.path)}';
    final String localPath = p.join(directory.path, fileName);
    
    final File localImage = await File(image.path).copy(localPath);
    
    return localImage.path;
  }
}
