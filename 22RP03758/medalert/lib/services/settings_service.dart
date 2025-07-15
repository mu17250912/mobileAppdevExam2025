import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // User preferences
  String _language = 'en';
  String _theme = 'system';
  bool _notificationsEnabled = true;
  bool _voiceRemindersEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _reminderAdvanceMinutes = 15;
  bool _autoSyncEnabled = true;
  bool _offlineModeEnabled = false;
  
  // Role-based settings
  String _userRole = 'patient';
  bool _caregiverNotificationsEnabled = true;
  bool _patientAlertsEnabled = true;
  bool _emergencyContactNotifications = true;
  bool _weeklyReportsEnabled = true;
  bool _monthlyReportsEnabled = true;
  
  // Profile settings
  String _displayName = '';
  String _email = '';
  String _phone = '';
  String _emergencyContact = '';
  String _medicalConditions = '';
  String _allergies = '';
  String _notes = '';

  // Getters
  String get language => _language;
  String get theme => _theme;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get voiceRemindersEnabled => _voiceRemindersEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  int get reminderAdvanceMinutes => _reminderAdvanceMinutes;
  bool get autoSyncEnabled => _autoSyncEnabled;
  bool get offlineModeEnabled => _offlineModeEnabled;
  String get userRole => _userRole;
  bool get caregiverNotificationsEnabled => _caregiverNotificationsEnabled;
  bool get patientAlertsEnabled => _patientAlertsEnabled;
  bool get emergencyContactNotifications => _emergencyContactNotifications;
  bool get weeklyReportsEnabled => _weeklyReportsEnabled;
  bool get monthlyReportsEnabled => _monthlyReportsEnabled;
  String get displayName => _displayName;
  String get email => _email;
  String get phone => _phone;
  String get emergencyContact => _emergencyContact;
  String get medicalConditions => _medicalConditions;
  String get allergies => _allergies;
  String get notes => _notes;

  // Initialize settings
  Future<void> initialize() async {
    await _loadLocalSettings();
    await _loadUserSettings();
  }

  // Load local settings from SharedPreferences
  Future<void> _loadLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _language = prefs.getString('language') ?? 'en';
      _theme = prefs.getString('theme') ?? 'system';
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _voiceRemindersEnabled = prefs.getBool('voice_reminders_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _reminderAdvanceMinutes = prefs.getInt('reminder_advance_minutes') ?? 15;
      _autoSyncEnabled = prefs.getBool('auto_sync_enabled') ?? true;
      _offlineModeEnabled = prefs.getBool('offline_mode_enabled') ?? false;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading local settings: $e');
    }
  }

  // Load user settings from Firestore
  Future<void> _loadUserSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        
        _userRole = data['role'] ?? 'patient';
        _displayName = data['name'] ?? '';
        _email = data['email'] ?? '';
        _phone = data['phone'] ?? '';
        _emergencyContact = data['emergencyContact'] ?? '';
        _medicalConditions = data['medicalConditions'] ?? '';
        _allergies = data['allergies'] ?? '';
        _notes = data['notes'] ?? '';
        
        // Role-based settings
        if (_userRole == 'caregiver') {
          _caregiverNotificationsEnabled = data['caregiverNotificationsEnabled'] ?? true;
          _patientAlertsEnabled = data['patientAlertsEnabled'] ?? true;
          _emergencyContactNotifications = data['emergencyContactNotifications'] ?? true;
          _weeklyReportsEnabled = data['weeklyReportsEnabled'] ?? true;
          _monthlyReportsEnabled = data['monthlyReportsEnabled'] ?? true;
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user settings: $e');
    }
  }

  // Save local settings
  Future<void> _saveLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('language', _language);
      await prefs.setString('theme', _theme);
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('voice_reminders_enabled', _voiceRemindersEnabled);
      await prefs.setBool('sound_enabled', _soundEnabled);
      await prefs.setBool('vibration_enabled', _vibrationEnabled);
      await prefs.setInt('reminder_advance_minutes', _reminderAdvanceMinutes);
      await prefs.setBool('auto_sync_enabled', _autoSyncEnabled);
      await prefs.setBool('offline_mode_enabled', _offlineModeEnabled);
    } catch (e) {
      debugPrint('Error saving local settings: $e');
    }
  }

  // Save user settings to Firestore
  Future<void> _saveUserSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final updateData = <String, dynamic>{
        'name': _displayName,
        'phone': _phone,
        'emergencyContact': _emergencyContact,
        'medicalConditions': _medicalConditions,
        'allergies': _allergies,
        'notes': _notes,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add role-based settings
      if (_userRole == 'caregiver') {
        updateData['caregiverNotificationsEnabled'] = _caregiverNotificationsEnabled;
        updateData['patientAlertsEnabled'] = _patientAlertsEnabled;
        updateData['emergencyContactNotifications'] = _emergencyContactNotifications;
        updateData['weeklyReportsEnabled'] = _weeklyReportsEnabled;
        updateData['monthlyReportsEnabled'] = _monthlyReportsEnabled;
      }

      await _firestore.collection('users').doc(user.uid).update(updateData);
    } catch (e) {
      debugPrint('Error saving user settings: $e');
    }
  }

  // General settings methods
  Future<void> setLanguage(String language) async {
    _language = language;
    await _saveLocalSettings();
    notifyListeners();
  }

  Future<void> setTheme(String theme) async {
    _theme = theme;
    await _saveLocalSettings();
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _saveLocalSettings();
    notifyListeners();
  }

  Future<void> setVoiceRemindersEnabled(bool enabled) async {
    _voiceRemindersEnabled = enabled;
    await _saveLocalSettings();
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _saveLocalSettings();
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    await _saveLocalSettings();
    notifyListeners();
  }

  Future<void> setReminderAdvanceMinutes(int minutes) async {
    _reminderAdvanceMinutes = minutes;
    await _saveLocalSettings();
    notifyListeners();
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    _autoSyncEnabled = enabled;
    await _saveLocalSettings();
    notifyListeners();
  }

  Future<void> setOfflineModeEnabled(bool enabled) async {
    _offlineModeEnabled = enabled;
    await _saveLocalSettings();
    notifyListeners();
  }

  // Caregiver-specific settings
  Future<void> setCaregiverNotificationsEnabled(bool enabled) async {
    _caregiverNotificationsEnabled = enabled;
    await _saveUserSettings();
    notifyListeners();
  }

  Future<void> setPatientAlertsEnabled(bool enabled) async {
    _patientAlertsEnabled = enabled;
    await _saveUserSettings();
    notifyListeners();
  }

  Future<void> setEmergencyContactNotifications(bool enabled) async {
    _emergencyContactNotifications = enabled;
    await _saveUserSettings();
    notifyListeners();
  }

  Future<void> setWeeklyReportsEnabled(bool enabled) async {
    _weeklyReportsEnabled = enabled;
    await _saveUserSettings();
    notifyListeners();
  }

  Future<void> setMonthlyReportsEnabled(bool enabled) async {
    _monthlyReportsEnabled = enabled;
    await _saveUserSettings();
    notifyListeners();
  }

  // Profile settings
  Future<void> updateProfile({
    String? displayName,
    String? phone,
    String? emergencyContact,
    String? medicalConditions,
    String? allergies,
    String? notes,
  }) async {
    if (displayName != null) _displayName = displayName;
    if (phone != null) _phone = phone;
    if (emergencyContact != null) _emergencyContact = emergencyContact;
    if (medicalConditions != null) _medicalConditions = medicalConditions;
    if (allergies != null) _allergies = allergies;
    if (notes != null) _notes = notes;

    await _saveUserSettings();
    notifyListeners();
  }

  // Get available languages
  List<Map<String, String>> getAvailableLanguages() {
    return [
      {'code': 'en', 'name': 'English'},
      {'code': 'es', 'name': 'Español'},
      {'code': 'fr', 'name': 'Français'},
      {'code': 'de', 'name': 'Deutsch'},
      {'code': 'it', 'name': 'Italiano'},
      {'code': 'pt', 'name': 'Português'},
      {'code': 'ru', 'name': 'Русский'},
      {'code': 'zh', 'name': '中文'},
      {'code': 'ja', 'name': '日本語'},
      {'code': 'ko', 'name': '한국어'},
    ];
  }

  // Get available themes
  List<Map<String, String>> getAvailableThemes() {
    return [
      {'code': 'system', 'name': 'System Default'},
      {'code': 'light', 'name': 'Light'},
      {'code': 'dark', 'name': 'Dark'},
    ];
  }

  // Get reminder advance options
  List<Map<String, dynamic>> getReminderAdvanceOptions() {
    return [
      {'minutes': 5, 'label': '5 minutes'},
      {'minutes': 10, 'label': '10 minutes'},
      {'minutes': 15, 'label': '15 minutes'},
      {'minutes': 30, 'label': '30 minutes'},
      {'minutes': 60, 'label': '1 hour'},
    ];
  }

  // Export settings
  Map<String, dynamic> exportSettings() {
    return {
      'language': _language,
      'theme': _theme,
      'notificationsEnabled': _notificationsEnabled,
      'voiceRemindersEnabled': _voiceRemindersEnabled,
      'soundEnabled': _soundEnabled,
      'vibrationEnabled': _vibrationEnabled,
      'reminderAdvanceMinutes': _reminderAdvanceMinutes,
      'autoSyncEnabled': _autoSyncEnabled,
      'offlineModeEnabled': _offlineModeEnabled,
      'userRole': _userRole,
      'caregiverNotificationsEnabled': _caregiverNotificationsEnabled,
      'patientAlertsEnabled': _patientAlertsEnabled,
      'emergencyContactNotifications': _emergencyContactNotifications,
      'weeklyReportsEnabled': _weeklyReportsEnabled,
      'monthlyReportsEnabled': _monthlyReportsEnabled,
      'displayName': _displayName,
      'email': _email,
      'phone': _phone,
      'emergencyContact': _emergencyContact,
      'medicalConditions': _medicalConditions,
      'allergies': _allergies,
      'notes': _notes,
    };
  }

  // Import settings
  Future<void> importSettings(Map<String, dynamic> settings) async {
    _language = settings['language'] ?? _language;
    _theme = settings['theme'] ?? _theme;
    _notificationsEnabled = settings['notificationsEnabled'] ?? _notificationsEnabled;
    _voiceRemindersEnabled = settings['voiceRemindersEnabled'] ?? _voiceRemindersEnabled;
    _soundEnabled = settings['soundEnabled'] ?? _soundEnabled;
    _vibrationEnabled = settings['vibrationEnabled'] ?? _vibrationEnabled;
    _reminderAdvanceMinutes = settings['reminderAdvanceMinutes'] ?? _reminderAdvanceMinutes;
    _autoSyncEnabled = settings['autoSyncEnabled'] ?? _autoSyncEnabled;
    _offlineModeEnabled = settings['offlineModeEnabled'] ?? _offlineModeEnabled;
    _userRole = settings['userRole'] ?? _userRole;
    _caregiverNotificationsEnabled = settings['caregiverNotificationsEnabled'] ?? _caregiverNotificationsEnabled;
    _patientAlertsEnabled = settings['patientAlertsEnabled'] ?? _patientAlertsEnabled;
    _emergencyContactNotifications = settings['emergencyContactNotifications'] ?? _emergencyContactNotifications;
    _weeklyReportsEnabled = settings['weeklyReportsEnabled'] ?? _weeklyReportsEnabled;
    _monthlyReportsEnabled = settings['monthlyReportsEnabled'] ?? _monthlyReportsEnabled;
    _displayName = settings['displayName'] ?? _displayName;
    _email = settings['email'] ?? _email;
    _phone = settings['phone'] ?? _phone;
    _emergencyContact = settings['emergencyContact'] ?? _emergencyContact;
    _medicalConditions = settings['medicalConditions'] ?? _medicalConditions;
    _allergies = settings['allergies'] ?? _allergies;
    _notes = settings['notes'] ?? _notes;

    await _saveLocalSettings();
    await _saveUserSettings();
    notifyListeners();
  }

  // Reset all settings to defaults
  Future<void> resetToDefaults() async {
    _language = 'en';
    _theme = 'system';
    _notificationsEnabled = true;
    _voiceRemindersEnabled = true;
    _soundEnabled = true;
    _vibrationEnabled = true;
    _reminderAdvanceMinutes = 15;
    _autoSyncEnabled = true;
    _offlineModeEnabled = false;
    _caregiverNotificationsEnabled = true;
    _patientAlertsEnabled = true;
    _emergencyContactNotifications = true;
    _weeklyReportsEnabled = true;
    _monthlyReportsEnabled = true;

    await _saveLocalSettings();
    await _saveUserSettings();
    notifyListeners();
  }

  // Get settings summary
  String getSettingsSummary() {
    final settings = <String>[];
    
    settings.add('Language: ${getAvailableLanguages().firstWhere((lang) => lang['code'] == _language)['name']}');
    settings.add('Theme: ${getAvailableThemes().firstWhere((theme) => theme['code'] == _theme)['name']}');
    settings.add('Notifications: ${_notificationsEnabled ? 'On' : 'Off'}');
    settings.add('Voice Reminders: ${_voiceRemindersEnabled ? 'On' : 'Off'}');
    
    if (_userRole == 'caregiver') {
      settings.add('Patient Alerts: ${_patientAlertsEnabled ? 'On' : 'Off'}');
      settings.add('Weekly Reports: ${_weeklyReportsEnabled ? 'On' : 'Off'}');
    }
    
    return settings.join(', ');
  }
} 