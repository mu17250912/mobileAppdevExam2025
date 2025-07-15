class BookingModel {
  final String id;
  final String userId;
  final String eventId;
  final String providerId;
  final String fullName;
  final String email;
  final String phone;
  final String serviceType;
  final DateTime preferredDate;
  final String preferredTime;
  final String additionalMessage;
  final String requirements;
  final String status;
  final double price;
  final String place;
  final String duration;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.providerId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.serviceType,
    required this.preferredDate,
    required this.preferredTime,
    required this.additionalMessage,
    required this.requirements,
    required this.status,
    required this.price,
    required this.place,
    required this.duration,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      eventId: json['eventId'] ?? '',
      providerId: json['providerId'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      serviceType: json['serviceType'] ?? '',
      preferredDate: DateTime.parse(json['preferredDate']),
      preferredTime: json['preferredTime'] ?? '',
      additionalMessage: json['additionalMessage'] ?? '',
      requirements: json['requirements'] ?? '',
      status: json['status'] ?? 'pending',
      price: (json['price'] ?? 0).toDouble(),
      place: json['place'] ?? '',
      duration: json['duration'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'eventId': eventId,
      'providerId': providerId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'serviceType': serviceType,
      'preferredDate': preferredDate.toIso8601String(),
      'preferredTime': preferredTime,
      'additionalMessage': additionalMessage,
      'requirements': requirements,
      'status': status,
      'price': price,
      'place': place,
      'duration': duration,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
} 