import 'package:hive/hive.dart';
part 'daily_forecast.g.dart';

@HiveType(typeId: 0)
class DailyForecast {
  @HiveField(0)
  final DateTime date;
  @HiveField(1)
  final double temp;
  @HiveField(2)
  final double? minTemp;
  @HiveField(3)
  final double? maxTemp;
  @HiveField(4)
  final String icon;
  @HiveField(5)
  final double? rainChance;
  @HiveField(6)
  final double? wind;
  DailyForecast({
    required this.date,
    required this.temp,
    required this.icon,
    this.minTemp,
    this.maxTemp,
    this.rainChance,
    this.wind,
  });
} 