import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../payment/hdev_payment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PremiumScreen extends StatefulWidget {
  @override
  _PremiumScreenState createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final String _premiumProductId = 'premium_access'; // TODO: Replace with your real product ID

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> showPremiumPaymentDialog(BuildContext context) async {
    final _phoneController = TextEditingController();
    bool loading = false;
    String? statusMessage;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.workspace_premium, color: Colors.amber, size: 32),
                SizedBox(width: 8),
                Text('Go Premium', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Unlock all features for only', style: GoogleFonts.poppins()),
                SizedBox(height: 8),
                Text('500 RWF', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.indigo)),
                SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                ),
                if (statusMessage != null) ...[
                  SizedBox(height: 12),
                  Text(statusMessage!, style: TextStyle(color: Colors.red)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                onPressed: loading
                    ? null
                    : () async {
                        final phone = _phoneController.text.trim();
                        if (phone.isEmpty) {
                          setState(() { statusMessage = 'Enter your phone number.'; });
                          return;
                        }
                        setState(() { loading = true; statusMessage = null; });
                        final user = FirebaseAuth.instance.currentUser;
                        final hdevPayment = HdevPayment(
                          apiId: 'HDEV-2f7b3554-eb27-477b-8ebb-2ca799f03412-ID',
                          apiKey: 'HDEV-28407ece-5d24-438d-a9e8-73105c905a7d-KEY',
                        );
                        final transactionRef = (user?.uid ?? '') + DateTime.now().millisecondsSinceEpoch.toString();
                        final result = await hdevPayment.pay(
                          tel: phone,
                          amount: '500',
                          transactionRef: transactionRef,
                        );
                        if (result != null && result['status'] == 'success') {
                          final expiry = DateTime.now().add(Duration(days: 30));
                          await FirebaseFirestore.instance.collection('users').doc(user?.uid).set({
                            'subscriptionStatus': 'active',
                            'subscriptionType': 'premium',
                            'subscriptionExpiry': expiry,
                            'userType': 'premium',
                          }, SetOptions(merge: true));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Payment request sent. Please approve on your phone.')),
                          );
                        } else {
                          setState(() { statusMessage = result != null ? result['message'] : 'Payment failed.'; loading = false; });
                        }
                      },
                child: loading ? CircularProgressIndicator(color: Colors.white) : Text('Pay & Upgrade'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F8FFF), Color(0xFF6C63FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Premium', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Card(
            color: Colors.white,
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium, color: Colors.amber, size: 60),
                  SizedBox(height: 16),
                  Text('Go Premium!', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 24)),
                  SizedBox(height: 12),
                  Text('Unlock all categories, remove ads, and get exclusive features.', style: GoogleFonts.poppins(fontSize: 16)),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      showPremiumPaymentDialog(context);
                    },
                    child: Text('Upgrade Now'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 