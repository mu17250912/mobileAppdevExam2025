import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService extends ChangeNotifier {
  static const String _premiumKey = 'is_premium_user';
  static const String _trialEndKey = 'trial_end_date';
  
  bool _isPremium = false;
  DateTime? _trialEndDate;
  bool _isLoading = false;

  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  DateTime? get trialEndDate => _trialEndDate;
  
  // Premium features list
  static const List<PremiumFeature> premiumFeatures = [
    PremiumFeature(
      id: 'advanced_analytics',
      title: 'Advanced Analytics',
      description: 'Detailed sales reports, customer insights, and performance metrics',
      icon: Icons.analytics,
      isComingSoon: false,
    ),
    PremiumFeature(
      id: 'inventory_management',
      title: 'Smart Inventory',
      description: 'Automated stock alerts, low stock notifications, and demand forecasting',
      icon: Icons.inventory_2,
      isComingSoon: false,
    ),
    PremiumFeature(
      id: 'multi_store',
      title: 'Multi-Store Management',
      description: 'Manage multiple store locations from a single dashboard',
      icon: Icons.store,
      isComingSoon: true,
    ),
    PremiumFeature(
      id: 'customer_loyalty',
      title: 'Customer Loyalty Program',
      description: 'Reward customers with points, discounts, and special offers',
      icon: Icons.card_giftcard,
      isComingSoon: true,
    ),
    PremiumFeature(
      id: 'advanced_reports',
      title: 'Advanced Reports',
      description: 'Custom reports, data export, and business intelligence',
      icon: Icons.assessment,
      isComingSoon: true,
    ),
    PremiumFeature(
      id: 'api_integration',
      title: 'API Integration',
      description: 'Connect with third-party services and e-commerce platforms',
      icon: Icons.api,
      isComingSoon: true,
    ),
    PremiumFeature(
      id: 'team_management',
      title: 'Team Management',
      description: 'Manage multiple users, roles, and permissions',
      icon: Icons.people,
      isComingSoon: true,
    ),
    PremiumFeature(
      id: 'backup_sync',
      title: 'Cloud Backup & Sync',
      description: 'Automatic data backup and cross-device synchronization',
      icon: Icons.backup,
      isComingSoon: true,
    ),
  ];

  // Coming soon features
  static const List<PremiumFeature> comingSoonFeatures = [
    PremiumFeature(
      id: 'ai_assistant',
      title: 'AI Sales Assistant',
      description: 'AI-powered recommendations and sales optimization',
      icon: Icons.smart_toy,
      isComingSoon: true,
    ),
    PremiumFeature(
      id: 'voice_commands',
      title: 'Voice Commands',
      description: 'Control your store with voice commands',
      icon: Icons.mic,
      isComingSoon: true,
    ),
    PremiumFeature(
      id: 'qr_payments',
      title: 'QR Code Payments',
      description: 'Accept payments via QR codes',
      icon: Icons.qr_code,
      isComingSoon: true,
    ),
    PremiumFeature(
      id: 'social_media',
      title: 'Social Media Integration',
      description: 'Connect with social media platforms for marketing',
      icon: Icons.share,
      isComingSoon: true,
    ),
  ];

  PremiumService() {
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool(_premiumKey) ?? false;
      
      final trialEndString = prefs.getString(_trialEndKey);
      if (trialEndString != null) {
        _trialEndDate = DateTime.parse(trialEndString);
      } else {
        // Set trial end date to 30 days from now for new users
        _trialEndDate = DateTime.now().add(const Duration(days: 30));
        await prefs.setString(_trialEndKey, _trialEndDate!.toIso8601String());
      }
    } catch (e) {
      print('Error loading premium status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> upgradeToPremium() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Simulate upgrade process
      await Future.delayed(const Duration(seconds: 2));
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumKey, true);
      
      _isPremium = true;
      
      notifyListeners();
    } catch (e) {
      print('Error upgrading to premium: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restorePurchase() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Simulate restore process
      await Future.delayed(const Duration(seconds: 1));
      
      // For demo purposes, always restore as premium
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumKey, true);
      
      _isPremium = true;
      
      notifyListeners();
    } catch (e) {
      print('Error restoring purchase: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isFeatureAvailable(String featureId) {
    if (_isPremium) return true;
    
    final feature = premiumFeatures.firstWhere(
      (f) => f.id == featureId,
      orElse: () => PremiumFeature(
        id: featureId,
        title: '',
        description: '',
        icon: Icons.lock,
        isComingSoon: false,
      ),
    );
    
    return feature.isComingSoon == false;
  }

  bool isFeatureComingSoon(String featureId) {
    final feature = premiumFeatures.firstWhere(
      (f) => f.id == featureId,
      orElse: () => PremiumFeature(
        id: featureId,
        title: '',
        description: '',
        icon: Icons.lock,
        isComingSoon: false,
      ),
    );
    
    return feature.isComingSoon;
  }

  int get daysLeftInTrial {
    if (_trialEndDate == null) return 0;
    final now = DateTime.now();
    final difference = _trialEndDate!.difference(now);
    return difference.inDays > 0 ? difference.inDays : 0;
  }

  bool get isTrialExpired {
    if (_trialEndDate == null) return false;
    return DateTime.now().isAfter(_trialEndDate!);
  }
}

class PremiumFeature {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isComingSoon;

  const PremiumFeature({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isComingSoon,
  });
} 