class EventModel {
  final String id;
  final String title;
  final String description;
  final String eventType; // wedding, celebration, faith_based
  final DateTime eventDate;
  final String location;
  final String organizerId;
  final String organizerName;
  final List<String>? images;
  final int guestCount;
  final double budget;
  final String status; // planning, confirmed, completed, cancelled
  final List<String>? serviceProviders; // List of service provider IDs
  final Map<String, dynamic>? requirements;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.eventType,
    required this.eventDate,
    required this.location,
    required this.organizerId,
    required this.organizerName,
    this.images,
    required this.guestCount,
    required this.budget,
    required this.status,
    this.serviceProviders,
    this.requirements,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      eventType: json['eventType'] ?? '',
      eventDate: DateTime.parse(json['eventDate']),
      location: json['location'] ?? '',
      organizerId: json['organizerId'] ?? '',
      organizerName: json['organizerName'] ?? '',
      images: json['images'] != null 
          ? List<String>.from(json['images']) 
          : null,
      guestCount: json['guestCount'] ?? 0,
      budget: (json['budget'] ?? 0).toDouble(),
      status: json['status'] ?? 'planning',
      serviceProviders: json['serviceProviders'] != null 
          ? List<String>.from(json['serviceProviders']) 
          : null,
      requirements: json['requirements'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'eventType': eventType,
      'eventDate': eventDate.toIso8601String(),
      'location': location,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'images': images,
      'guestCount': guestCount,
      'budget': budget,
      'status': status,
      'serviceProviders': serviceProviders,
      'requirements': requirements,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? eventType,
    DateTime? eventDate,
    String? location,
    String? organizerId,
    String? organizerName,
    List<String>? images,
    int? guestCount,
    double? budget,
    String? status,
    List<String>? serviceProviders,
    Map<String, dynamic>? requirements,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      eventDate: eventDate ?? this.eventDate,
      location: location ?? this.location,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      images: images ?? this.images,
      guestCount: guestCount ?? this.guestCount,
      budget: budget ?? this.budget,
      status: status ?? this.status,
      serviceProviders: serviceProviders ?? this.serviceProviders,
      requirements: requirements ?? this.requirements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isWedding => eventType == 'wedding';
  bool get isCelebration => eventType == 'celebration';
  bool get isFaithBased => eventType == 'faith_based';
  bool get isPlanning => status == 'planning';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
} 