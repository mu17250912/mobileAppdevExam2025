import 'package:hive/hive.dart';
part 'disease.g.dart';

@HiveType(typeId: 5)
class Disease {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final String imagePath;
  @HiveField(2)
  final List<String> affectedCrops;
  @HiveField(3)
  final String symptoms;
  @HiveField(4)
  final String organicControl;
  @HiveField(5)
  final String chemicalControl;
  @HiveField(6)
  final List<String> weatherTriggers;
  @HiveField(7)
  final String infoUrl;

  Disease({
    required this.name,
    required this.imagePath,
    required this.affectedCrops,
    required this.symptoms,
    required this.organicControl,
    required this.chemicalControl,
    required this.weatherTriggers,
    required this.infoUrl,
  });
} 