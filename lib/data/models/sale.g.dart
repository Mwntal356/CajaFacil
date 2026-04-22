// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SaleAdapter extends TypeAdapter<Sale> {
  @override
  final int typeId = 1;

  @override
  Sale read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Sale(
      date: fields[0] as DateTime,
      products: (fields[1] as List).cast<SoldProduct>(),
      total: fields[2] as double,
      paymentMethod: fields[3] as String,
      totalUtility: fields[4] as double,
      isCancelled: fields[5] as bool?,
      cancelledBy: fields[6] as String?,
      shiftKey: fields[7] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Sale obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.products)
      ..writeByte(2)
      ..write(obj.total)
      ..writeByte(3)
      ..write(obj.paymentMethod)
      ..writeByte(4)
      ..write(obj.totalUtility)
      ..writeByte(5)
      ..write(obj.isCancelled)
      ..writeByte(6)
      ..write(obj.cancelledBy)
      ..writeByte(7)
      ..write(obj.shiftKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SoldProductAdapter extends TypeAdapter<SoldProduct> {
  @override
  final int typeId = 2;

  @override
  SoldProduct read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SoldProduct(
      productName: fields[0] as String,
      quantity: fields[1] as double,
      priceAtSale: fields[2] as double,
      utilityAtSale: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, SoldProduct obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.productName)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.priceAtSale)
      ..writeByte(3)
      ..write(obj.utilityAtSale);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SoldProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
