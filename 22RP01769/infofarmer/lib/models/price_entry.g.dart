// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PriceEntryAdapter extends TypeAdapter<PriceEntry> {
  @override
  final int typeId = 3;

  @override
  PriceEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PriceEntry(
      itemName: fields[0] as String,
      unit: fields[1] as String,
      marketName: fields[2] as String,
      priceMin: fields[3] as double,
      priceMax: fields[4] as double,
      priceAvg: fields[5] as double,
      date: fields[6] as DateTime,
      source: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PriceEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.itemName)
      ..writeByte(1)
      ..write(obj.unit)
      ..writeByte(2)
      ..write(obj.marketName)
      ..writeByte(3)
      ..write(obj.priceMin)
      ..writeByte(4)
      ..write(obj.priceMax)
      ..writeByte(5)
      ..write(obj.priceAvg)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.source);
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
