import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String organizerId;
  final String organizerName;
  final DateTime dateTime;
  final String location;
  final String? imageUrl;
  final int maxParticipants;
  final List<String> participants; // User IDs
  final List<String> categories; // e.g., ['study', 'meeting', 'social']
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status; // 'upcoming', 'ongoing', 'completed', 'cancelled'

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.organizerId,
    required this.organizerName,
    required this.dateTime,
    required this.location,
    this.imageUrl,
    required this.maxParticipants,
    this.participants = const [],
    this.categories = const [],
    this.isPrivate = false,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'upcoming',
  });

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      organizerId: map['organizerId'] ?? '',
      organizerName: map['organizerName'] ?? '',
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'],
      maxParticipants: map['maxParticipants'] ?? 0,
      participants: List<String>.from(map['participants'] ?? []),
      categories: List<String>.from(map['categories'] ?? []),
      isPrivate: map['isPrivate'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'upcoming',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'imageUrl': imageUrl,
      'maxParticipants': maxParticipants,
      'participants': participants,
      'categories': categories,
      'isPrivate': isPrivate,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': status,
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? organizerId,
    String? organizerName,
    DateTime? dateTime,
    String? location,
    String? imageUrl,
    int? maxParticipants,
    List<String>? participants,
    List<String>? categories,
    bool? isPrivate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      participants: participants ?? this.participants,
      categories: categories ?? this.categories,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }

  bool get isFull => participants.length >= maxParticipants;
  bool get isUpcoming => dateTime.isAfter(DateTime.now());
  bool get isOngoing => dateTime.isBefore(DateTime.now()) && 
                       dateTime.add(Duration(hours: 2)).isAfter(DateTime.now());
} 