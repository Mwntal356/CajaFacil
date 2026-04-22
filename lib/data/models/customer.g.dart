// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomerAdapter extends TypeAdapter<Customer> {
  @override
  final int typeId = 9;

  @override
  Customer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Customer(
      name: fields[0] as String,
      phone: fields[1] as String?,
      debt: fields[2] as double,
      debtHistory: (fields[3] as List?)?.cast<DebtEntry>(),
    );
  }

  @override
  void write(BinaryWriter writer, Customer obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.phone)
      ..writeByte(2)
      ..write(obj.debt)
      ..writeByte(3)
      ..write(obj.debtHistory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DebtEntryAdapter extends TypeAdapter<DebtEntry> {
  @override
  final int typeId = 10;

  @override
  DebtEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DebtEntry(
      date: fields[0] as DateTime,
      amount: fields[1] as double,
      concept: fields[2] as String,
      isPayment: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DebtEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.concept)
      ..writeByte(3)
      ..write(obj.isPayment);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
