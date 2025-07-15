import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../services/subscription_service.dart';
import '../providers/auth_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late SubscriptionService _subscriptionService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _subscriptionService = SubscriptionService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeaderSection(),
            const SizedBox(height: AppSizes.lg),

            // Subscription Plans
            _buildSubscriptionPlans(),
            const SizedBox(height: AppSizes.lg),

            // Features Comparison
            _buildFeaturesComparison(),
            const SizedBox(height: AppSizes.lg),

            // FAQ Section
            _buildFAQSection(),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        children: [
          Icon(
            Icons.star,
            size: 48,
            color: AppColors.textInverse,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'Upgrade Your Experience',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textInverse,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Get access to premium features and unlock the full potential of our real estate platform.',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textInverse.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Plan',
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          children: [
            Expanded(
              child: _buildPlanCard(
                'Basic',
                '\$${SubscriptionService.subscriptionPricing['basic']}',
                '/month',
                SubscriptionService.tierBasic,
                [
                  'Unlimited property views',
                  'Basic search filters',
                  'Email support',
                  '5 purchase requests per month',
                ],
                isPopular: false,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _buildPlanCard(
                'Premium',
                '\$${SubscriptionService.subscriptionPricing['premium']}',
                '/month',
                SubscriptionService.tierPremium,
                [
                  'All Basic features',
                  'Advanced search filters',
                  'Priority support',
                  'Unlimited purchase requests',
                  'Property alerts',
                  'Saved searches',
                  'No ads',
                ],
                isPopular: true,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _buildPlanCard(
                'Pro',
                '\$${SubscriptionService.subscriptionPricing['pro']}',
                '/month',
                SubscriptionService.tierPro,
                [
                  'All Premium features',
                  'Commissioner dashboard access',
                  'Analytics and insights',
                  'Priority listing placement',
                  'Dedicated support',
                  'Custom branding',
                  'API access',
                ],
                isPopular: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlanCard(
    String title,
    String price,
    String period,
    String tier,
    List<String> features,
    {required bool isPopular}
  ) {
    return Card(
      elevation: isPopular ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: isPopular
            ? BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          children: [
            if (isPopular)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: AppSizes.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Text(
                  'MOST POPULAR',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isPopular) const SizedBox(height: AppSizes.sm),
            Text(
              title,
              style: AppTextStyles.heading4.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  period,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.xs),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Expanded(
                    child: Text(
                      feature,
                      style: AppTextStyles.body2,
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: AppSizes.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _subscribeToPlan(tier),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPopular ? AppColors.primary : AppColors.surface,
                  foregroundColor: isPopular ? AppColors.textInverse : AppColors.primary,
                  side: isPopular
                      ? null
                      : BorderSide(color: AppColors.primary),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Subscribe'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesComparison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feature Comparison',
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: AppSizes.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              children: [
                _buildComparisonRow('Feature', 'Basic', 'Premium', 'Pro'),
                const Divider(),
                _buildComparisonRow('Property Views', 'Unlimited', 'Unlimited', 'Unlimited'),
                _buildComparisonRow('Search Filters', 'Basic', 'Advanced', 'Advanced'),
                _buildComparisonRow('Support', 'Email', 'Priority', 'Dedicated'),
                _buildComparisonRow('Purchase Requests', '5/month', 'Unlimited', 'Unlimited'),
                _buildComparisonRow('Property Alerts', '❌', '✅', '✅'),
                _buildComparisonRow('Saved Searches', '❌', '✅', '✅'),
                _buildComparisonRow('No Ads', '❌', '✅', '✅'),
                _buildComparisonRow('Analytics', '❌', '❌', '✅'),
                _buildComparisonRow('API Access', '❌', '❌', '✅'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonRow(String feature, String basic, String premium, String pro) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              basic,
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              premium,
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              pro,
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: AppSizes.md),
        _buildFAQItem(
          'Can I cancel my subscription anytime?',
          'Yes, you can cancel your subscription at any time. Your access will continue until the end of your current billing period.',
        ),
        _buildFAQItem(
          'Do you offer refunds?',
          'We offer a 30-day money-back guarantee for all new subscriptions. If you\'re not satisfied, contact our support team.',
        ),
        _buildFAQItem(
          'Can I upgrade or downgrade my plan?',
          'Yes, you can change your plan at any time. When upgrading, you\'ll be charged the prorated difference. When downgrading, changes take effect at the next billing cycle.',
        ),
        _buildFAQItem(
          'Is there a free trial?',
          'Yes, we offer a 7-day free trial for all premium plans. No credit card required to start your trial.',
        ),
        _buildFAQItem(
          'What payment methods do you accept?',
          'We accept all major credit cards, debit cards, and mobile money payments through our secure payment gateway.',
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Text(
            answer,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _subscribeToPlan(String tier) async {
    setState(() => _isLoading = true);

    try {
      // Get available products
      final products = await _subscriptionService.getAvailableProducts();
      final product = products.firstWhere(
        (p) => p.id.contains(tier.toLowerCase()),
        orElse: () => products.first,
      );

      // Purchase subscription
      final success = await _subscriptionService.purchaseSubscription(product);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully subscribed to $tier plan!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription failed. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
} 