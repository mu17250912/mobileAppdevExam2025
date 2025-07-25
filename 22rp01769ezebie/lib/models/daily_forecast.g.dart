// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_forecast.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyForecastAdapter extends TypeAdapter<DailyForecast> {
  @override
  final int typeId = 0;

  @override
  DailyForecast read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyForecast(
      date: fields[0] as DateTime,
      temp: fields[1] as double,
      icon: fields[4] as String,
      minTemp: fields[2] as double?,
      maxTemp: fields[3] as double?,
      rainChance: fields[5] as double?,
      wind: fields[6] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, DailyForecast obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.temp)
      ..writeByte(2)
      ..write(obj.minTemp)
      ..writeByte(3)
      ..write(obj.maxTemp)
      ..writeByte(4)
      ..write(obj.icon)
      ..writeByte(5)
      ..write(obj.rainChance)
      ..writeByte(6)
      ..write(obj.wind);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyForecastAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
