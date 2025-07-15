// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hourly_forecast.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HourlyForecastAdapter extends TypeAdapter<HourlyForecast> {
  @override
  final int typeId = 1;

  @override
  HourlyForecast read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HourlyForecast(
      time: fields[0] as DateTime,
      temp: fields[1] as double,
      icon: fields[2] as String,
      rain: fields[3] as double,
      wind: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, HourlyForecast obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.time)
      ..writeByte(1)
      ..write(obj.temp)
      ..writeByte(2)
      ..write(obj.icon)
      ..writeByte(3)
      ..write(obj.rain)
      ..writeByte(4)
      ..write(obj.wind);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HourlyForecastAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
