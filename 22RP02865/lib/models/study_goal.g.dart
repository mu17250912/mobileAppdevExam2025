// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_goal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudyGoalAdapter extends TypeAdapter<StudyGoal> {
  @override
  final int typeId = 1;

  @override
  StudyGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudyGoal(
      dailyMinutes: fields[0] as int,
      weeklyMinutes: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, StudyGoal obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.dailyMinutes)
      ..writeByte(1)
      ..write(obj.weeklyMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
