import 'package:cloud_firestore/cloud_firestore.dart';

class Car {
  final String id;
  final String brand;
  final String model;
  final int price;
  final String image;
  final bool available;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Car({
    required this.id,
    required this.brand,
    required this.model,
    required this.price,
    required this.image,
    this.available = true,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'price': price,
      'image': image,
      'available': available,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create from Map
  factory Car.fromMap(Map<String, dynamic> map, String documentId) {
    return Car(
      id: documentId,
      brand: (map['brand'] ?? '').toString(),
      model: (map['model'] ?? '').toString(),
      price: (map['price'] ?? 0) as int,
      image: (map['image'] ?? '').toString(),
      available: map['available'] ?? true,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : (map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) : null),
    );
  }

  // Copy with method for updating car data
  Car copyWith({
    String? id,
    String? brand,
    String? model,
    int? price,
    String? image,
    bool? available,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Car(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      price: price ?? this.price,
      image: image ?? this.image,
      available: available ?? this.available,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CarStore {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize cars in Firestore
  static Future<void> initialize() async {
    try {
      // Check if cars collection is empty
      final carsSnapshot = await _firestore.collection('cars').get();
      
      if (carsSnapshot.docs.isEmpty) {
        // Add default cars to Firestore
        final defaultCars = [
          {'brand': 'Toyota', 'model': 'Corolla', 'price': 50000, 'image': 'https://cdn.pixabay.com/photo/2012/05/29/00/43/car-49278_1280.jpg'},
          {'brand': 'Honda', 'model': 'Civic', 'price': 60000, 'image': 'https://cdn.pixabay.com/photo/2016/11/29/09/32/auto-1868726_1280.jpg'},
          {'brand': 'Ford', 'model': 'Focus', 'price': 55000, 'image': 'https://cdn.pixabay.com/photo/2013/07/12/15/55/ford-150238_1280.png'},
          {'brand': 'BMW', 'model': '3 Series', 'price': 120000, 'image': 'https://cdn.pixabay.com/photo/2017/01/06/19/15/bmw-1957037_1280.jpg'},
          {'brand': 'Mercedes', 'model': 'C-Class', 'price': 130000, 'image': 'https://cdn.pixabay.com/photo/2015/01/19/13/51/mercedes-benz-604019_1280.jpg'},
          {'brand': 'Audi', 'model': 'A4', 'price': 125000, 'image': 'https://cdn.pixabay.com/photo/2016/11/29/09/32/audi-1868727_1280.jpg'},
          {'brand': 'Volkswagen', 'model': 'Golf', 'price': 70000, 'image': 'https://cdn.pixabay.com/photo/2017/01/06/19/15/volkswagen-1957038_1280.jpg'},
          {'brand': 'Hyundai', 'model': 'Elantra', 'price': 65000, 'image': 'https://cdn.pixabay.com/photo/2016/11/29/09/32/hyundai-1868728_1280.jpg'},
          {'brand': 'Kia', 'model': 'Rio', 'price': 60000, 'image': 'https://cdn.pixabay.com/photo/2016/11/29/09/32/kia-1868729_1280.jpg'},
          {'brand': 'Mazda', 'model': '3', 'price': 68000, 'image': 'https://cdn.pixabay.com/photo/2016/11/29/09/32/mazda-1868730_1280.jpg'},
          {'brand': 'Nissan', 'model': 'Sentra', 'price': 62000, 'image': 'https://cdn.pixabay.com/photo/2016/11/29/09/32/nissan-1868731_1280.jpg'},
          {'brand': 'Chevrolet', 'model': 'Cruze', 'price': 64000, 'image': 'https://cdn.pixabay.com/photo/2016/11/29/09/32/chevrolet-1868732_1280.jpg'},
          {'brand': 'Subaru', 'model': 'Impreza', 'price': 70000, 'image': 'https://cdn.pixabay.com/photo/2016/11/29/09/32/subaru-1868733_1280.jpg'},
          {'brand': 'Peugeot', 'model': '308', 'price': 72000, 'image': 'https://cdn.pixabay.com/photo/2016/11/29/09/32/peugeot-1868734_1280.jpg'},
          {'brand': 'Renault', 'model': 'Megane', 'price': 71000, 'image': 'https://cdn.pixabay.com/photo/2016/11/29/09/32/renault-1868735_1280.jpg'},
        ];

        for (final carData in defaultCars) {
          final car = Car(
            id: 'car_${DateTime.now().millisecondsSinceEpoch}_${carData['brand']}_${carData['model']}',
            brand: carData['brand'] as String,
            model: carData['model'] as String,
            price: carData['price'] as int,
            image: carData['image'] as String,
            createdAt: DateTime.now(),
          );
          
          await _firestore.collection('cars').doc(car.id).set(car.toMap());
        }
      }
    } catch (e) {
      print('Error initializing cars: $e');
    }
  }

  // Stream for real-time updates
  static Stream<List<Car>> getCarsStream() {
    return _firestore.collection('cars').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Car.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Get available cars stream
  static Stream<List<Car>> getAvailableCarsStream() {
    return _firestore
        .collection('cars')
        .where('available', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Car.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Get car by ID
  static Future<Car?> getCarById(String id) async {
    try {
      final doc = await _firestore.collection('cars').doc(id).get();
      if (doc.exists) {
        return Car.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting car by ID: $e');
      return null;
    }
  }

  // Create new car
  static Future<bool> createCar(Car car) async {
    try {
      await _firestore.collection('cars').doc(car.id).set(car.toMap());
      return true;
    } catch (e) {
      throw Exception('Failed to create car: ${e.toString()}');
    }
  }

  // Update car
  static Future<bool> updateCar(Car updatedCar) async {
    try {
      final updatedData = updatedCar.copyWith(updatedAt: DateTime.now()).toMap();
      await _firestore.collection('cars').doc(updatedCar.id).update(updatedData);
      return true;
    } catch (e) {
      throw Exception('Failed to update car: ${e.toString()}');
    }
  }

  // Delete car
  static Future<bool> deleteCar(String carId) async {
    try {
      await _firestore.collection('cars').doc(carId).delete();
      return true;
    } catch (e) {
      throw Exception('Failed to delete car: ${e.toString()}');
    }
  }

  // Search cars using stream
  static Stream<List<Car>> searchCarsStream(String query) {
    if (query.isEmpty) {
      return getCarsStream();
    }
    
    final lowercaseQuery = query.toLowerCase();
    
    return _firestore.collection('cars').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Car.fromMap(doc.data(), doc.id))
          .where((car) =>
            car.brand.toLowerCase().contains(lowercaseQuery) ||
            car.model.toLowerCase().contains(lowercaseQuery)
          )
          .toList();
    });
  }

  // Get cars by price range stream
  static Stream<List<Car>> getCarsByPriceRangeStream(int minPrice, int maxPrice) {
    return _firestore.collection('cars').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Car.fromMap(doc.data(), doc.id))
          .where((car) => car.price >= minPrice && car.price <= maxPrice)
          .toList();
    });
  }

  // Get cars by availability stream
  static Stream<List<Car>> getCarsByAvailabilityStream(bool available) {
    return _firestore
        .collection('cars')
        .where('available', isEqualTo: available)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Car.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Update car availability
  static Future<bool> updateCarAvailability(String carId, bool available) async {
    try {
      await _firestore.collection('cars').doc(carId).update({
        'available': available,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      throw Exception('Failed to update car availability: ${e.toString()}');
    }
  }

  // Get car statistics
  static Stream<Map<String, int>> getCarStatisticsStream() {
    return _firestore.collection('cars').snapshots().map((snapshot) {
      final cars = snapshot.docs.map((doc) => Car.fromMap(doc.data(), doc.id)).toList();
      
      return {
        'total': cars.length,
        'available': cars.where((car) => car.available).length,
        'unavailable': cars.where((car) => !car.available).length,
      };
    });
  }
} 