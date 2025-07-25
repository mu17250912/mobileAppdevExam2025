class Booking {
  final String id;
  final String providerId;
  final String userId;
  final String serviceType; // Basic, Standard, Premium
  final String contactname;
  final String contactphone;
  final String date;
  final String time;
  final String location;
  final String notes;
  final String status; // pending, confirmed, completed, cancelled
  final String paymentstatus; // pending, paid, failed
  final DateTime creatAt;
  final double price;

  Booking({
    required this.id,
    required this.providerId,
    required this.userId,
    required this.serviceType,
    required this.contactname,
    required this.contactphone,
    required this.date,
    required this.time,
    required this.location,
    required this.notes,
    required this.status,
    required this.paymentstatus,
    required this.creatAt,
    required this.price,
  });

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] ?? '',
      providerId: map['providerId'] ?? '',
      userId: map['userId'] ?? '',
      serviceType: map['serviceType'] ?? '',
      contactname: map['contactname'] ?? '',
      contactphone: map['contactphone'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      location: map['location'] ?? '',
      notes: map['notes'] ?? '',
      status: map['status'] ?? 'pending',
      paymentstatus: map['paymentstatus'] ?? 'pending',
      creatAt: map['creatAt'] != null 
          ? DateTime.parse(map['creatAt']) 
          : DateTime.now(),
      price: (map['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'providerId': providerId,
      'userId': userId,
      'serviceType': serviceType,
      'contactname': contactname,
      'contactphone': contactphone,
      'date': date,
      'time': time,
      'location': location,
      'notes': notes,
      'status': status,
      'paymentstatus': paymentstatus,
      'creatAt': creatAt.toIso8601String(),
      'price': price,
    };
  }

  static double getServicePrice(String serviceType) {
    switch (serviceType) {
      case 'Basic':
        return 4500.0;
      case 'Standard':
        return 7000.0;
      case 'Premium':
        return 10000.0;
      default:
        return 4500.0;
    }
  }

  static List<String> getServiceTypes() {
    return ['Basic', 'Standard', 'Premium'];
  }
} 