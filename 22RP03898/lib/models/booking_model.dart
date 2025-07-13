import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saferide/models/payment_method.dart';

enum BookingStatus { pending, confirmed, cancelled, completed, noShow }

enum PaymentStatus { pending, paid, refunded, failed }

class BookingModel {
  final String id;
  final String rideId;
  final String passengerId;
  final String passengerName;
  final String? passengerPhone;
  final String? passengerImage;
  final String driverId;
  final String driverName;
  final String? driverPhone;
  final String? driverImage;
  final int seatsBooked;
  final double totalAmount;
  final String currency;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final PaymentMethod? paymentMethod;
  final DateTime bookingTime;
  final DateTime? confirmationTime;
  final DateTime? cancellationTime;
  final DateTime? completionTime;
  final String? pickupLocation;
  final String? dropoffLocation;
  final String? specialRequests;
  final String? cancellationReason;
  final double? rating;
  final String? review;
  final Map<String, dynamic> metadata;
  final bool isPremium;

  BookingModel({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.passengerName,
    this.passengerPhone,
    this.passengerImage,
    required this.driverId,
    required this.driverName,
    this.driverPhone,
    this.driverImage,
    required this.seatsBooked,
    required this.totalAmount,
    this.currency = 'FRW',
    this.status = BookingStatus.pending,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentMethod,
    required this.bookingTime,
    this.confirmationTime,
    this.cancellationTime,
    this.completionTime,
    this.pickupLocation,
    this.dropoffLocation,
    this.specialRequests,
    this.cancellationReason,
    this.rating,
    this.review,
    this.metadata = const {},
    this.isPremium = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rideId': rideId,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'passengerImage': passengerImage,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverImage': driverImage,
      'seatsBooked': seatsBooked,
      'totalAmount': totalAmount,
      'currency': currency,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'paymentMethod': paymentMethod?.name,
      'bookingTime': bookingTime.toIso8601String(),
      'confirmationTime': confirmationTime?.toIso8601String(),
      'cancellationTime': cancellationTime?.toIso8601String(),
      'completionTime': completionTime?.toIso8601String(),
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'specialRequests': specialRequests,
      'cancellationReason': cancellationReason,
      'rating': rating,
      'review': review,
      'metadata': metadata,
      'isPremium': isPremium,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] ?? '',
      rideId: map['rideId'] ?? '',
      passengerId: map['passengerId'] ?? '',
      passengerName: map['passengerName'] ?? '',
      passengerPhone: map['passengerPhone'],
      passengerImage: map['passengerImage'],
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      driverPhone: map['driverPhone'],
      driverImage: map['driverImage'],
      seatsBooked: map['seatsBooked'] ?? 0,
      totalAmount: map['totalAmount']?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'NGN',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BookingStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == map['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentMethod: map['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.name == map['paymentMethod'],
              orElse: () => PaymentMethod.cash,
            )
          : null,
      bookingTime: _parseDateTime(map['bookingTime']),
      confirmationTime: map['confirmationTime'] != null
          ? _parseDateTime(map['confirmationTime'])
          : null,
      cancellationTime: map['cancellationTime'] != null
          ? _parseDateTime(map['cancellationTime'])
          : null,
      completionTime: map['completionTime'] != null
          ? _parseDateTime(map['completionTime'])
          : null,
      pickupLocation: map['pickupLocation'],
      dropoffLocation: map['dropoffLocation'],
      specialRequests: map['specialRequests'],
      cancellationReason: map['cancellationReason'],
      rating: map['rating']?.toDouble(),
      review: map['review'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      isPremium: map['isPremium'] ?? false,
    );
  }

  factory BookingModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel.fromMap({...data, 'id': doc.id});
  }

  BookingModel copyWith({
    String? id,
    String? rideId,
    String? passengerId,
    String? passengerName,
    String? passengerPhone,
    String? passengerImage,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? driverImage,
    int? seatsBooked,
    double? totalAmount,
    String? currency,
    BookingStatus? status,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    DateTime? bookingTime,
    DateTime? confirmationTime,
    DateTime? cancellationTime,
    DateTime? completionTime,
    String? pickupLocation,
    String? dropoffLocation,
    String? specialRequests,
    String? cancellationReason,
    double? rating,
    String? review,
    Map<String, dynamic>? metadata,
    bool? isPremium,
  }) {
    return BookingModel(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      passengerImage: passengerImage ?? this.passengerImage,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverImage: driverImage ?? this.driverImage,
      seatsBooked: seatsBooked ?? this.seatsBooked,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      bookingTime: bookingTime ?? this.bookingTime,
      confirmationTime: confirmationTime ?? this.confirmationTime,
      cancellationTime: cancellationTime ?? this.cancellationTime,
      completionTime: completionTime ?? this.completionTime,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      specialRequests: specialRequests ?? this.specialRequests,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      metadata: metadata ?? this.metadata,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  bool get isConfirmed => status == BookingStatus.confirmed;
  bool get isPending => status == BookingStatus.pending;
  bool get isCancelled => status == BookingStatus.cancelled;
  bool get isCompleted => status == BookingStatus.completed;
  bool get isPaid => paymentStatus == PaymentStatus.paid;
  bool get canBeCancelled =>
      status == BookingStatus.pending || status == BookingStatus.confirmed;
  bool get canBeRated => status == BookingStatus.completed && rating == null;

  String get statusDisplay {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.noShow:
        return 'No Show';
    }
  }

  String get paymentStatusDisplay {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.failed:
        return 'Failed';
    }
  }

  String get formattedAmount => '$currency ${totalAmount.toStringAsFixed(0)}';

  String get formattedBookingTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDate = DateTime(
      bookingTime.year,
      bookingTime.month,
      bookingTime.day,
    );

    if (bookingDate == today) {
      return 'Today at ${_formatTime(bookingTime)}';
    } else if (bookingDate == today.add(Duration(days: 1))) {
      return 'Tomorrow at ${_formatTime(bookingTime)}';
    } else {
      return '${_formatDate(bookingTime)} at ${_formatTime(bookingTime)}';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Duration get timeSinceBooking => DateTime.now().difference(bookingTime);

  bool get isRecent => timeSinceBooking.inHours < 24;

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
