import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as location_package;
import 'package:logger/logger.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

final Logger _logger = Logger();

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final location_package.Location _location = location_package.Location();
  StreamSubscription<location_package.LocationData>? _locationSubscription;

  bool _isInitialized = false;
  bool _isTracking = false;
  location_package.LocationData? _currentLocation;
  final List<location_package.LocationData> _locationHistory = [];

  // Location permissions
  bool _hasLocationPermission = false;
  bool _hasBackgroundPermission = false;

  /// Initialize location service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        _logger.w('Location service: Skipping initialization on web');
        _isInitialized = false;
        return;
      }
      // Only request permissions on Android/iOS
      if (Platform.isAndroid || Platform.isIOS) {
        // Check and request permissions
        await _requestPermissions();
        // Enable location services
        await _location.enableBackgroundMode(enable: true);
        _isInitialized = true;
        _logger.i('Location service initialized successfully');
      } else {
        _logger.w('Location service: Not supported on this platform');
        _isInitialized = false;
      }
    } catch (e) {
      _logger.e('Failed to initialize location service: $e');
      _isInitialized = false;
    }
  }

  /// Request location permissions
  Future<void> _requestPermissions() async {
    if (kIsWeb) {
      _logger.w('Location permissions: Skipping on web');
      _hasLocationPermission = false;
      _hasBackgroundPermission = false;
      return;
    }
    try {
      // Check location permission
      var locationStatus = await Permission.location.status;
      if (locationStatus.isDenied) {
        locationStatus = await Permission.location.request();
      }

      // Check background location permission
      var backgroundStatus = await Permission.locationAlways.status;
      if (backgroundStatus.isDenied) {
        backgroundStatus = await Permission.locationAlways.request();
      }

      _hasLocationPermission = locationStatus.isGranted;
      _hasBackgroundPermission = backgroundStatus.isGranted;

      _logger.i(
          'Location permissions: $_hasLocationPermission, Background: $_hasBackgroundPermission');
    } catch (e) {
      _logger.e('Error requesting location permissions: $e');
    }
  }

  /// Get current location
  Future<location_package.LocationData?> getCurrentLocation() async {
    if (kIsWeb) {
      _logger.w('getCurrentLocation: Not supported on web');
      return null;
    }
    if (!_isInitialized) {
      await initialize();
    }
    if (!_hasLocationPermission) {
      _logger.w('Location permission not granted');
      return null;
    }
    try {
      _currentLocation = await _location.getLocation();
      _logger.i(
          'Current location: ${_currentLocation?.latitude}, ${_currentLocation?.longitude}');
      return _currentLocation;
    } catch (e) {
      _logger.e('Error getting current location: $e');
      return null;
    }
  }

  /// Start real-time location tracking
  Future<void> startLocationTracking({
    required Function(location_package.LocationData) onLocationUpdate,
    Duration interval = const Duration(seconds: 10),
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_hasLocationPermission) {
      _logger.w('Location permission not granted');
      return;
    }

    if (_isTracking) {
      _logger.w('Location tracking already active');
      return;
    }

    try {
      _locationSubscription =
          _location.onLocationChanged.listen((locationData) {
        _currentLocation = locationData;
        _locationHistory.add(locationData);

        // Keep only last 100 locations
        if (_locationHistory.length > 100) {
          _locationHistory.removeAt(0);
        }

        onLocationUpdate(locationData);
        _logger.d(
            'Location update: ${locationData.latitude}, ${locationData.longitude}');
      });

      _isTracking = true;
      _logger.i('Location tracking started');
    } catch (e) {
      _logger.e('Error starting location tracking: $e');
    }
  }

  /// Stop location tracking
  Future<void> stopLocationTracking() async {
    if (!_isTracking) return;

    try {
      await _locationSubscription?.cancel();
      _locationSubscription = null;
      _isTracking = false;
      _logger.i('Location tracking stopped');
    } catch (e) {
      _logger.e('Error stopping location tracking: $e');
    }
  }

  /// Calculate distance between two points (Haversine formula)
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double R = 6371000; // Earth radius in meters
    final double dLat = _deg2rad(lat2 - lat1);
    final double dLon = _deg2rad(lon2 - lon1);
    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (3.141592653589793 / 180.0);

  /// Get location history
  List<location_package.LocationData> getLocationHistory() {
    return List.from(_locationHistory);
  }

  /// Clear location history
  void clearLocationHistory() {
    _locationHistory.clear();
    _logger.i('Location history cleared');
  }

  /// Check if location services are enabled
  Future<bool> isLocationEnabled() async {
    try {
      return await _location.serviceEnabled();
    } catch (e) {
      _logger.e('Error checking location service: $e');
      return false;
    }
  }

  /// Request to enable location services
  Future<bool> requestLocationService() async {
    try {
      return await _location.requestService();
    } catch (e) {
      _logger.e('Error requesting location service: $e');
      return false;
    }
  }

  /// Get formatted address from coordinates (not implemented)
  Future<String> getAddressFromCoordinates(double lat, double lon) async {
    return 'Location at ${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
  }

  /// Get coordinates from address (not implemented)
  Future<location_package.LocationData?> getCoordinatesFromAddress(
      String address) async {
    _logger.i('Geocoding not implemented yet');
    return null;
  }

  /// Check if user is within specified radius of a location
  bool isWithinRadius(
    double userLat,
    double userLon,
    double targetLat,
    double targetLon,
    double radiusInMeters,
  ) {
    final distance = calculateDistance(userLat, userLon, targetLat, targetLon);
    return distance <= radiusInMeters;
  }

  /// Get current location data
  location_package.LocationData? get currentLocation => _currentLocation;

  /// Check if tracking is active
  bool get isTracking => _isTracking;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if location permission is granted
  bool get hasLocationPermission => _hasLocationPermission;

  /// Check if background location permission is granted
  bool get hasBackgroundPermission => _hasBackgroundPermission;

  /// Dispose resources
  void dispose() {
    stopLocationTracking();
    clearLocationHistory();
    _isInitialized = false;
  }
}
