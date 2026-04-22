import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/business_config.dart';
import '../local/config_service.dart';
import '../../core/constants/app_constants.dart';

// Provider para la caja de Hive (inicializada en main)
final configBoxProvider = Provider<Box<BusinessConfig>>((ref) {
  return Hive.box<BusinessConfig>(AppConstants.settingsBox);
});

// Provider para el servicio de configuración
final configServiceProvider = Provider<ConfigService>((ref) {
  final box = ref.watch(configBoxProvider);
  return ConfigService(box);
});

// StateNotifier para manejar la configuración de forma reactiva
class ConfigNotifier extends StateNotifier<BusinessConfig> {
  final ConfigService _service;

  ConfigNotifier(this._service) : super(_service.getConfig());

  Future<void> updateLogo(String? path) async {
    final newState = state.copyWith(logoPath: path);
    await _service.saveConfig(newState);
    state = newState;
  }

  Future<void> updateName(String name) async {
    final newState = state.copyWith(name: name);
    await _service.saveConfig(newState);
    state = newState;
  }
}

final configProvider = StateNotifierProvider<ConfigNotifier, BusinessConfig>((ref) {
  final service = ref.watch(configServiceProvider);
  return ConfigNotifier(service);
});
