import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // Default values for remote config
  static const Map<String, dynamic> _defaults = {
    'welcome_message': 'Welcome to Blood Donor App!',
    'app_version': '1.0.0',
    'premium_price': '10',
    'donation_reminder_days': '56',
    'emergency_contact': '+1234567890',
    'maintenance_mode': false,
    'new_features_enabled': true,
    'blood_types': 'A+, A-, B+, B-, AB+, AB-, O+, O-',
    'donation_centers': 'Red Cross, City Hospital, Community Center',
    'app_theme_color': 'red',
    'max_donations_per_year': '4',
    'donation_eligibility_age': '18',
    'featured_campaign': 'Summer Blood Drive 2024',
    'urgent_blood_types': 'O-, A-',
    'app_update_required': false,
    'minimum_app_version': '1.0.0',
  };

  Future<void> initialize() async {
    try {
      // Set default values
      await _remoteConfig.setDefaults(_defaults);

      // Configure settings
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // Fetch and activate
      await _remoteConfig.fetchAndActivate();
      
      print('Remote Config initialized successfully');
    } catch (e) {
      print('Error initializing Remote Config: $e');
    }
  }

  // Get string values
  String getString(String key) {
    return _remoteConfig.getString(key);
  }

  // Get boolean values
  bool getBool(String key) {
    return _remoteConfig.getBool(key);
  }

  // Get integer values
  int getInt(String key) {
    return _remoteConfig.getInt(key);
  }

  // Get double values
  double getDouble(String key) {
    return _remoteConfig.getDouble(key);
  }

  // Check if update is required
  bool isUpdateRequired(String currentVersion) {
    final minimumVersion = getString('minimum_app_version');
    return _compareVersions(currentVersion, minimumVersion) < 0;
  }

  // Compare version strings
  int _compareVersions(String version1, String version2) {
    List<int> v1 = version1.split('.').map(int.parse).toList();
    List<int> v2 = version2.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
      int num1 = i < v1.length ? v1[i] : 0;
      int num2 = i < v2.length ? v2[i] : 0;
      
      if (num1 > num2) return 1;
      if (num1 < num2) return -1;
    }
    return 0;
  }

  // Get blood types as list
  List<String> getBloodTypes() {
    return getString('blood_types').split(', ');
  }

  // Get donation centers as list
  List<String> getDonationCenters() {
    return getString('donation_centers').split(', ');
  }

  // Get urgent blood types as list
  List<String> getUrgentBloodTypes() {
    return getString('urgent_blood_types').split(', ');
  }

  // Check if app is in maintenance mode
  bool isMaintenanceMode() {
    return getBool('maintenance_mode');
  }

  // Get premium price
  String getPremiumPrice() {
    return getString('premium_price');
  }

  // Get welcome message
  String getWelcomeMessage() {
    return getString('welcome_message');
  }

  // Get featured campaign
  String getFeaturedCampaign() {
    return getString('featured_campaign');
  }

  // Get donation reminder days
  int getDonationReminderDays() {
    return getInt('donation_reminder_days');
  }

  // Get emergency contact
  String getEmergencyContact() {
    return getString('emergency_contact');
  }

  // Check if new features are enabled
  bool areNewFeaturesEnabled() {
    return getBool('new_features_enabled');
  }

  // Get max donations per year
  int getMaxDonationsPerYear() {
    return getInt('max_donations_per_year');
  }

  // Get donation eligibility age
  int getDonationEligibilityAge() {
    return getInt('donation_eligibility_age');
  }

  // Force fetch latest config
  Future<void> forceFetch() async {
    try {
      await _remoteConfig.fetchAndActivate();
      print('Remote Config force fetch completed');
    } catch (e) {
      print('Error force fetching Remote Config: $e');
    }
  }

  // Get last fetch time
  DateTime getLastFetchTime() {
    return _remoteConfig.lastFetchTime;
  }

  // Get fetch status
  RemoteConfigFetchStatus getFetchStatus() {
    return _remoteConfig.lastFetchStatus;
  }
} 