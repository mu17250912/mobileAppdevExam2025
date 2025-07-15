import 'package:hive/hive.dart';
part 'tip.g.dart';

@HiveType(typeId: 4)
class Tip {
  @HiveField(0)
  String crop;
  @HiveField(1)
  String category;
  @HiveField(2)
  String title;
  @HiveField(3)
  String description;

  Tip({
    required this.crop,
    required this.category,
    required this.title,
    required this.description,
  });
} 