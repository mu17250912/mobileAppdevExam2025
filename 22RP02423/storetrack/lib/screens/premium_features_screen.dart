import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/premium_service.dart';
import '../widgets/upgrade_banner.dart';
import 'coming_soon_screen.dart';

class PremiumFeaturesScreen extends StatelessWidget {
  const PremiumFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Features'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Upgrade banner
            const UpgradeBanner(),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  _buildHeaderSection(),
                  
                  const SizedBox(height: 32),
                  
                  // Premium features
                  _buildFeaturesSection(
                    'Premium Features',
                    PremiumService.premiumFeatures,
                    context,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Coming soon features
                  _buildFeaturesSection(
                    'Coming Soon',
                    PremiumService.comingSoonFeatures,
                    context,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Upgrade section
                  _buildUpgradeSection(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Consumer<PremiumService>(
      builder: (context, premiumService, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                premiumService.isPremium ? Icons.star : Icons.star_border,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                premiumService.isPremium ? 'Premium Active' : 'Upgrade to Premium',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                premiumService.isPremium
                    ? 'You have access to all premium features'
                    : 'Unlock advanced features and analytics',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              if (!premiumService.isPremium && !premiumService.isTrialExpired) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${premiumService.daysLeftInTrial} days left in trial',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeaturesSection(
    String title,
    List<PremiumFeature> features,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...features.map((feature) => _buildFeatureCard(feature, context)),
      ],
    );
  }

  Widget _buildFeatureCard(PremiumFeature feature, BuildContext context) {
    return Consumer<PremiumService>(
      builder: (context, premiumService, child) {
        final isAvailable = premiumService.isFeatureAvailable(feature.id);
        final isComingSoon = feature.isComingSoon;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isAvailable
                ? () {
                    // Navigate to feature or show coming soon
                    if (isComingSoon) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ComingSoonScreen(
                            featureId: feature.id,
                            featureTitle: feature.title,
                            featureDescription: feature.description,
                            featureIcon: feature.icon,
                          ),
                        ),
                      );
                    }
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getFeatureColor(feature, premiumService).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      feature.icon,
                      color: _getFeatureColor(feature, premiumService),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                feature.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            _buildStatusBadge(feature, premiumService),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feature.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isAvailable && !isComingSoon)
                    Icon(
                      Icons.lock,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getFeatureColor(PremiumFeature feature, PremiumService premiumService) {
    if (premiumService.isPremium) return Colors.green;
    if (feature.isComingSoon) return Colors.orange;
    if (premiumService.isFeatureAvailable(feature.id)) return Colors.blue;
    return Colors.grey;
  }

  Widget _buildStatusBadge(PremiumFeature feature, PremiumService premiumService) {
    if (premiumService.isPremium) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Active',
          style: TextStyle(
            color: Colors.green,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    
    if (feature.isComingSoon) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Soon',
          style: TextStyle(
            color: Colors.orange,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    
    if (premiumService.isFeatureAvailable(feature.id)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Free',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Premium',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildUpgradeSection(BuildContext context) {
    return Consumer<PremiumService>(
      builder: (context, premiumService, child) {
        if (premiumService.isPremium) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.star,
                size: 48,
                color: Color(0xFF667eea),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ready to upgrade?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Get access to all premium features and unlock your business potential',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: premiumService.isLoading
                      ? null
                      : () => _showUpgradeDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: premiumService.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Upgrade Now',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UpgradeDialog(),
    );
  }
} 