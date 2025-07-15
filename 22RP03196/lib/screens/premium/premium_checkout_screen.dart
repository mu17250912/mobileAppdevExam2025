import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class PremiumCheckoutScreen extends StatefulWidget {
  const PremiumCheckoutScreen({super.key});

  @override
  State<PremiumCheckoutScreen> createState() => _PremiumCheckoutScreenState();
}

class _PremiumCheckoutScreenState extends State<PremiumCheckoutScreen> {
  final _cardController = TextEditingController();
  final _expController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final planType = args != null && args['planType'] != null ? args['planType'] as String : 'one-time';
    return StreamBuilder<AppUser?>(
      stream: AuthService().user,
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            backgroundColor: const Color(0xFF22A6F2),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data!;
        return Scaffold(
          backgroundColor: const Color(0xFF22A6F2),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Spacer(),
                  Icon(Icons.credit_card, color: Colors.white, size: 80),
                  SizedBox(height: 24),
                  Text('Checkout', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(planType == 'one-time' ? 'One-time Premium' : planType == 'monthly' ? 'Monthly Subscription' : 'Annual Subscription',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                  SizedBox(height: 18),
                  TextField(
                    controller: _cardController,
                    decoration: InputDecoration(
                      hintText: 'Card number',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _expController,
                          decoration: InputDecoration(
                            hintText: 'Expiration',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          keyboardType: TextInputType.datetime,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _cvvController,
                          decoration: InputDecoration(
                            hintText: 'CVV',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          keyboardType: TextInputType.number,
                          obscureText: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : () => _pay(user, planType),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF22A6F2),
                      minimumSize: Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      textStyle: TextStyle(fontSize: 18),
                      elevation: 2,
                    ),
                    child: _loading ? CircularProgressIndicator() : Text('Pay 9.99', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'This is a simulated payment. No real transaction will occur.\nFor educational/assignment demonstration only.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pay(AppUser user, String planType) async {
    setState(() => _loading = true);
    try {
      // Update user premium and subscription info
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final subData = planType == 'one-time'
        ? {'isPremium': true}
        : {
            'isPremium': true,
            'subscription': {
              'type': planType,
              'startDate': FieldValue.serverTimestamp(),
            },
          };
      await userRef.set({
        'uid': user.uid,
        'email': user.email,
        ...subData,
      }, SetOptions(merge: true));

      // Fetch latest user info
      final userDoc = await userRef.get();
      final userData = userDoc.data() ?? {};
      final userEmail = userData['email'] ?? user.email ?? '';
      final userName = userData['name'] ?? user.name ?? '';

      await FirebaseFirestore.instance.collection('payments').add({
        'userId': user.uid,
        'userEmail': userEmail,
        'userName': userName,
        'amount': planType == 'annual' ? 99.99 : planType == 'monthly' ? 14.99 : 9.99,
        'planType': planType,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushNamed(context, '/premium_success');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
} 