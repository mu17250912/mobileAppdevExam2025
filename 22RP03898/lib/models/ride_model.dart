import 'package:cloud_firestore/cloud_firestore.dart';

enum RideStatus { scheduled, inProgress, completed, cancelled }

enum VehicleType { bus, minibus, moto, car, truck }

class Location {
  final String name;
  final double latitude;
  final double longitude;
  final String? address;

  Location({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      name: map['name'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      address: map['address'],
    );
  }
}

class RideModel {
  final String id;
  final String driverId;
  final String driverName;
  final String? driverPhone;
  final String? driverImage;
  final double? driverRating;
  final Location origin;
  final Location destination;
  final DateTime departureTime;
  final DateTime? arrivalTime;
  final VehicleType vehicleType;
  final String? vehicleNumber;
  final int totalSeats;
  final int availableSeats;
  final double price;
  final String currency;
  final RideStatus status;
  final String? description;
  final List<String> amenities;
  final Map<String, dynamic> rules;
  final bool isPremium;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> bookedUsers;
  final String? notes;
  final bool isVerified;
  final Map<String, dynamic> metadata;
  final int? reportCount;

  /// Getter for fare (alias for price)
  double get fare => price;

  RideModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    this.driverPhone,
    this.driverImage,
    this.driverRating,
    required this.origin,
    required this.destination,
    required this.departureTime,
    this.arrivalTime,
    required this.vehicleType,
    this.vehicleNumber,
    required this.totalSeats,
    required this.availableSeats,
    required this.price,
    this.currency = 'NGN',
    this.status = RideStatus.scheduled,
    this.description,
    this.amenities = const [],
    this.rules = const {},
    this.isPremium = false,
    required this.createdAt,
    required this.updatedAt,
    this.bookedUsers = const [],
    this.notes,
    this.isVerified = false,
    this.metadata = const {},
    this.reportCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverImage': driverImage,
      'driverRating': driverRating,
      'origin': origin.toMap(),
      'destination': destination.toMap(),
      'departureTime': departureTime.toIso8601String(),
      'arrivalTime': arrivalTime?.toIso8601String(),
      'vehicleType': vehicleType.name,
      'vehicleNumber': vehicleNumber,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'price': price,
      'currency': currency,
      'status': status.name,
      'description': description,
      'amenities': amenities,
      'rules': rules,
      'isPremium': isPremium,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'bookedUsers': bookedUsers,
      'notes': notes,
      'isVerified': isVerified,
      'metadata': metadata,
      'reportCount': reportCount,
    };
  }

  factory RideModel.fromMap(Map<String, dynamic> map) {
    return RideModel(
      id: map['id'] ?? '',
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      driverPhone: map['driverPhone'],
      driverImage: map['driverImage'],
      driverRating: map['driverRating']?.toDouble(),
      origin: Location.fromMap(map['origin'] ?? {}),
      destination: Location.fromMap(map['destination'] ?? {}),
      departureTime: _parseDateTime(map['departureTime']),
      arrivalTime: map['arrivalTime'] != null
          ? _parseDateTime(map['arrivalTime'])
          : null,
      vehicleType: VehicleType.values.firstWhere(
        (e) => e.name == map['vehicleType'],
        orElse: () => VehicleType.bus,
      ),
      vehicleNumber: map['vehicleNumber'],
      totalSeats: map['totalSeats'] ?? 0,
      availableSeats: map['availableSeats'] ?? 0,
      price: map['price']?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'FRW',
      status: RideStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RideStatus.scheduled,
      ),
      description: map['description'],
      amenities: List<String>.from(map['amenities'] ?? []),
      rules: Map<String, dynamic>.from(map['rules'] ?? {}),
      isPremium: map['isPremium'] ?? false,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      bookedUsers: List<String>.from(map['bookedUsers'] ?? []),
      notes: map['notes'],
      isVerified: map['isVerified'] ?? false,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      reportCount: map['reportCount'],
    );
  }

  factory RideModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RideModel.fromMap({...data, 'id': doc.id});
  }

  RideModel copyWith({
    String? id,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? driverImage,
    double? driverRating,
    Location? origin,
    Location? destination,
    DateTime? departureTime,
    DateTime? arrivalTime,
    VehicleType? vehicleType,
    String? vehicleNumber,
    int? totalSeats,
    int? availableSeats,
    double? price,
    String? currency,
    RideStatus? status,
    String? description,
    List<String>? amenities,
    Map<String, dynamic>? rules,
    bool? isPremium,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? bookedUsers,
    String? notes,
    bool? isVerified,
    Map<String, dynamic>? metadata,
    int? reportCount,
  }) {
    return RideModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverImage: driverImage ?? this.driverImage,
      driverRating: driverRating ?? this.driverRating,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      totalSeats: totalSeats ?? this.totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      description: description ?? this.description,
      amenities: amenities ?? this.amenities,
      rules: rules ?? this.rules,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bookedUsers: bookedUsers ?? this.bookedUsers,
      notes: notes ?? this.notes,
      isVerified: isVerified ?? this.isVerified,
      metadata: metadata ?? this.metadata,
      reportCount: reportCount ?? this.reportCount,
    );
  }

  bool get isAvailable => availableSeats > 0 && status == RideStatus.scheduled;
  bool get isFull => availableSeats == 0;
  bool get isUpcoming => departureTime.isAfter(DateTime.now());
  bool get isToday =>
      departureTime.day == DateTime.now().day &&
      departureTime.month == DateTime.now().month &&
      departureTime.year == DateTime.now().year;

  String get vehicleTypeDisplay {
    switch (vehicleType) {
      case VehicleType.bus:
        return 'Bus';
      case VehicleType.minibus:
        return 'Minibus';
      case VehicleType.moto:
        return 'Moto Taxi';
      case VehicleType.car:
        return 'Car';
      case VehicleType.truck:
        return 'Truck';
    }
  }

  String get statusDisplay {
    switch (status) {
      case RideStatus.scheduled:
        return 'Scheduled';
      case RideStatus.inProgress:
        return 'In Progress';
      case RideStatus.completed:
        return 'Completed';
      case RideStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get formattedPrice {
    if (currency == 'FRW') {
      return '${price.toStringAsFixed(0)} FRW (\$${(price / 1000).toStringAsFixed(2)} USD)';
    } else {
      return '$currency ${price.toStringAsFixed(0)}';
    }
  }

  String get formattedDepartureTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final departureDate = DateTime(
      departureTime.year,
      departureTime.month,
      departureTime.day,
    );

    if (departureDate == today) {
      return 'Today at ${_formatTime(departureTime)}';
    } else if (departureDate == today.add(Duration(days: 1))) {
      return 'Tomorrow at ${_formatTime(departureTime)}';
    } else {
      return '${_formatDate(departureTime)} at ${_formatTime(departureTime)}';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  double get occupancyRate =>
      totalSeats > 0 ? (totalSeats - availableSeats) / totalSeats : 0.0;

  // Helper method to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}
