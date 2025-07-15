import 'package:hive/hive.dart';
import '../services/hive_service.dart';

part 'exam.g.dart';

@HiveType(typeId: 7)
class Exam extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String subject;

  @HiveField(3)
  DateTime examDate;

  @HiveField(4)
  String? location;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  ExamPriority priority;

  @HiveField(7)
  bool isCompleted;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  List<String> topics;

  @HiveField(10)
  int studyHoursPlanned;

  @HiveField(11)
  int studyHoursCompleted;

  @HiveField(12)
  String? result;

  Exam({
    required this.id,
    required this.name,
    required this.subject,
    required this.examDate,
    this.location,
    this.notes,
    this.priority = ExamPriority.medium,
    this.isCompleted = false,
    DateTime? createdAt,
    this.topics = const [],
    this.studyHoursPlanned = 0,
    this.studyHoursCompleted = 0,
    this.result,
  }) : createdAt = createdAt ?? DateTime.now();

  // Calculate days remaining until exam
  int get daysRemaining {
    final now = DateTime.now();
    final difference = examDate.difference(now);
    return difference.inDays;
  }

  // Calculate hours remaining until exam
  int get hoursRemaining {
    final now = DateTime.now();
    final difference = examDate.difference(now);
    return difference.inHours;
  }

  // Check if exam is today
  bool get isToday {
    final now = DateTime.now();
    return examDate.year == now.year &&
           examDate.month == now.month &&
           examDate.day == now.day;
  }

  // Check if exam is tomorrow
  bool get isTomorrow {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    return examDate.year == tomorrow.year &&
           examDate.month == tomorrow.month &&
           examDate.day == tomorrow.day;
  }

  // Check if exam is overdue
  bool get isOverdue {
    return DateTime.now().isAfter(examDate) && !isCompleted;
  }

  // Check if exam is upcoming (within 7 days)
  bool get isUpcoming {
    return daysRemaining <= 7 && daysRemaining > 0;
  }

  // Calculate study progress percentage
  double get studyProgress {
    if (studyHoursPlanned == 0) return 0.0;
    return (studyHoursCompleted / studyHoursPlanned) * 100;
  }

  // Get urgency level
  String get urgencyLevel {
    if (isOverdue) return 'Overdue';
    if (isToday) return 'Today';
    if (isTomorrow) return 'Tomorrow';
    if (daysRemaining <= 3) return 'Critical';
    if (daysRemaining <= 7) return 'High';
    if (daysRemaining <= 14) return 'Medium';
    return 'Low';
  }

  // Get urgency color
  int get urgencyColor {
    switch (urgencyLevel) {
      case 'Overdue':
        return 0xFFFF6B6B; // Red
      case 'Today':
        return 0xFFFF6B6B; // Red
      case 'Tomorrow':
        return 0xFFFFA726; // Orange
      case 'Critical':
        return 0xFFFFA726; // Orange
      case 'High':
        return 0xFFFFB74D; // Light Orange
      case 'Medium':
        return 0xFFFFD54F; // Yellow
      case 'Low':
        return 0xFF66BB6A; // Green
      default:
        return 0xFF66BB6A; // Green
    }
  }

  // Get formatted countdown string
  String get countdownString {
    if (isOverdue) return 'Overdue';
    if (isToday) return 'Today';
    if (isTomorrow) return 'Tomorrow';
    
    if (daysRemaining > 0) {
      return '$daysRemaining days';
    } else {
      return '${hoursRemaining} hours';
    }
  }

  // Mark exam as completed
  void markCompleted({String? result}) {
    isCompleted = true;
    this.result = result;
  }

  // Add study hours
  void addStudyHours(int hours) {
    studyHoursCompleted += hours;
  }

  // Get priority string
  String get priorityString {
    switch (priority) {
      case ExamPriority.low:
        return 'Low';
      case ExamPriority.medium:
        return 'Medium';
      case ExamPriority.high:
        return 'High';
      case ExamPriority.critical:
        return 'Critical';
    }
  }

  // Get priority color
  int get priorityColor {
    switch (priority) {
      case ExamPriority.low:
        return 0xFF66BB6A; // Green
      case ExamPriority.medium:
        return 0xFFFFD54F; // Yellow
      case ExamPriority.high:
        return 0xFFFFA726; // Orange
      case ExamPriority.critical:
        return 0xFFFF6B6B; // Red
    }
  }
}

@HiveType(typeId: 8)
enum ExamPriority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
  @HiveField(3)
  critical,
}

class ExamService {
  static final ExamService _instance = ExamService._internal();
  factory ExamService() => _instance;
  ExamService._internal();

  // Create a new exam
  Future<Exam> createExam({
    required String name,
    required String subject,
    required DateTime examDate,
    String? location,
    String? notes,
    ExamPriority priority = ExamPriority.medium,
    List<String> topics = const [],
    int studyHoursPlanned = 0,
  }) async {
    final exam = Exam(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      subject: subject,
      examDate: examDate,
      location: location,
      notes: notes,
      priority: priority,
      topics: topics,
      studyHoursPlanned: studyHoursPlanned,
    );

    final box = await HiveService().getExamsBox();
    await box.put(exam.id, exam);
    return exam;
  }

  // Get all exams
  Future<List<Exam>> getAllExams() async {
    final box = await HiveService().getExamsBox();
    return box.values.toList();
  }

  // Get upcoming exams
  Future<List<Exam>> getUpcomingExams() async {
    final box = await HiveService().getExamsBox();
    return box.values
        .where((exam) => !exam.isCompleted && !exam.isOverdue)
        .toList()
      ..sort((a, b) => a.examDate.compareTo(b.examDate));
  }

  // Get overdue exams
  Future<List<Exam>> getOverdueExams() async {
    final box = await HiveService().getExamsBox();
    return box.values
        .where((exam) => exam.isOverdue)
        .toList()
      ..sort((a, b) => a.examDate.compareTo(b.examDate));
  }

  // Get exams by subject
  Future<List<Exam>> getExamsBySubject(String subject) async {
    final box = await HiveService().getExamsBox();
    return box.values
        .where((exam) => exam.subject == subject)
        .toList()
      ..sort((a, b) => a.examDate.compareTo(b.examDate));
  }

  // Get exams by priority
  Future<List<Exam>> getExamsByPriority(ExamPriority priority) async {
    final box = await HiveService().getExamsBox();
    return box.values
        .where((exam) => exam.priority == priority)
        .toList()
      ..sort((a, b) => a.examDate.compareTo(b.examDate));
  }

  // Get critical exams (within 3 days)
  Future<List<Exam>> getCriticalExams() async {
    final box = await HiveService().getExamsBox();
    return box.values
        .where((exam) => !exam.isCompleted && exam.daysRemaining <= 3)
        .toList()
      ..sort((a, b) => a.examDate.compareTo(b.examDate));
  }

  // Update exam
  Future<void> updateExam(Exam exam) async {
    final box = await HiveService().getExamsBox();
    await box.put(exam.id, exam);
  }

  // Delete exam
  Future<void> deleteExam(String examId) async {
    final box = await HiveService().getExamsBox();
    await box.delete(examId);
  }

  // Mark exam as completed
  Future<void> markExamCompleted(String examId, {String? result}) async {
    final box = await HiveService().getExamsBox();
    final exam = box.get(examId);
    if (exam != null) {
      exam.markCompleted(result: result);
      await box.put(examId, exam);
    }
  }

  // Add study hours to exam
  Future<void> addStudyHours(String examId, int hours) async {
    final box = await HiveService().getExamsBox();
    final exam = box.get(examId);
    if (exam != null) {
      exam.addStudyHours(hours);
      await box.put(examId, exam);
    }
  }

  // Get exam statistics
  Future<Map<String, dynamic>> getExamStats() async {
    final box = await HiveService().getExamsBox();
    final exams = box.values.toList();
    
    final totalExams = exams.length;
    final completedExams = exams.where((exam) => exam.isCompleted).length;
    final upcomingExams = exams.where((exam) => exam.isUpcoming).length;
    final overdueExams = exams.where((exam) => exam.isOverdue).length;
    final criticalExams = exams.where((exam) => exam.daysRemaining <= 3 && !exam.isCompleted).length;
    
    final totalStudyHoursPlanned = exams.fold(0, (sum, exam) => sum + exam.studyHoursPlanned);
    final totalStudyHoursCompleted = exams.fold(0, (sum, exam) => sum + exam.studyHoursCompleted);
    
    return {
      'totalExams': totalExams,
      'completedExams': completedExams,
      'upcomingExams': upcomingExams,
      'overdueExams': overdueExams,
      'criticalExams': criticalExams,
      'totalStudyHoursPlanned': totalStudyHoursPlanned,
      'totalStudyHoursCompleted': totalStudyHoursCompleted,
      'studyProgress': totalStudyHoursPlanned > 0 ? (totalStudyHoursCompleted / totalStudyHoursPlanned) * 100 : 0,
    };
  }

  // Get next exam
  Future<Exam?> getNextExam() async {
    final upcomingExams = await getUpcomingExams();
    return upcomingExams.isNotEmpty ? upcomingExams.first : null;
  }

  // Search exams
  Future<List<Exam>> searchExams(String query) async {
    final box = await HiveService().getExamsBox();
    final queryLower = query.toLowerCase();
    return box.values.where((exam) =>
      exam.name.toLowerCase().contains(queryLower) ||
      exam.subject.toLowerCase().contains(queryLower) ||
      (exam.notes?.toLowerCase().contains(queryLower) ?? false) ||
      (exam.location?.toLowerCase().contains(queryLower) ?? false)
    ).toList();
  }
} 