import 'package:flutter/material.dart';
import '../services/freemium_service.dart';
import '../services/ad_service.dart';
import '../widgets/custom_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final FreemiumService _freemiumService = FreemiumService();
  final AdService _adService = AdService();
  bool _isLoading = true;
  bool _isPremium = false;
  Map<String, dynamic> _usageStats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final isPremium = await _freemiumService.isPremium();
    final usageStats = await _freemiumService.getUsageStats();
    
    setState(() {
      _isPremium = isPremium;
      _usageStats = usageStats;
      _isLoading = false;
    });
  }

  Future<void> _upgradeToPremium() async {
    try {
      await _freemiumService.upgradeToPremium(days: 30);
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upgraded to Premium for 30 days!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downgradeToFree() async {
    try {
      await _freemiumService.downgradeToFree();
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downgraded to Free plan'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _simulatePaymentAndCheck() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Simulate payment process
    await Future.delayed(Duration(seconds: 2));
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({'isPremium': true}, SetOptions(merge: true));
    // Fetch the document to confirm
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    final isPremium = data != null && data['isPremium'] == true;
    print('DEBUG: Firestore isPremium value: $isPremium');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Premium Status'),
        content: Text(isPremium
            ? 'Firestore update successful! You are now premium.'
            : 'Firestore update failed. Please check your rules or network.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
    if (isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment simulated! You are now premium.')),
      );
    }
  }

  Future<void> _simulateMobileMoneyPayment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String mobileNumber = '';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Mobile Money Payment'),
          content: TextField(
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Enter Mobile Money Number',
              hintText: 'e.g. 07XXXXXXXX',
            ),
            onChanged: (val) => mobileNumber = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (mobileNumber.isNotEmpty) {
                  Navigator.of(context).pop(true);
                }
              },
              child: Text('Pay'),
            ),
          ],
        );
      },
    );
    if (result == true) {
      // Simulate payment processing
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Processing Payment'),
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Processing...'),
            ],
          ),
        ),
      );
      await Future.delayed(Duration(seconds: 2));
      Navigator.of(context).pop(); // Close processing dialog
      // Set user as premium
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'isPremium': true}, SetOptions(merge: true));
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Payment Successful!'),
          content: Text('You are now a premium user.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment simulated! You are now premium.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Premium Features')),
        body: const Center(child: Text('You must be logged in.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Features'),
        // Removed leading back arrow
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final isPremium = data != null && data['isPremium'] == true;
          print('DEBUG: StreamBuilder isPremium value: $isPremium');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, size: 64, color: Colors.deepPurple),
                  const SizedBox(height: 16),
                  Text(
                    isPremium
                        ? 'You are a premium user!\nThank you for supporting us.'
                        : 'Upgrade to Premium\nGet unlimited access to all features.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  if (!isPremium) ...[
                    const Divider(height: 32, thickness: 2),
                    const Text(
                      'Simulated Payment Gateway',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _simulateMobileMoneyPayment,
                      child: const Text('Upgrade with Mobile Money'),
                    ),
                  ],
                  if (isPremium)
                    Column(
                      children: [
                        const Text(
                          'Premium features unlocked!\nEnjoy your experience.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .set({'isPremium': false}, SetOptions(merge: true));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('You have been downgraded to free.')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Downgrade to Free'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUsageStats() {
    return Column(
      children: [
        _buildUsageCard('Students', _usageStats['students'] ?? {}, Icons.people),
        _buildUsageCard('Courses', _usageStats['courses'] ?? {}, Icons.book),
        _buildUsageCard('Attendance', _usageStats['attendance'] ?? {}, Icons.checklist),
        _buildUsageCard('Grades', _usageStats['grades'] ?? {}, Icons.grade),
      ],
    );
  }

  Widget _buildUsageCard(String title, Map<String, dynamic> stats, IconData icon) {
    final used = stats['used'] ?? 0;
    final limit = stats['limit'] ?? 0;
    final remaining = stats['remaining'] ?? 0;
    final percentage = limit > 0 ? (used / limit) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '$used / $limit used',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$remaining left',
                style: TextStyle(
                  fontSize: 12,
                  color: remaining > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 60,
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentage > 0.8 ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureComparison() {
    return Column(
      children: [
        _buildFeatureRow('Students', '10', 'Unlimited', Icons.people),
        _buildFeatureRow('Courses', '5', 'Unlimited', Icons.book),
        _buildFeatureRow('Attendance Records', '50', 'Unlimited', Icons.checklist),
        _buildFeatureRow('Grade Records', '100', 'Unlimited', Icons.grade),
        _buildFeatureRow('Advanced Analytics', '❌', '✅', Icons.analytics),
        _buildFeatureRow('Priority Support', '❌', '✅', Icons.support_agent),
        _buildFeatureRow('Ad-Free Experience', '❌', '✅', Icons.block),
        _buildFeatureRow('Export Data', '❌', '✅', Icons.download),
        _buildFeatureRow('Custom Branding', '❌', '✅', Icons.palette),
      ],
    );
  }

  Widget _buildFeatureRow(String feature, String free, String premium, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              free,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              premium,
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 