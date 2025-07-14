import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class PremiumRestrictionWidget extends StatelessWidget {
  final VoidCallback? onUpgrade;
  final String? customMessage;
  final Widget? customIcon;
  final String? customTitle;

  const PremiumRestrictionWidget({
    super.key,
    this.onUpgrade,
    this.customMessage,
    this.customIcon,
    this.customTitle,
  });

  @override
  Widget build(BuildContext context) {
    final Color mainColor = const Color(0xFFFFD600); // Lightning yellow
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';
    
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Premium Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: customIcon ?? Icon(Icons.star, size: 64, color: mainColor),
          ),
          const SizedBox(height: 24),
          
          // Title
          Text(
            customTitle ?? (isFrench 
              ? AppLocalizations.of(context)!.premiumRequired 
              : 'Premium Required'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: mainColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Message
          Text(
            customMessage ?? (isFrench 
              ? AppLocalizations.of(context)!.premiumFeatureMessage 
              : 'This feature is only available for premium users. Upgrade now to unlock advanced analytics, AI insights, and detailed reports.'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Premium Features List
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFrench 
                    ? AppLocalizations.of(context)!.premiumFeatures 
                    : 'Premium Features',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: mainColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isFrench 
                    ? AppLocalizations.of(context)!.premiumFeaturesList 
                    : '• Advanced Analytics & Charts\n• AI Business Insights\n• Detailed Reports\n• Unlimited Data Storage\n• Priority Support',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Upgrade Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: mainColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
                isFrench 
                  ? AppLocalizations.of(context)!.upgradeNow 
                  : 'Upgrade Now',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget to wrap premium features
class PremiumFeatureWrapper extends StatelessWidget {
  final bool isPremium;
  final Widget child;
  final VoidCallback? onUpgrade;
  final String? customMessage;
  final Widget? customIcon;
  final String? customTitle;

  const PremiumFeatureWrapper({
    super.key,
    required this.isPremium,
    required this.child,
    this.onUpgrade,
    this.customMessage,
    this.customIcon,
    this.customTitle,
  });

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return child;
    } else {
      return PremiumRestrictionWidget(
        onUpgrade: onUpgrade,
        customMessage: customMessage,
        customIcon: customIcon,
        customTitle: customTitle,
      );
    }
  }
} 