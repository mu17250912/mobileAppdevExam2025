import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Skill {
  final String id;
  final String name;
  final String description;
  final String category;
  final String difficulty;
  final List<String> tags;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int rating;
  final int totalSessions;
  final List<String> prerequisites;
  final String location;
  final String availability;
  final double hourlyRate;
  final List<String> languages;
  final Map<String, dynamic> metadata;

  Skill({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.tags,
    required this.userId,
    required this.userName,
    this.userPhotoUrl = '',
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.rating = 0,
    this.totalSessions = 0,
    this.prerequisites = const [],
    this.location = '',
    this.availability = 'Available',
    this.hourlyRate = 0.0,
    this.languages = const ['English'],
    this.metadata = const {},
  });

  // Create from Firestore document
  factory Skill.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Skill(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Other',
      difficulty: data['difficulty'] ?? 'Beginner',
      tags: List<String>.from(data['tags'] ?? []),
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      rating: data['rating'] ?? 0,
      totalSessions: data['totalSessions'] ?? 0,
      prerequisites: List<String>.from(data['prerequisites'] ?? []),
      location: data['location'] ?? '',
      availability: data['availability'] ?? 'Available',
      hourlyRate: (data['hourlyRate'] ?? 0.0).toDouble(),
      languages: List<String>.from(data['languages'] ?? ['English']),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'tags': tags,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'rating': rating,
      'totalSessions': totalSessions,
      'prerequisites': prerequisites,
      'location': location,
      'availability': availability,
      'hourlyRate': hourlyRate,
      'languages': languages,
      'metadata': metadata,
    };
  }

  // Create a copy with updated fields
  Skill copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? difficulty,
    List<String>? tags,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? rating,
    int? totalSessions,
    List<String>? prerequisites,
    String? location,
    String? availability,
    double? hourlyRate,
    List<String>? languages,
    Map<String, dynamic>? metadata,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      rating: rating ?? this.rating,
      totalSessions: totalSessions ?? this.totalSessions,
      prerequisites: prerequisites ?? this.prerequisites,
      location: location ?? this.location,
      availability: availability ?? this.availability,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      languages: languages ?? this.languages,
      metadata: metadata ?? this.metadata,
    );
  }

  // Get difficulty color
  Color get difficultyColor {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      case 'expert':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // Get category icon
  IconData get categoryIcon {
    switch (category.toLowerCase()) {
      case 'programming':
        return Icons.code;
      case 'design':
        return Icons.design_services;
      case 'language':
        return Icons.language;
      case 'music':
        return Icons.music_note;
      case 'cooking':
        return Icons.restaurant;
      case 'fitness':
        return Icons.fitness_center;
      case 'art':
        return Icons.brush;
      case 'business':
        return Icons.business;
      case 'technology':
        return Icons.computer;
      default:
        return Icons.school;
    }
  }

  // Check if skill matches search query
  bool matchesSearch(String query) {
    final lowercaseQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowercaseQuery) ||
        description.toLowerCase().contains(lowercaseQuery) ||
        category.toLowerCase().contains(lowercaseQuery) ||
        tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
  }

  // Get formatted hourly rate
  String get formattedHourlyRate {
    if (hourlyRate == 0.0) return 'Free';
    return '\$${hourlyRate.toStringAsFixed(2)}/hr';
  }

  // Get average rating
  double get averageRating {
    return totalSessions > 0 ? rating / totalSessions : 0.0;
  }

  // Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  String toString() {
    return 'Skill(id: $id, name: $name, category: $category, difficulty: $difficulty)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Skill && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Skill categories
class SkillCategories {
  static const List<String> categories = [
    'Programming',
    'Design',
    'Language',
    'Music',
    'Cooking',
    'Fitness',
    'Art',
    'Business',
    'Technology',
    'Education',
    'Health',
    'Sports',
    'Other',
  ];

  static const List<String> difficulties = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Expert',
  ];
}

// Skill statistics
class SkillStats {
  final int totalSkills;
  final int activeSkills;
  final int completedSessions;
  final double averageRating;
  final Map<String, int> categoryDistribution;

  SkillStats({
    required this.totalSkills,
    required this.activeSkills,
    required this.completedSessions,
    required this.averageRating,
    required this.categoryDistribution,
  });

  factory SkillStats.empty() {
    return SkillStats(
      totalSkills: 0,
      activeSkills: 0,
      completedSessions: 0,
      averageRating: 0.0,
      categoryDistribution: {},
    );
  }
}
