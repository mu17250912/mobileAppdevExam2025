import 'package:hive/hive.dart';

part 'achievement.g.dart';

@HiveType(typeId: 3)
class Achievement extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  String icon;

  @HiveField(4)
  AchievementType type;

  @HiveField(5)
  int targetValue;

  @HiveField(6)
  int currentValue;

  @HiveField(7)
  bool isUnlocked;

  @HiveField(8)
  DateTime? unlockedAt;

  @HiveField(9)
  int points;

  @HiveField(10)
  String? badgeImage;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.targetValue,
    this.currentValue = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    this.points = 0,
    this.badgeImage,
  });

  double get progress => targetValue > 0 ? currentValue / targetValue : 0.0;

  bool get isCompleted => currentValue >= targetValue;

  void increment() {
    currentValue++;
    if (isCompleted && !isUnlocked) {
      unlock();
    }
  }

  void unlock() {
    isUnlocked = true;
    unlockedAt = DateTime.now();
  }

  void reset() {
    currentValue = 0;
    isUnlocked = false;
    unlockedAt = null;
  }
}

@HiveType(typeId: 4)
enum AchievementType {
  @HiveField(0)
  studyStreak,
  @HiveField(1)
  totalHours,
  @HiveField(2)
  tasksCompleted,
  @HiveField(3)
  subjectsStudied,
  @HiveField(4)
  perfectWeek,
  @HiveField(5)
  earlyBird,
  @HiveField(6)
  nightOwl,
  @HiveField(7)
  marathon,
  @HiveField(8)
  consistency,
  @HiveField(9)
  speedster,
}

class AchievementService {
  static final List<Achievement> _defaultAchievements = [
    Achievement(
      id: 'first_task',
      title: 'First Steps',
      description: 'Complete your first study task',
      icon: '🎯',
      type: AchievementType.tasksCompleted,
      targetValue: 1,
      points: 10,
    ),
    Achievement(
      id: 'study_streak_3',
      title: 'Getting Started',
      description: 'Study for 3 days in a row',
      icon: '🔥',
      type: AchievementType.studyStreak,
      targetValue: 3,
      points: 25,
    ),
    Achievement(
      id: 'study_streak_7',
      title: 'Week Warrior',
      description: 'Study for 7 days in a row',
      icon: '⚡',
      type: AchievementType.studyStreak,
      targetValue: 7,
      points: 50,
    ),
    Achievement(
      id: 'study_streak_30',
      title: 'Consistency King',
      description: 'Study for 30 days in a row',
      icon: '👑',
      type: AchievementType.studyStreak,
      targetValue: 30,
      points: 200,
    ),
    Achievement(
      id: 'total_hours_10',
      title: 'Dedicated Learner',
      description: 'Study for 10 total hours',
      icon: '📚',
      type: AchievementType.totalHours,
      targetValue: 10,
      points: 30,
    ),
    Achievement(
      id: 'total_hours_50',
      title: 'Knowledge Seeker',
      description: 'Study for 50 total hours',
      icon: '🎓',
      type: AchievementType.totalHours,
      targetValue: 50,
      points: 100,
    ),
    Achievement(
      id: 'total_hours_100',
      title: 'Study Master',
      description: 'Study for 100 total hours',
      icon: '🏆',
      type: AchievementType.totalHours,
      targetValue: 100,
      points: 250,
    ),
    Achievement(
      id: 'tasks_completed_10',
      title: 'Task Master',
      description: 'Complete 10 study tasks',
      icon: '✅',
      type: AchievementType.tasksCompleted,
      targetValue: 10,
      points: 40,
    ),
    Achievement(
      id: 'tasks_completed_50',
      title: 'Productivity Pro',
      description: 'Complete 50 study tasks',
      icon: '🚀',
      type: AchievementType.tasksCompleted,
      targetValue: 50,
      points: 150,
    ),
    Achievement(
      id: 'subjects_5',
      title: 'Versatile Learner',
      description: 'Study 5 different subjects',
      icon: '🎨',
      type: AchievementType.subjectsStudied,
      targetValue: 5,
      points: 75,
    ),
    Achievement(
      id: 'perfect_week',
      title: 'Perfect Week',
      description: 'Complete all planned tasks in a week',
      icon: '⭐',
      type: AchievementType.perfectWeek,
      targetValue: 1,
      points: 100,
    ),
    Achievement(
      id: 'early_bird',
      title: 'Early Bird',
      description: 'Study before 8 AM for 5 days',
      icon: '🌅',
      type: AchievementType.earlyBird,
      targetValue: 5,
      points: 60,
    ),
    Achievement(
      id: 'night_owl',
      title: 'Night Owl',
      description: 'Study after 10 PM for 5 days',
      icon: '🦉',
      type: AchievementType.nightOwl,
      targetValue: 5,
      points: 60,
    ),
    Achievement(
      id: 'marathon_4',
      title: 'Study Marathon',
      description: 'Study for 4 hours in a single session',
      icon: '🏃',
      type: AchievementType.marathon,
      targetValue: 4,
      points: 80,
    ),
    Achievement(
      id: 'consistency_week',
      title: 'Consistent',
      description: 'Study every day for a week',
      icon: '📅',
      type: AchievementType.consistency,
      targetValue: 7,
      points: 90,
    ),
    Achievement(
      id: 'speedster',
      title: 'Speedster',
      description: 'Complete 5 tasks in one day',
      icon: '⚡',
      type: AchievementType.speedster,
      targetValue: 5,
      points: 70,
    ),
  ];

  static List<Achievement> getDefaultAchievements() {
    return _defaultAchievements.map((achievement) => Achievement(
      id: achievement.id,
      title: achievement.title,
      description: achievement.description,
      icon: achievement.icon,
      type: achievement.type,
      targetValue: achievement.targetValue,
      points: achievement.points,
    )).toList();
  }

  static Achievement? getAchievementById(String id) {
    try {
      return _defaultAchievements.firstWhere((achievement) => achievement.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<Achievement> getAchievementsByType(AchievementType type) {
    return _defaultAchievements.where((achievement) => achievement.type == type).toList();
  }
} 