// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disease.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DiseaseAdapter extends TypeAdapter<Disease> {
  @override
  final int typeId = 5;

  @override
  Disease read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Disease(
      name: fields[0] as String,
      imagePath: fields[1] as String,
      affectedCrops: (fields[2] as List).cast<String>(),
      symptoms: fields[3] as String,
      organicControl: fields[4] as String,
      chemicalControl: fields[5] as String,
      weatherTriggers: (fields[6] as List).cast<String>(),
      infoUrl: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Disease obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.imagePath)
      ..writeByte(2)
      ..write(obj.affectedCrops)
      ..writeByte(3)
      ..write(obj.symptoms)
      ..writeByte(4)
      ..write(obj.organicControl)
      ..writeByte(5)
      ..write(obj.chemicalControl)
      ..writeByte(6)
      ..write(obj.weatherTriggers)
      ..writeByte(7)
      ..write(obj.infoUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiseaseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
