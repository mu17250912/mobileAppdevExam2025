import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/subscription_provider.dart';
import '../../utils/constants.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  @override
  void initState() {
    super.initState();
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    subscriptionProvider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, subscriptionProvider, child) {
          if (subscriptionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final plans = subscriptionProvider.getAllPlans();
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Your Plan',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unlock premium features to enhance your event planning experience',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ...plans.entries.map((entry) => _buildPlanCard(
                  entry.key,
                  entry.value,
                  subscriptionProvider,
                )),
                const SizedBox(height: 24),
                if (subscriptionProvider.hasActiveSubscription) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(AppColors.successColor).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(AppColors.successColor),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(AppColors.successColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active Subscription',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(AppColors.successColor),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You currently have an active ${subscriptionProvider.currentSubscription?.planType ?? 'premium'} subscription',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanCard(String planKey, Map<String, dynamic> plan, SubscriptionProvider subscriptionProvider) {
    final isCurrentPlan = subscriptionProvider.currentSubscription?.planType == planKey;
    final isBasic = planKey == 'basic';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isCurrentPlan 
                            ? const Color(AppColors.primaryColor).withValues(alpha: 0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlan 
              ? const Color(AppColors.primaryColor)
              : Colors.grey[300]!,
          width: isCurrentPlan ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan['name'],
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isCurrentPlan 
                        ? const Color(AppColors.primaryColor)
                        : Colors.black87,
                  ),
                ),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(AppColors.primaryColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Current',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  plan['price'] == 0 ? 'Free' : '${plan['price']} ${plan['currency']}',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isCurrentPlan 
                        ? const Color(AppColors.primaryColor)
                        : Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '/month',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Features:',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...(plan['features'] as List<String>).map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: isCurrentPlan 
                        ? const Color(AppColors.primaryColor)
                        : Colors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isBasic || isCurrentPlan
                    ? null
                    : () => _subscribeToPlan(planKey, subscriptionProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrentPlan 
                      ? Colors.grey[300]
                      : const Color(AppColors.primaryColor),
                  foregroundColor: isCurrentPlan 
                      ? Colors.grey[600]
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isBasic 
                      ? 'Current Plan'
                      : isCurrentPlan 
                          ? 'Current Plan'
                          : 'Subscribe Now',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _subscribeToPlan(String planKey, SubscriptionProvider subscriptionProvider) async {
    final success = await subscriptionProvider.createSubscription(
      planType: planKey,
      paymentMethod: 'mobile_money', // Default payment method
      autoRenew: true,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully subscribed to $planKey plan!'),
          backgroundColor: const Color(AppColors.successColor),
        ),
      );
      Get.back();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to subscribe. Please try again.'),
          backgroundColor: Color(AppColors.errorColor),
        ),
      );
    }
  }
} 