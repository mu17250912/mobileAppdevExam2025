import 'package:flutter/material.dart';
import 'custom_top_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionScreen extends StatelessWidget {
  final String? userEmail;
  const SubscriptionScreen({Key? key, this.userEmail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomTopBar(pageName: 'Subscription', userEmail: userEmail),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/home.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            if (width > 600) {
              double cardWidth = (width - 2 * 16 - 2 * 16) / 3;
              cardWidth = cardWidth.clamp(140.0, 320.0);
              return Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _subscriptionCard(
                      context,
                      title: 'Weekly',
                      price: '\$0/Week',
                      color: Colors.amber[700]!,
                      buttonColor: Colors.amber[700]!,
                      textColor: Colors.white,
                      iconColor: Colors.amber[700]!,
                      elevated: false,
                      cardWidth: cardWidth,
                    ),
                    SizedBox(width: 16),
                    _subscriptionCard(
                      context,
                      title: 'Monthly',
                      price: '\$20/Month',
                      color: Colors.blue[700]!,
                      buttonColor: Colors.blue[700]!,
                      textColor: Colors.white,
                      iconColor: Colors.blue[700]!,
                      elevated: true,
                      cardWidth: cardWidth,
                    ),
                    SizedBox(width: 16),
                    _subscriptionCard(
                      context,
                      title: 'Yearly',
                      price: '\$50/Yearly',
                      color: Colors.green[700]!,
                      buttonColor: Colors.green[700]!,
                      textColor: Colors.white,
                      iconColor: Colors.green[700]!,
                      elevated: false,
                      cardWidth: cardWidth,
                    ),
                  ],
                ),
              );
            } else {
              return ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 16,
                ),
                children: [
                  _subscriptionCard(
                    context,
                    title: 'Weekly',
                    price: '\$0/Week',
                    color: Colors.amber[700]!,
                    buttonColor: Colors.amber[700]!,
                    textColor: const Color.fromARGB(255, 100, 6, 243),
                    iconColor: Colors.amber[700]!,
                    elevated: false,
                    cardWidth: double.infinity,
                  ),
                  SizedBox(height: 16),
                  _subscriptionCard(
                    context,
                    title: 'Monthly',
                    price: '\$20/Month',
                    color: Colors.blue[700]!,
                    buttonColor: Colors.blue[700]!,
                    textColor: const Color.fromARGB(255, 5, 30, 221),
                    iconColor: Colors.blue[700]!,
                    elevated: true,
                    cardWidth: double.infinity,
                  ),
                  SizedBox(height: 16),
                  _subscriptionCard(
                    context,
                    title: 'Yearly',
                    price: '\$50/Yearly',
                    color: Colors.green[700]!,
                    buttonColor: Colors.green[700]!,
                    textColor: Colors.white,
                    iconColor: Colors.green[700]!,
                    elevated: false,
                    cardWidth: double.infinity,
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _subscriptionCard(
    BuildContext context, {
    required String title,
    required String price,
    required Color color,
    required Color buttonColor,
    required Color textColor,
    required Color iconColor,
    required bool elevated,
    required double cardWidth,
  }) {
    return Material(
      elevation: elevated ? 12 : 2,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: cardWidth,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 3),
        ),
        child: Column(
          children: [
            Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Icon(Icons.calendar_month, color: iconColor, size: 30),
            SizedBox(height: 6),
            Text(
              price,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => _paymentOptionDialog(context, title),
                    );
                  },
                  child: Text('Sign Up', style: TextStyle(fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentOptionDialog(BuildContext context, String planType) {
    return AlertDialog(
      contentPadding: const EdgeInsets.only(
        top: 10,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      titlePadding: EdgeInsets.zero,
      title: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12.0, left: 16.0, right: 48.0),
            child: Center(
              child: Text(
                "Choose Payment Method",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(),
          ElevatedButton.icon(
            icon: Icon(Icons.phone_android),
            label: Text("Momo"),
            onPressed: () {
              Navigator.of(context).pop();
              _showPaymentForm(context, 'Momo', planType);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              minimumSize: Size(double.infinity, 40),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton.icon(
            icon: Icon(Icons.account_balance),
            label: Text("Bank"),
            onPressed: () {
              Navigator.of(context).pop();
              _showPaymentForm(context, 'Bank', planType);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              minimumSize: Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentForm(BuildContext context, String method, String planType) {
    final _formKey = GlobalKey<FormState>();
    String name = '', email = '', amount = '', phone = '', bankId = '';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          contentPadding: EdgeInsets.only(
            top: 10,
            left: 16,
            right: 16,
            bottom: 16,
          ),
          titlePadding: EdgeInsets.zero,
          title: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 12.0,
                  left: 16.0,
                  right: 48.0,
                ),
                child: Center(
                  child: Text(
                    '$method Payment Form',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Divider(),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    onChanged: (val) => name = val,
                    validator: (val) => val!.isEmpty ? 'Enter name' : null,
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    onChanged: (val) => email = val,
                    validator: (val) => val!.isEmpty ? 'Enter email' : null,
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Money Amount',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => amount = val,
                    validator: (val) => val!.isEmpty ? 'Enter amount' : null,
                  ),
                  SizedBox(height: 8),
                  if (method == 'Momo')
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_android),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (val) => phone = val,
                      validator: (val) => val!.isEmpty ? 'Enter phone number' : null,
                    ),
                  if (method == 'Bank')
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Bank ID',
                        prefixIcon: Icon(Icons.account_balance),
                      ),
                      onChanged: (val) => bankId = val,
                      validator: (val) => val!.isEmpty ? 'Enter bank ID' : null,
                    ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Icon(Icons.check, color: Colors.white),
                    label: Text(isLoading ? 'Processing...' : 'Submit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: method == 'Momo' ? Colors.orangeAccent : Colors.blueAccent,
                      minimumSize: Size(double.infinity, 40),
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            setState(() => isLoading = true);
                            try {
                              await FirebaseFirestore.instance.collection('subscription').add({
                                'name': name,
                                'email': email,
                                'amount': amount,
                                'method': method,
                                'phone': method == 'Momo' ? phone : null,
                                'bankId': method == 'Bank' ? bankId : null,
                                'planType': planType,
                                'timestamp': FieldValue.serverTimestamp(),
                              });
                              await Future.delayed(const Duration(seconds: 2));
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Subscription successful!')),
                              );
                            } catch (e) {
                              setState(() => isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed: $e')),
                              );
                            }
                          },
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
