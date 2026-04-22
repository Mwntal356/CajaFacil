// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CostEntryAdapter extends TypeAdapter<CostEntry> {
  @override
  final int typeId = 5;

  @override
  CostEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CostEntry(
      date: fields[0] as DateTime,
      quantity: fields[1] as double,
      cost: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CostEntry obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.cost);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CostEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PriceEntryAdapter extends TypeAdapter<PriceEntry> {
  @override
  final int typeId = 6;

  @override
  PriceEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PriceEntry(
      date: fields[0] as DateTime,
      price: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, PriceEntry obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.price);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 0;

  @override
  Product read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Product(
      nombre: fields[0] as String,
      aliases: (fields[1] as List).cast<String>(),
      categoria: fields[2] as String,
      unidadMedida: fields[3] as String,
      existencias: fields[4] as double,
      precioCosto: fields[5] as double,
      precioVenta: fields[6] as double,
      fotoPath: fields[7] as String?,
      barcode: fields[10] as String?,
      stockMinimo: (fields[11] as double?) ?? 5.0,
      costHistory: (fields[8] as List?)?.cast<CostEntry>(),
      priceHistory: (fields[9] as List?)?.cast<PriceEntry>(),
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.nombre)
      ..writeByte(1)
      ..write(obj.aliases)
      ..writeByte(2)
      ..write(obj.categoria)
      ..writeByte(3)
      ..write(obj.unidadMedida)
      ..writeByte(4)
      ..write(obj.existencias)
      ..writeByte(5)
      ..write(obj.precioCosto)
      ..writeByte(6)
      ..write(obj.precioVenta)
      ..writeByte(7)
      ..write(obj.fotoPath)
      ..writeByte(8)
      ..write(obj.costHistory)
      ..writeByte(9)
      ..write(obj.priceHistory)
      ..writeByte(10)
      ..write(obj.barcode)
      ..writeByte(11)
      ..write(obj.stockMinimo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
