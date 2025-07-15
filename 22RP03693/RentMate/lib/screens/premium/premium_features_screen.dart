import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/premium_service.dart';

class PremiumFeaturesScreen extends StatelessWidget {
  const PremiumFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isLandlord = user?.userType.toString() == 'UserType.landlord';
    final isPremium = user?.isPremium ?? false;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.star, color: Colors.amber, size: 48),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Premium Features',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Unlock advanced features for landlords',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Features List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFeatureTile(Icons.trending_up, 'Promoted Listings', 'Boost your listings with paid promotions', Colors.green),
                    _buildFeatureTile(Icons.notifications_active, 'Instant Notifications', 'Get notified immediately when students show interest', Colors.indigo),
                    _buildFeatureTile(Icons.bar_chart, 'Market Insights', 'Access to market trends and pricing data', Colors.amber),
                  ],
                ),
              ),
              // Upgrade Button (Landlord only, not already premium)
              if (isLandlord && !isPremium)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.star),
                      label: const Text('Upgrade to Premium'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                      ),
                      onPressed: () async {
                        String? selectedMethod;
                        String phoneNumber = '';
                        bool isProcessing = false;
                        String? errorText;
                        bool isButtonEnabled() {
                          final phone = phoneNumber.trim();
                          return selectedMethod != null &&
                            phone.length == 10 &&
                            phone.startsWith('07') &&
                            RegExp(r'^\d{10}\$').hasMatch(phone) &&
                            !isProcessing;
                        }
                        final confirmed = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return AlertDialog(
                                  title: const Text('Upgrade to Premium'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Subscribe for RWF 9,999/month to unlock all premium features?'),
                                      const SizedBox(height: 16),
                                      const Text('Select Payment Method:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          ChoiceChip(
                                            label: const Text('MTN Mobile Money'),
                                            selected: selectedMethod == 'MTN',
                                            onSelected: (selected) {
                                              selectedMethod = selected ? 'MTN' : null;
                                              setState(() {});
                                            },
                                          ),
                                          const SizedBox(width: 12),
                                          ChoiceChip(
                                            label: const Text('Airtel Money'),
                                            selected: selectedMethod == 'Airtel',
                                            onSelected: (selected) {
                                              selectedMethod = selected ? 'Airtel' : null;
                                              setState(() {});
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        keyboardType: TextInputType.phone,
                                        decoration: InputDecoration(
                                          labelText: 'Mobile Money Number',
                                          prefixIcon: const Icon(Icons.phone),
                                          errorText: errorText,
                                        ),
                                        onChanged: (val) {
                                          phoneNumber = val;
                                          errorText = null;
                                          setState(() {});
                                        },
                                      ),
                                      if (errorText != null) ...[
                                        const SizedBox(height: 4),
                                        Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                                      ],
                                      if (isProcessing) ...[
                                        const SizedBox(height: 16),
                                        const Center(child: CircularProgressIndicator()),
                                      ],
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: isProcessing ? null : () => Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: (!isProcessing)
                                        ? () async {
                                            final phone = phoneNumber.trim();
                                            if (selectedMethod == null) {
                                              setState(() {
                                                errorText = 'Please select a payment method.';
                                              });
                                              return;
                                            }
                                            if (phone.isEmpty) {
                                              setState(() {
                                                errorText = 'Please enter your mobile money number.';
                                              });
                                              return;
                                            }
                                            if (phone.length != 10 || !phone.startsWith('07') || !RegExp(r'^\d{10}$').hasMatch(phone)) {
                                              setState(() {
                                                errorText = 'Please enter a valid 10-digit number starting with 07';
                                              });
                                              return;
                                            }
                                            setState(() => isProcessing = true);
                                            await Future.delayed(const Duration(seconds: 2)); // Simulate payment
                                            setState(() => isProcessing = false);
                                            Navigator.of(context).pop(true);
                                          }
                                        : null,
                                      child: const Text('Pay & Upgrade'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                        if (confirmed == true) {
                          // Simulate payment and upgrade
                          final premiumService = PremiumService();
                          await premiumService.upgradeToPremium(user!);
                          await authProvider.refreshUser();
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => AlertDialog(
                                title: const Text('Congratulations!'),
                                content: const Text('You are now a Premium Landlord!'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),
              if (isPremium)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'You are a Premium Landlord! 🎉',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.amber),
                      ),
                    ),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Cancel anytime. No commitment required.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, String subtitle, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }
} 