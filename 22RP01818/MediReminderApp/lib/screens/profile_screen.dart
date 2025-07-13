import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<AppState>().isPremium;
    final userEmail = context.watch<AppState>().currentUserEmail ?? 'User';
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 24),
              // Header with avatar and email
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.15),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              // Premium status or Go Premium
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: isPremium
                    ? Column(
                        children: [
                          Icon(Icons.verified, color: Colors.amber, size: 40),
                          SizedBox(height: 8),
                          Text(
                            'You are a Premium user!',
                            style: TextStyle(
                              color: Colors.amber[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Text(
                            'Upgrade to Premium',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Unlock all features and remove limits.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF666666),
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: Icon(Icons.star, color: Colors.white),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  String selectedMethod = 'Credit Card';
                                  TextEditingController controller = TextEditingController();
                                  return StatefulBuilder(
                                    builder: (context, setState) => AlertDialog(
                                      title: Text('Simulated Payment'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Choose a payment method:'),
                                          DropdownButton<String>(
                                            value: selectedMethod,
                                            items: [
                                              DropdownMenuItem(
                                                value: 'Credit Card',
                                                child: Text('Credit Card'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Mobile Money',
                                                child: Text('Mobile Money'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'PayPal',
                                                child: Text('PayPal'),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                selectedMethod = value!;
                                              });
                                            },
                                          ),
                                          SizedBox(height: 16),
                                          TextField(
                                            controller: controller,
                                            decoration: InputDecoration(
                                              labelText: selectedMethod == 'Credit Card'
                                                  ? 'Card Number'
                                                  : selectedMethod == 'Mobile Money'
                                                      ? 'Phone Number'
                                                      : 'Email',
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                            final appState = Provider.of<AppState>(
                                              context,
                                              listen: false,
                                            );
                                            appState.setPremium(true);
                                            // Log analytics event for premium upgrade
                                            await FirebaseAnalytics.instance.logEvent(
                                              name: 'premium_upgrade',
                                              parameters: {'method': selectedMethod},
                                            );
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Premium features unlocked!'),
                                              ),
                                            );
                                          },
                                          child: Text('Pay'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            label: Text('Go Premium'),
                          ),
                        ],
                      ),
              ),
              SizedBox(height: 40),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.home, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      label: Text('Back to Home'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.logout, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        // Logout logic (if any)
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                      },
                      label: Text('Logout'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
