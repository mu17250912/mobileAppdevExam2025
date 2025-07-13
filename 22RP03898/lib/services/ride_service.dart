/// Ride Service for SafeRide
///
/// Handles all ride-related operations including creating, searching, booking,
/// and managing rides. This is a core service that connects passengers with drivers.
///
/// Features:
/// - Create and post rides (drivers only)
/// - Search and filter available rides
/// - Book and manage seat reservations
/// - Location-based ride matching
/// - Premium ride features
/// - Ride status management
///
/// TODO: Future Enhancements:
/// - Real-time ride tracking with GPS
/// - Route optimization and suggestions
/// - Dynamic pricing based on demand
/// - Ride sharing and carpooling features
/// - Integration with payment gateways
/// - Advanced analytics for drivers
/// - Ride scheduling and recurring rides
/// - Emergency contact integration
/// - Ride insurance features
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ride_model.dart';
import 'auth_service.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

class RideService {
  static final RideService _instance = RideService._internal();
  factory RideService() => _instance;
  RideService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  // Create a new ride
  Future<RideModel> createRide({
    required Location origin,
    required Location destination,
    required DateTime departureTime,
    required VehicleType vehicleType,
    required int totalSeats,
    required double price,
    String? vehicleNumber,
    String? description,
    List<String> amenities = const [],
    Map<String, dynamic> rules = const {},
    bool isPremium = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userModel = await _authService.getCurrentUserModel();
      if (userModel == null) {
        throw Exception('User profile not found');
      }

      if (!userModel.isDriver) {
        throw Exception('Only drivers can create rides');
      }

      final ride = RideModel(
        id: '',
        driverId: user.uid,
        driverName: userModel.name,
        driverPhone: userModel.phone,
        driverImage: userModel.profileImage,
        driverRating: userModel.rating,
        origin: origin,
        destination: destination,
        departureTime: departureTime,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber ?? userModel.vehicleNumber,
        totalSeats: totalSeats,
        availableSeats: totalSeats,
        price: price,
        description: description,
        amenities: amenities,
        rules: rules,
        isPremium: isPremium,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('rides').add(ride.toMap());

      return ride.copyWith(id: docRef.id, updatedAt: DateTime.now());
    } catch (e) {
      throw Exception('Failed to create ride: $e');
    }
  }

  // Get all available rides
  Stream<List<RideModel>> getAvailableRides({
    String? originQuery,
    String? destinationQuery,
    VehicleType? vehicleType,
    DateTime? date,
    double? maxPrice,
    bool? isPremium,
  }) {
    try {
      Query query = _firestore
          .collection('rides')
          .where('status', isEqualTo: RideStatus.scheduled.name)
          .where('availableSeats', isGreaterThan: 0)
          .orderBy('availableSeats', descending: true)
          .orderBy('departureTime');

      if (vehicleType != null) {
        query = query.where('vehicleType', isEqualTo: vehicleType.name);
      }

      if (isPremium != null) {
        query = query.where('isPremium', isEqualTo: isPremium);
      }

      return query.snapshots().handleError((error) {
        if (error is FirebaseException &&
            error.code == 'failed-precondition' &&
            error.message != null &&
            error.message!.contains('index')) {
          _logger.w('Firestore index missing for rides query: $error');
          return const Stream.empty();
        }
        throw error;
      }).map((snapshot) {
        List<RideModel> rides = [];
        for (var doc in snapshot.docs) {
          final ride = RideModel.fromDoc(doc);

          // Apply filters
          bool shouldInclude = true;

          if (originQuery != null && originQuery.isNotEmpty) {
            shouldInclude = shouldInclude &&
                ride.origin.name
                    .toLowerCase()
                    .contains(originQuery.toLowerCase());
          }

          if (destinationQuery != null && destinationQuery.isNotEmpty) {
            shouldInclude = shouldInclude &&
                ride.destination.name
                    .toLowerCase()
                    .contains(destinationQuery.toLowerCase());
          }

          if (date != null) {
            final rideDate = DateTime(
              ride.departureTime.year,
              ride.departureTime.month,
              ride.departureTime.day,
            );
            final filterDate = DateTime(date.year, date.month, date.day);
            shouldInclude =
                shouldInclude && rideDate.isAtSameMomentAs(filterDate);
          }

          if (maxPrice != null) {
            shouldInclude = shouldInclude && ride.price <= maxPrice;
          }

          if (shouldInclude) {
            rides.add(ride);
          }
        }

        // Sort by premium status first, then by departure time
        rides.sort((a, b) {
          if (a.isPremium != b.isPremium) {
            return b.isPremium ? 1 : -1; // Premium rides first
          }
          return a.departureTime.compareTo(b.departureTime);
        });

        return rides;
      });
    } catch (e) {
      _logger.e('Error getting available rides: $e');
      return Stream.value([]);
    }
  }

  // Get ride by ID
  Future<RideModel?> getRideById(String rideId) async {
    try {
      final doc = await _firestore.collection('rides').doc(rideId).get();
      if (doc.exists) {
        return RideModel.fromDoc(doc);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting ride by ID: $e');
      return null;
    }
  }

  // Get rides by driver
  Stream<List<RideModel>> getRidesByDriver(String driverId) {
    try {
      return _firestore
          .collection('rides')
          .where('driverId', isEqualTo: driverId)
          .orderBy('departureTime', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => RideModel.fromDoc(doc)).toList());
    } catch (e) {
      _logger.e('Error getting rides by driver: $e');
      return Stream.value([]);
    }
  }

  // Update ride
  Future<void> updateRide(String rideId, Map<String, dynamic> updates) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final ride = await getRideById(rideId);
      if (ride == null) {
        throw Exception('Ride not found');
      }

      if (ride.driverId != user.uid) {
        throw Exception('Not authorized to update this ride');
      }

      updates['updatedAt'] = DateTime.now().toIso8601String();

      await _firestore.collection('rides').doc(rideId).update(updates);
      _logger.i('Ride updated successfully: $rideId');
    } catch (e) {
      _logger.e('Error updating ride: $e');
      throw Exception('Failed to update ride: $e');
    }
  }

  // Update ride status
  Future<void> updateRideStatus(String rideId, RideStatus status) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final ride = await getRideById(rideId);
      if (ride == null) {
        throw Exception('Ride not found');
      }

      if (ride.driverId != user.uid) {
        throw Exception('Not authorized to update this ride');
      }

      await _firestore.collection('rides').doc(rideId).update({
        'status': status.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      _logger.i('Ride status updated: $rideId -> ${status.name}');
    } catch (e) {
      _logger.e('Error updating ride status: $e');
      throw Exception('Failed to update ride status: $e');
    }
  }

  // Delete ride
  Future<void> deleteRide(String rideId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final ride = await getRideById(rideId);
      if (ride == null) {
        throw Exception('Ride not found');
      }

      if (ride.driverId != user.uid) {
        throw Exception('Not authorized to delete this ride');
      }

      await _firestore.collection('rides').doc(rideId).delete();
      _logger.i('Ride deleted successfully: $rideId');
    } catch (e) {
      _logger.e('Error deleting ride: $e');
      throw Exception('Failed to delete ride: $e');
    }
  }

  // Book seats on a ride
  Future<void> bookSeats(String rideId, int seats) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final ride = await getRideById(rideId);
      if (ride == null) {
        throw Exception('Ride not found');
      }

      if (ride.availableSeats < seats) {
        throw Exception('Not enough seats available');
      }

      await _firestore.collection('rides').doc(rideId).update({
        'availableSeats': ride.availableSeats - seats,
        'bookedUsers': FieldValue.arrayUnion([user.uid]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to book seats: $e');
    }
  }

  // Release seats on a ride
  Future<void> releaseSeats(String rideId, int seats) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final ride = await getRideById(rideId);
      if (ride == null) {
        throw Exception('Ride not found');
      }

      await _firestore.collection('rides').doc(rideId).update({
        'availableSeats': ride.availableSeats + seats,
        'bookedUsers': FieldValue.arrayRemove([user.uid]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to release seats: $e');
    }
  }

  // Search rides by location
  Future<List<RideModel>> searchRidesByLocation({
    required String origin,
    required String destination,
    DateTime? date,
    VehicleType? vehicleType,
  }) async {
    try {
      Query query = _firestore
          .collection('rides')
          .where('status', isEqualTo: RideStatus.scheduled.name)
          .where('availableSeats', isGreaterThan: 0);

      if (vehicleType != null) {
        query = query.where('vehicleType', isEqualTo: vehicleType.name);
      }

      final snapshot = await query.get();
      List<RideModel> rides = [];

      for (var doc in snapshot.docs) {
        final ride = RideModel.fromDoc(doc);

        bool matchesOrigin = ride.origin.name.toLowerCase().contains(
              origin.toLowerCase(),
            );
        bool matchesDestination = ride.destination.name.toLowerCase().contains(
              destination.toLowerCase(),
            );

        if (matchesOrigin && matchesDestination) {
          if (date != null) {
            final rideDate = DateTime(
              ride.departureTime.year,
              ride.departureTime.month,
              ride.departureTime.day,
            );
            final filterDate = DateTime(date.year, date.month, date.day);
            if (rideDate.isAtSameMomentAs(filterDate)) {
              rides.add(ride);
            }
          } else {
            rides.add(ride);
          }
        }
      }

      // Sort by premium status first, then by departure time
      rides.sort((a, b) {
        if (a.isPremium != b.isPremium) {
          return b.isPremium ? 1 : -1; // Premium rides first
        }
        return a.departureTime.compareTo(b.departureTime);
      });

      return rides;
    } catch (e) {
      _logger.e('Error searching rides by location: $e');
      return [];
    }
  }

  // Get nearby rides (within a certain radius)
  Future<List<RideModel>> getNearbyRides({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      // TODO: Implement geospatial queries with Firestore GeoPoint
      // For now, return all available rides
      final snapshot = await _firestore
          .collection('rides')
          .where('status', isEqualTo: RideStatus.scheduled.name)
          .where('availableSeats', isGreaterThan: 0)
          .get();

      return snapshot.docs.map((doc) => RideModel.fromDoc(doc)).toList();
    } catch (e) {
      _logger.e('Error getting nearby rides: $e');
      return [];
    }
  }

  // Get ride statistics for a driver
  Future<Map<String, dynamic>> getDriverRideStats(String driverId) async {
    try {
      final ridesSnapshot = await _firestore
          .collection('rides')
          .where('driverId', isEqualTo: driverId)
          .get();

      int totalRides = ridesSnapshot.docs.length;
      int completedRides = 0;
      int cancelledRides = 0;
      double totalEarnings = 0.0;

      for (var doc in ridesSnapshot.docs) {
        final ride = RideModel.fromDoc(doc);
        if (ride.status == RideStatus.completed) {
          completedRides++;
          totalEarnings += ride.price * (ride.totalSeats - ride.availableSeats);
        } else if (ride.status == RideStatus.cancelled) {
          cancelledRides++;
        }
      }

      return {
        'totalRides': totalRides,
        'completedRides': completedRides,
        'cancelledRides': cancelledRides,
        'totalEarnings': totalEarnings,
        'completionRate': totalRides > 0 ? completedRides / totalRides : 0.0,
      };
    } catch (e) {
      _logger.e('Error getting driver ride stats: $e');
      return {};
    }
  }

  // Mark ride as completed
  Future<void> completeRide(String rideId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final ride = await getRideById(rideId);
      if (ride == null) {
        throw Exception('Ride not found');
      }

      if (ride.driverId != user.uid) {
        throw Exception('Not authorized to complete this ride');
      }

      await _firestore.collection('rides').doc(rideId).update({
        'status': RideStatus.completed.name,
        'arrivalTime': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      _logger.i('Ride completed: $rideId');
    } catch (e) {
      _logger.e('Error completing ride: $e');
      throw Exception('Failed to complete ride: $e');
    }
  }
}
