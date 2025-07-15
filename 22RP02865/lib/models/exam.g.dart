// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExamAdapter extends TypeAdapter<Exam> {
  @override
  final int typeId = 7;

  @override
  Exam read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Exam(
      id: fields[0] as String,
      name: fields[1] as String,
      subject: fields[2] as String,
      examDate: fields[3] as DateTime,
      location: fields[4] as String?,
      notes: fields[5] as String?,
      priority: fields[6] as ExamPriority,
      isCompleted: fields[7] as bool,
      createdAt: fields[8] as DateTime?,
      topics: (fields[9] as List).cast<String>(),
      studyHoursPlanned: fields[10] as int,
      studyHoursCompleted: fields[11] as int,
      result: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Exam obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.subject)
      ..writeByte(3)
      ..write(obj.examDate)
      ..writeByte(4)
      ..write(obj.location)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.priority)
      ..writeByte(7)
      ..write(obj.isCompleted)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.topics)
      ..writeByte(10)
      ..write(obj.studyHoursPlanned)
      ..writeByte(11)
      ..write(obj.studyHoursCompleted)
      ..writeByte(12)
      ..write(obj.result);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExamPriorityAdapter extends TypeAdapter<ExamPriority> {
  @override
  final int typeId = 8;

  @override
  ExamPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExamPriority.low;
      case 1:
        return ExamPriority.medium;
      case 2:
        return ExamPriority.high;
      case 3:
        return ExamPriority.critical;
      default:
        return ExamPriority.low;
    }
  }

  @override
  void write(BinaryWriter writer, ExamPriority obj) {
    switch (obj) {
      case ExamPriority.low:
        writer.writeByte(0);
        break;
      case ExamPriority.medium:
        writer.writeByte(1);
        break;
      case ExamPriority.high:
        writer.writeByte(2);
        break;
      case ExamPriority.critical:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
