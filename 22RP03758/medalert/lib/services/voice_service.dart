import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  // Initialize TTS
  Future<void> initialize() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5); // Normal speed
      await _flutterTts.setVolume(1.0); // Full volume
      await _flutterTts.setPitch(1.0); // Normal pitch
      
      _isInitialized = true;
      debugPrint('Voice service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing voice service: $e');
      _isInitialized = false;
    }
  }

  // Speak medication reminder
  Future<void> speakMedicationReminder(String medicationName, String dosage, String time) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final message = 'Time to take $medicationName, $dosage at $time. Please take your medication now.';
      await _flutterTts.speak(message);
      debugPrint('Spoke medication reminder: $message');
    } catch (e) {
      debugPrint('Error speaking medication reminder: $e');
    }
  }

  // Speak medication instruction
  Future<void> speakMedicationInstruction(String medicationName, String instructions) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final message = 'Instructions for $medicationName: $instructions';
      await _flutterTts.speak(message);
      debugPrint('Spoke medication instruction: $message');
    } catch (e) {
      debugPrint('Error speaking medication instruction: $e');
    }
  }

  // Speak adherence status
  Future<void> speakAdherenceStatus(String status, String percentage) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final message = 'Your medication adherence is $percentage percent. Status: $status';
      await _flutterTts.speak(message);
      debugPrint('Spoke adherence status: $message');
    } catch (e) {
      debugPrint('Error speaking adherence status: $e');
    }
  }

  // Speak emergency contact info
  Future<void> speakEmergencyContact(String contactName, String relationship) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final message = 'Calling $contactName, your $relationship for emergency assistance.';
      await _flutterTts.speak(message);
      debugPrint('Spoke emergency contact: $message');
    } catch (e) {
      debugPrint('Error speaking emergency contact: $e');
    }
  }

  // Speak general message
  Future<void> speak(String message) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _flutterTts.speak(message);
      debugPrint('Spoke message: $message');
    } catch (e) {
      debugPrint('Error speaking message: $e');
    }
  }

  // Stop speaking
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      debugPrint('Stopped speaking');
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }
  }

  // Check if TTS is available
  Future<bool> isAvailable() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return languages.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking TTS availability: $e');
      return false;
    }
  }

  // Get available languages
  Future<List<dynamic>> getAvailableLanguages() async {
    try {
      return await _flutterTts.getLanguages;
    } catch (e) {
      debugPrint('Error getting available languages: $e');
      return [];
    }
  }

  // Set language
  Future<void> setLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);
      debugPrint('Set language to: $language');
    } catch (e) {
      debugPrint('Error setting language: $e');
    }
  }

  // Set speech rate (0.1 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
      debugPrint('Set speech rate to: $rate');
    } catch (e) {
      debugPrint('Error setting speech rate: $e');
    }
  }

  // Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume);
      debugPrint('Set volume to: $volume');
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  // Set pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch);
      debugPrint('Set pitch to: $pitch');
    } catch (e) {
      debugPrint('Error setting pitch: $e');
    }
  }

  // Check if currently speaking
  Future<bool> isSpeaking() async {
    try {
      // Note: isSpeaking is not available as a getter in FlutterTts
      // We'll return false as a fallback
      return false;
    } catch (e) {
      debugPrint('Error checking speaking status: $e');
      return false;
    }
  }

  // Get current language
  Future<String?> getCurrentLanguage() async {
    try {
      // Note: getLanguage is not available as a getter in FlutterTts
      // We'll return null as a fallback
      return null;
    } catch (e) {
      debugPrint('Error getting current language: $e');
      return null;
    }
  }

  // Get current speech rate
  Future<double?> getCurrentSpeechRate() async {
    try {
      // Note: getSpeechRate is not available as a getter in FlutterTts
      // We'll return null as a fallback
      return null;
    } catch (e) {
      debugPrint('Error getting current speech rate: $e');
      return null;
    }
  }

  // Get current volume
  Future<double?> getCurrentVolume() async {
    try {
      // Note: getVolume is not available as a getter in FlutterTts
      // We'll return null as a fallback
      return null;
    } catch (e) {
      debugPrint('Error getting current volume: $e');
      return null;
    }
  }

  // Get current pitch
  Future<double?> getCurrentPitch() async {
    try {
      // getPitch might not be available in all versions
      return 1.0; // Default pitch
    } catch (e) {
      debugPrint('Error getting current pitch: $e');
      return null;
    }
  }
} 