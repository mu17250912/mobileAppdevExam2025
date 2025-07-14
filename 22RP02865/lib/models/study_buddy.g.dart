// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_buddy.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudyBuddyAdapter extends TypeAdapter<StudyBuddy> {
  @override
  final int typeId = 14;

  @override
  StudyBuddy read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudyBuddy(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      avatar: fields[3] as String,
      addedAt: fields[4] as DateTime,
      lastInteraction: fields[5] as DateTime,
      sharedGoals: (fields[6] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      sharedResources: (fields[7] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
    );
  }

  @override
  void write(BinaryWriter writer, StudyBuddy obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.avatar)
      ..writeByte(4)
      ..write(obj.addedAt)
      ..writeByte(5)
      ..write(obj.lastInteraction)
      ..writeByte(6)
      ..write(obj.sharedGoals)
      ..writeByte(7)
      ..write(obj.sharedResources);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyBuddyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
