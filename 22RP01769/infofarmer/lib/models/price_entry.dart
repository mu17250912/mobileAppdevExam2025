import 'package:hive/hive.dart';
part 'price_entry.g.dart';

@HiveType(typeId: 3)
class PriceEntry {
  @HiveField(0)
  final String itemName;
  @HiveField(1)
  final String unit;
  @HiveField(2)
  final String marketName;
  @HiveField(3)
  final double priceMin;
  @HiveField(4)
  final double priceMax;
  @HiveField(5)
  final double priceAvg;
  @HiveField(6)
  final DateTime date;
  @HiveField(7)
  final String? source;

  PriceEntry({
    required this.itemName,
    required this.unit,
    required this.marketName,
    required this.priceMin,
    required this.priceMax,
    required this.priceAvg,
    required this.date,
    this.source,
  });
} 