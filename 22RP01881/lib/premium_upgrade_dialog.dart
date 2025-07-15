import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'premium_features_summary.dart';

class PremiumUpgradeDialog extends StatelessWidget {
  final String featureName;
  final String? customMessage;
  final VoidCallback? onUpgradePressed;
  final VoidCallback? onMaybeLaterPressed;

  const PremiumUpgradeDialog({
    super.key,
    required this.featureName,
    this.customMessage,
    this.onUpgradePressed,
    this.onMaybeLaterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Premium Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium,
                size: 48,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Premium Feature',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 12),
            
            // Feature Name
            Text(
              featureName,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Message
            Text(
              customMessage ?? 'This feature is only available for Premium users.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Features List
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Premium to unlock:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureList(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onMaybeLaterPressed?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Maybe Later',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onUpgradePressed?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Upgrade Now',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    return Column(
      children: [
        _buildFeatureItem('Advanced Analytics & Reports'),
        _buildFeatureItem('Unlimited Categories'),
        _buildFeatureItem('Saving Goals & Tracking'),
        _buildFeatureItem('Smart Reminders'),
        _buildFeatureItem('AI Spending Insights'),
        _buildFeatureItem('Ad-Free Experience'),
        _buildFeatureItem('Data Export'),
        _buildFeatureItem('Priority Support'),
      ],
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// Extension for easy premium upgrade dialogs
extension PremiumUpgradeExtension on BuildContext {
  void showPremiumUpgradeDialog({
    required String featureName,
    String? customMessage,
    VoidCallback? onUpgradePressed,
    VoidCallback? onMaybeLaterPressed,
  }) {
    showDialog(
      context: this,
      builder: (context) => PremiumUpgradeDialog(
        featureName: featureName,
        customMessage: customMessage,
        onUpgradePressed: onUpgradePressed ?? () {
          Navigator.of(context).pushNamed('/premium');
        },
        onMaybeLaterPressed: onMaybeLaterPressed,
      ),
    );
  }
} 