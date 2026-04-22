// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_closing.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CashClosingAdapter extends TypeAdapter<CashClosing> {
  @override
  final int typeId = 9;

  @override
  CashClosing read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CashClosing(
      date: fields[0] as DateTime,
      openingBalance: fields[1] as double,
      salesEfectivo: fields[2] as double,
      salesTarjeta: fields[3] as double,
      expenses: fields[4] as double,
      expectedCash: fields[5] as double,
      actualCash: fields[6] as double,
      notes: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CashClosing obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.openingBalance)
      ..writeByte(2)
      ..write(obj.salesEfectivo)
      ..writeByte(3)
      ..write(obj.salesTarjeta)
      ..writeByte(4)
      ..write(obj.expenses)
      ..writeByte(5)
      ..write(obj.expectedCash)
      ..writeByte(6)
      ..write(obj.actualCash)
      ..writeByte(7)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CashClosingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
