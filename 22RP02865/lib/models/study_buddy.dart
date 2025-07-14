import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'study_buddy.g.dart';

@HiveType(typeId: 14)
class StudyBuddy extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String avatar;

  @HiveField(4)
  final DateTime addedAt;

  @HiveField(5)
  final DateTime lastInteraction;

  @HiveField(6)
  final List<Map<String, dynamic>> sharedGoals;

  @HiveField(7)
  final List<Map<String, dynamic>> sharedResources;

  StudyBuddy({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.addedAt,
    required this.lastInteraction,
    required this.sharedGoals,
    required this.sharedResources,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'addedAt': addedAt,
      'lastInteraction': lastInteraction,
      'sharedGoals': sharedGoals,
      'sharedResources': sharedResources,
    };
  }

  // Create from Map (from Firestore)
  factory StudyBuddy.fromMap(Map<String, dynamic> map, String id) {
    return StudyBuddy(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      avatar: map['avatar'] ?? '',
      addedAt: (map['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastInteraction: (map['lastInteraction'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sharedGoals: List<Map<String, dynamic>>.from(map['sharedGoals'] ?? []),
      sharedResources: List<Map<String, dynamic>>.from(map['sharedResources'] ?? []),
    );
  }

  // Copy with modifications
  StudyBuddy copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    DateTime? addedAt,
    DateTime? lastInteraction,
    List<Map<String, dynamic>>? sharedGoals,
    List<Map<String, dynamic>>? sharedResources,
  }) {
    return StudyBuddy(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      addedAt: addedAt ?? this.addedAt,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      sharedGoals: sharedGoals ?? this.sharedGoals,
      sharedResources: sharedResources ?? this.sharedResources,
    );
  }

  // Update last interaction
  StudyBuddy updateLastInteraction() {
    return copyWith(lastInteraction: DateTime.now());
  }

  // Add shared goal
  StudyBuddy addSharedGoal(String goalId, String goalTitle) {
    final newSharedGoals = List<Map<String, dynamic>>.from(sharedGoals);
    newSharedGoals.add({
      'goalId': goalId,
      'title': goalTitle,
      'sharedAt': DateTime.now(),
    });
    return copyWith(sharedGoals: newSharedGoals);
  }

  // Add shared resource
  StudyBuddy addSharedResource(String resourceId, String resourceTitle, String resourceType) {
    final newSharedResources = List<Map<String, dynamic>>.from(sharedResources);
    newSharedResources.add({
      'resourceId': resourceId,
      'title': resourceTitle,
      'type': resourceType,
      'sharedAt': DateTime.now(),
    });
    return copyWith(sharedResources: newSharedResources);
  }

  // Get formatted added time
  String get formattedAddedTime {
    final now = DateTime.now();
    final difference = now.difference(addedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  // Get formatted last interaction time
  String get formattedLastInteraction {
    final now = DateTime.now();
    final difference = now.difference(lastInteraction);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  // Get shared goals count
  int get sharedGoalsCount {
    return sharedGoals.length;
  }

  // Get shared resources count
  int get sharedResourcesCount {
    return sharedResources.length;
  }

  // Check if buddy has shared content
  bool get hasSharedContent {
    return sharedGoals.isNotEmpty || sharedResources.isNotEmpty;
  }

  // Get recent shared content
  List<Map<String, dynamic>> get recentSharedContent {
    final allContent = <Map<String, dynamic>>[];
    allContent.addAll(sharedGoals.map((goal) => {...goal, 'type': 'goal'}));
    allContent.addAll(sharedResources.map((resource) => {...resource, 'type': 'resource'}));
    
    allContent.sort((a, b) {
      final aTime = a['sharedAt'] as DateTime? ?? DateTime.now();
      final bTime = b['sharedAt'] as DateTime? ?? DateTime.now();
      return bTime.compareTo(aTime);
    });
    
    return allContent.take(5).toList();
  }
} 