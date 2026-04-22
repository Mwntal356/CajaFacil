// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShiftAdapter extends TypeAdapter<Shift> {
  @override
  final int typeId = 10;

  @override
  Shift read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Shift(
      userId: fields[0] as String,
      startTime: fields[1] as DateTime,
      openingBalance: (fields[3] as double?) ?? 0.0,
      endTime: fields[2] as DateTime?,
      closingBalance: fields[4] as double?,
      isOpen: fields[5] as bool,
      salesTotal: (fields[6] as double?) ?? 0.0,
      expensesTotal: (fields[7] as double?) ?? 0.0,
    );
  }

  @override
  void write(BinaryWriter writer, Shift obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.openingBalance)
      ..writeByte(4)
      ..write(obj.closingBalance)
      ..writeByte(5)
      ..write(obj.isOpen)
      ..writeByte(6)
      ..write(obj.salesTotal)
      ..writeByte(7)
      ..write(obj.expensesTotal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
