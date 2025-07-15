// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AchievementAdapter extends TypeAdapter<Achievement> {
  @override
  final int typeId = 3;

  @override
  Achievement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Achievement(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      icon: fields[3] as String,
      type: fields[4] as AchievementType,
      targetValue: fields[5] as int,
      currentValue: fields[6] as int,
      isUnlocked: fields[7] as bool,
      unlockedAt: fields[8] as DateTime?,
      points: fields[9] as int,
      badgeImage: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Achievement obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.icon)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.targetValue)
      ..writeByte(6)
      ..write(obj.currentValue)
      ..writeByte(7)
      ..write(obj.isUnlocked)
      ..writeByte(8)
      ..write(obj.unlockedAt)
      ..writeByte(9)
      ..write(obj.points)
      ..writeByte(10)
      ..write(obj.badgeImage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AchievementTypeAdapter extends TypeAdapter<AchievementType> {
  @override
  final int typeId = 4;

  @override
  AchievementType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AchievementType.studyStreak;
      case 1:
        return AchievementType.totalHours;
      case 2:
        return AchievementType.tasksCompleted;
      case 3:
        return AchievementType.subjectsStudied;
      case 4:
        return AchievementType.perfectWeek;
      case 5:
        return AchievementType.earlyBird;
      case 6:
        return AchievementType.nightOwl;
      case 7:
        return AchievementType.marathon;
      case 8:
        return AchievementType.consistency;
      case 9:
        return AchievementType.speedster;
      default:
        return AchievementType.studyStreak;
    }
  }

  @override
  void write(BinaryWriter writer, AchievementType obj) {
    switch (obj) {
      case AchievementType.studyStreak:
        writer.writeByte(0);
        break;
      case AchievementType.totalHours:
        writer.writeByte(1);
        break;
      case AchievementType.tasksCompleted:
        writer.writeByte(2);
        break;
      case AchievementType.subjectsStudied:
        writer.writeByte(3);
        break;
      case AchievementType.perfectWeek:
        writer.writeByte(4);
        break;
      case AchievementType.earlyBird:
        writer.writeByte(5);
        break;
      case AchievementType.nightOwl:
        writer.writeByte(6);
        break;
      case AchievementType.marathon:
        writer.writeByte(7);
        break;
      case AchievementType.consistency:
        writer.writeByte(8);
        break;
      case AchievementType.speedster:
        writer.writeByte(9);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
