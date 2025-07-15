// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tip.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TipAdapter extends TypeAdapter<Tip> {
  @override
  final int typeId = 4;

  @override
  Tip read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Tip(
      crop: fields[0] as String,
      category: fields[1] as String,
      title: fields[2] as String,
      description: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Tip obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.crop)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TipAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
