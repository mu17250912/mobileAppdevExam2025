import 'package:hive/hive.dart';

part 'study_goal.g.dart';

@HiveType(typeId: 1)
class StudyGoal extends HiveObject {
  @HiveField(0)
  int dailyMinutes;

  @HiveField(1)
  int weeklyMinutes;

  StudyGoal({required this.dailyMinutes, required this.weeklyMinutes});
} 