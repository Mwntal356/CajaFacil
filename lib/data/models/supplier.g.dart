// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SupplierAdapter extends TypeAdapter<Supplier> {
  @override
  final int typeId = 7;

  @override
  Supplier read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Supplier(
      name: fields[0] as String,
      contactName: fields[1] as String?,
      phone: fields[2] as String?,
      note: fields[3] as String?,
      purchases: (fields[4] as List?)?.cast<SupplierPurchase>(),
    );
  }

  @override
  void write(BinaryWriter writer, Supplier obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.contactName)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.purchases);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupplierAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SupplierPurchaseAdapter extends TypeAdapter<SupplierPurchase> {
  @override
  final int typeId = 8;

  @override
  SupplierPurchase read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SupplierPurchase(
      date: fields[0] as DateTime,
      amount: fields[1] as double,
      ticketPhotos: (fields[2] as List).cast<String>(),
      description: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SupplierPurchase obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.ticketPhotos)
      ..writeByte(3)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupplierPurchaseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
