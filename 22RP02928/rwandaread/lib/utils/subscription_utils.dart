import '../services/subscription_service.dart';

class SubscriptionUtils {
  static final SubscriptionService _subscriptionService = SubscriptionService();

  /// Check if user has access to premium features
  static Future<bool> hasPremiumAccess() async {
    try {
      return await _subscriptionService.isUserSubscribed();
    } catch (e) {
      print('Error checking premium access: $e');
      return false;
    }
  }

  /// Check if user can download books (premium feature)
  static Future<bool> canDownloadBooks() async {
    return await hasPremiumAccess();
  }

  /// Check if user can access unlimited searches (premium feature)
  static Future<bool> canUnlimitedSearch() async {
    return await hasPremiumAccess();
  }

  /// Check if user can access advanced bookmarks (premium feature)
  static Future<bool> canAdvancedBookmarks() async {
    return await hasPremiumAccess();
  }

  /// Check if user can access priority support (premium feature)
  static Future<bool> canPrioritySupport() async {
    return await hasPremiumAccess();
  }

  /// Check if user can access exclusive content (premium feature)
  static Future<bool> canExclusiveContent() async {
    return await hasPremiumAccess();
  }

  /// Get subscription status message
  static Future<String> getSubscriptionStatusMessage() async {
    try {
      final isSubscribed = await _subscriptionService.isUserSubscribed();
      if (isSubscribed) {
        final subscription = await _subscriptionService.getCurrentSubscription();
        if (subscription != null) {
          if (subscription.isExpired) {
            return 'Your subscription has expired. Renew to continue enjoying premium features.';
          } else if (subscription.isExpiringSoon) {
            return 'Your subscription expires in ${subscription.daysRemaining} days.';
          } else {
            return 'You have an active premium subscription.';
          }
        }
      }
      return 'Upgrade to premium to unlock unlimited features.';
    } catch (e) {
      return 'Unable to check subscription status.';
    }
  }

  /// Get feature description based on subscription status
  static String getFeatureDescription(String featureName, bool isPremium) {
    if (isPremium) {
      return '$featureName (Premium)';
    }
    return '$featureName (Free)';
  }

  /// Get premium feature list
  static List<String> getPremiumFeatures() {
    return [
      'Unlimited book downloads',
      'Advanced search filters',
      'Priority customer support',
      'Exclusive content access',
      'Ad-free experience',
      'Reading progress sync',
      'Advanced bookmarks',
      'Early access to new features',
    ];
  }

  /// Get free feature list
  static List<String> getFreeFeatures() {
    return [
      'Basic book reading',
      'Limited search',
      'Basic bookmarks',
      'Reading progress tracking',
      'Standard support',
    ];
  }
} 