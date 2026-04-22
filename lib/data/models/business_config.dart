import 'package:hive/hive.dart';

part 'business_config.g.dart';

@HiveType(typeId: 3)
class BusinessConfig extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String? logoPath;

  BusinessConfig({
    required this.name,
    this.logoPath,
  });

  // Copia con cambios (útil para Riverpod)
  BusinessConfig copyWith({
    String? name,
    String? logoPath,
  }) {
    return BusinessConfig(
      name: name ?? this.name,
      logoPath: logoPath ?? this.logoPath,
    );
  }
}
