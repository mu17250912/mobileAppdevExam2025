import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PremiumFeaturesManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> isPremium() async {
    // Legacy global premium (for backward compatibility)
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;
      final data = doc.data()!;
      final isPremium = data['isPremium'] ?? false;
      if (!isPremium) return false;
      final subscriptionType = data['subscriptionType'];
      if (subscriptionType != 'lifetime') {
        final expiryDate = data['premiumExpiryDate'] as Timestamp?;
        if (expiryDate != null && DateTime.now().isAfter(expiryDate.toDate())) {
          await _firestore.collection('users').doc(user.uid).update({
            'isPremium': false,
            'subscriptionType': null,
            'premiumExpiryDate': null,
          });
          return false;
        }
      }
      return true;
    } catch (e) {
      print('Error checking premium status: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getPremiumStats() async {
    final user = _auth.currentUser;
    if (user == null) return {};
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return {};
      return doc.data()!;
    } catch (e) {
      print('Error getting premium stats: $e');
      return {};
    }
  }

  // --- FEATURE-SPECIFIC PREMIUM ---
  Future<bool> isFeatureUnlocked(String featureKey) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;
      final data = doc.data()!;
      final premiumFeatures = data['premiumFeatures'] as Map<String, dynamic>?;
      if (premiumFeatures == null) return false;
      return premiumFeatures[featureKey] == true;
    } catch (e) {
      print('Error checking feature premium: $e');
      return false;
    }
  }

  Future<void> unlockFeature(String featureKey) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'premiumFeatures': {featureKey: true}
      }, SetOptions(merge: true));
      print('Feature $featureKey unlocked for user');
    } catch (e) {
      print('Error unlocking feature: $e');
      rethrow;
    }
  }

  Future<void> unlockAllPremiumFeatures() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'premiumFeatures': {
          'savingGoals': true,
          'smartReminders': true,
          'advancedReports': true,
          'aiInsights': true,
          'unlimitedCategories': true,
        }
      }, SetOptions(merge: true));
      print('All premium features unlocked successfully');
    } catch (e) {
      print('Error unlocking all premium features: $e');
      rethrow;
    }
  }

  Future<void> grantPremiumAccess(String paymentMethod, String transactionId) async {
    // Legacy global premium
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    try {
      final expiryDate = DateTime.now().add(const Duration(days: 30));
      
      // Update user's premium status
      await _firestore.collection('users').doc(user.uid).update({
        'isPremium': true,
        'subscriptionType': 'monthly',
        'premiumSince': FieldValue.serverTimestamp(),
        'premiumExpiryDate': Timestamp.fromDate(expiryDate),
        'lastPurchaseDate': FieldValue.serverTimestamp(),
        'paymentMethod': paymentMethod,
        'lastTransactionId': transactionId,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Unlock specific premium features
      await _firestore.collection('users').doc(user.uid).set({
        'premiumFeatures': {
          'savingGoals': true,
          'smartReminders': true,
          'advancedReports': true,
          'aiInsights': true,
          'unlimitedCategories': true,
        }
      }, SetOptions(merge: true));
      
      // Record the purchase
      await _firestore.collection('purchases').add({
        'userId': user.uid,
        'productId': 'smartbudget_premium_monthly',
        'subscriptionType': 'monthly',
        'purchaseDate': FieldValue.serverTimestamp(),
        'purchaseToken': transactionId,
        'amount': 100.0, // Updated to 100 FRW
        'currency': 'FRW',
        'status': 'completed',
        'platform': paymentMethod,
        'paymentMethod': paymentMethod,
        'unlockedFeatures': ['savingGoals', 'smartReminders', 'advancedReports', 'aiInsights', 'unlimitedCategories'],
      });
      
      print('Premium access granted successfully with all features unlocked');
    } catch (e) {
      print('Error granting premium access: $e');
      rethrow;
    }
  }
}

class PremiumFeaturesSummary extends StatelessWidget {
  const PremiumFeaturesSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium,
                color: Theme.of(context).colorScheme.secondary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Premium Features',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Price Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Only 100 FRW',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Features List
          _buildFeatureItem('Advanced Analytics & Reports', true),
          _buildFeatureItem('Unlimited Categories', true),
          _buildFeatureItem('Saving Goals & Tracking', true),
          _buildFeatureItem('Smart Reminders', true),
          _buildFeatureItem('AI Spending Insights', true),
          _buildFeatureItem('Ad-Free Experience', true),
          _buildFeatureItem('Multi-Device Sync', true),
          _buildFeatureItem('Export Data', true),
          _buildFeatureItem('Priority Support', true),
          _buildFeatureItem('Custom Budgets', true),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '30 days of premium access for just 100 FRW',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature, bool isIncluded) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isIncluded ? Icons.check_circle : Icons.cancel,
            color: isIncluded 
                ? Colors.green 
                : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isIncluded 
                    ? null
                    : Colors.grey.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 