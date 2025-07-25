import 'package:hive/hive.dart';
part 'hourly_forecast.g.dart';

@HiveType(typeId: 1)
class HourlyForecast {
  @HiveField(0)
  final DateTime time;
  @HiveField(1)
  final double temp;
  @HiveField(2)
  final String icon;
  @HiveField(3)
  final double rain;
  @HiveField(4)
  final double wind;
  HourlyForecast({
    required this.time,
    required this.temp,
    required this.icon,
    required this.rain,
    required this.wind,
  });
} 