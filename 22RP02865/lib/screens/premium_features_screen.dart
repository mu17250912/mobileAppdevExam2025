import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/premium_provider.dart';
import '../theme.dart';

class PremiumFeaturesScreen extends StatelessWidget {
  const PremiumFeaturesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Premium Features', style: AppTextStyles.heading),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<PremiumProvider>(
        builder: (context, premiumProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                if (!premiumProvider.isPremium) ...[
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [Colors.amber[600]!, Colors.amber[400]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.star,
                            size: 60,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Unlock Premium Features',
                            style: AppTextStyles.heading.copyWith(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Get access to advanced features and remove limitations',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/premium');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.amber[600],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'Upgrade Now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Features Grid
                Text(
                  'Premium Features',
                  style: AppTextStyles.subheading.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFeaturesGrid(premiumProvider),
                const SizedBox(height: 24),

                // Usage Statistics
                if (premiumProvider.isPremium) ...[
                  Text(
                    'Your Premium Usage',
                    style: AppTextStyles.subheading.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildUsageStatistics(premiumProvider),
                  const SizedBox(height: 24),
                ],

                // Benefits Section
                Text(
                  'Why Choose Premium?',
                  style: AppTextStyles.subheading.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildBenefitsSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturesGrid(PremiumProvider premiumProvider) {
    final features = premiumProvider.getPremiumFeatures();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _buildFeatureCard(feature, premiumProvider.isPremium);
      },
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature, bool isPremium) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isPremium
              ? LinearGradient(
                  colors: [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                feature['icon'] as IconData,
                size: 48,
                color: isPremium ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                feature['name'] as String,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                feature['description'] as String,
                style: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Icon(
                isPremium ? Icons.check_circle : Icons.lock,
                color: isPremium ? Colors.green : Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsageStatistics(PremiumProvider premiumProvider) {
    final status = premiumProvider.getPremiumStatus();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  'Plan',
                  status['plan'] ?? 'Unknown',
                  Icons.star,
                ),
                _buildStatItem(
                  'Days Left',
                  '${status['daysRemaining']}',
                  Icons.schedule,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  'Features',
                  '${premiumProvider.getPremiumFeatures().length}',
                  Icons.featured_play_list,
                ),
                _buildStatItem(
                  'Status',
                  status['isExpired'] ? 'Expired' : 'Active',
                  status['isExpired'] ? Icons.warning : Icons.check_circle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading.copyWith(
              fontSize: 18,
              color: AppColors.primary,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    final benefits = [
      {
        'title': 'Unlimited Tasks',
        'description': 'Create as many study tasks as you need without any restrictions.',
        'icon': Icons.all_inclusive,
      },
      {
        'title': 'Advanced Analytics',
        'description': 'Get detailed insights into your study patterns and progress over time.',
        'icon': Icons.analytics,
      },
      {
        'title': 'Ad-Free Experience',
        'description': 'Enjoy a clean, distraction-free study environment.',
        'icon': Icons.block,
      },
      {
        'title': 'Cloud Backup',
        'description': 'Your data is automatically backed up and synced across devices.',
        'icon': Icons.backup,
      },
      {
        'title': 'Priority Support',
        'description': 'Get faster response times and dedicated support when you need help.',
        'icon': Icons.priority_high,
      },
      {
        'title': 'Custom Themes',
        'description': 'Personalize the app with beautiful themes and color schemes.',
        'icon': Icons.palette,
      },
    ];

    return Column(
      children: benefits.map((benefit) => Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Icon(
            benefit['icon'] as IconData,
            color: AppColors.primary,
            size: 28,
          ),
          title: Text(
            benefit['title'] as String,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            benefit['description'] as String,
            style: AppTextStyles.body.copyWith(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ),
      )).toList(),
    );
  }
} 