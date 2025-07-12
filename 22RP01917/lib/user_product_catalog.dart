import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart'; // For Product model
import 'user_booking_status.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'rwanda_colors.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'widgets/ad_banner.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class UserProductCatalog extends StatefulWidget {
  const UserProductCatalog({Key? key}) : super(key: key);

  @override
  State<UserProductCatalog> createState() => _UserProductCatalogState();
}

class _UserProductCatalogState extends State<UserProductCatalog> {
  bool isPremium = false;
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  CollectionReference get _productsRef => FirebaseFirestore.instance.collection('products');
  CollectionReference get _bookingsRef => FirebaseFirestore.instance.collection('bookings');

  void _bookProduct(BuildContext context, Product product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to book.')),
      );
      return;
    }
    int quantity = 1;
    double total = product.price;
    final quantityController = TextEditingController(text: '1');
    bool isLoading = false;
    String? quantityError;
    String paymentMethod = 'PayPal';
    await showDialog(
      context: context,
      barrierDismissible: !isLoading,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            int? parsedQuantity = int.tryParse(quantityController.text);
            double currentTotal = (parsedQuantity != null && parsedQuantity > 0) ? parsedQuantity * product.price : product.price;
            return AlertDialog(
              title: Text('Book ${product.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Available: ${product.quantity}'),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      errorText: quantityError,
                    ),
                    onChanged: (val) {
                      setState(() {
                        quantityError = null;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text('Total: \$${currentTotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('PayPal'),
                          value: 'PayPal',
                          groupValue: paymentMethod,
                          onChanged: isLoading ? null : (val) => setState(() => paymentMethod = val!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('MTN Mobile Money'),
                          value: 'MTN',
                          groupValue: paymentMethod,
                          onChanged: isLoading ? null : (val) => setState(() => paymentMethod = val!),
                        ),
                      ),
                    ],
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final q = int.tryParse(quantityController.text ?? '');
                          if (q == null || q < 1 || q > product.quantity) {
                            setState(() {
                              quantityError = 'Enter a valid quantity (1-${product.quantity})';
                            });
                            return;
                          }
                          quantity = q;
                          total = quantity * product.price;
                          setState(() => isLoading = true);
                          Navigator.pop(context);
                          bool paid = false;
                          String usedPayment = paymentMethod;
                          if (paymentMethod == 'PayPal') {
                            paid = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Row(
                                  children: [
                                    Image.network('https://www.paypalobjects.com/webstatic/icon/pp258.png', height: 32),
                                    const SizedBox(width: 8),
                                    const Text('Pay with PayPal'),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Amount: \$${total.toStringAsFixed(2)}'),
                                    const SizedBox(height: 12),
                                    const Text('This is a payment simulation.'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Pay'),
                                  ),
                                ],
                              ),
                            ) ?? false;
                          } else if (paymentMethod == 'MTN') {
                            final phoneController = TextEditingController();
                            paid = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Row(
                                  children: [
                                    Icon(Icons.phone_android, color: Colors.yellow[800]),
                                    const SizedBox(width: 8),
                                    const Text('MTN Mobile Money'),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Amount: \$${total.toStringAsFixed(2)}'),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: phoneController,
                                      keyboardType: TextInputType.phone,
                                      decoration: const InputDecoration(labelText: 'MTN Phone Number'),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text('This is a payment simulation.'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (phoneController.text.isEmpty || phoneController.text.length < 8) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Enter a valid MTN number.')),
                                        );
                                        return;
                                      }
                                      Navigator.pop(context, true);
                                    },
                                    child: const Text('Pay'),
                                  ),
                                ],
                              ),
                            ) ?? false;
                          }
                          if (paid == true) {
                            final commission = (total * 0.05).toStringAsFixed(2);
                            try {
                              await _bookingsRef.add({
                                'productId': product.id,
                                'productName': product.name,
                                'status': 'Pending',
                                'userUid': user.uid,
                                'userEmail': user.email,
                                'price': product.price,
                                'quantity': quantity,
                                'total': total,
                                'commission': commission,
                                'paid': true,
                                'paymentMethod': usedPayment,
                                'timestamp': FieldValue.serverTimestamp(),
                              });
                              // Reduce product quantity
                              await _productsRef.doc(product.id).update({
                                'quantity': product.quantity - quantity,
                              });
                              await analytics.logEvent(
                                name: 'booking_made',
                                parameters: {
                                  'product_id': product.id,
                                  'product_name': product.name,
                                  'quantity': quantity,
                                  'total': total,
                                  'user_id': user.uid,
                                  'payment_method': usedPayment,
                                },
                              );
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Payment Successful'),
                                  content: Text('You have paid for: ${product.name}\nQuantity: ${quantity}\nTotal: \$${total.toStringAsFixed(2)}\nPayment Method: $usedPayment'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            } catch (e) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Error'),
                                  content: Text('Failed to complete booking: ${e.toString()}'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Payment Cancelled'),
                                content: const Text('Your payment was not completed.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                  child: const Text('Pay'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to leave feedback.')),
      );
      return;
    }
    int rating = 5;
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leave Feedback'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    rating = index + 1;
                    (context as Element).markNeedsBuild();
                  },
                )),
              ),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(labelText: 'Comment'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final feedback = {
                  'userId': user.uid,
                  'rating': rating,
                  'comment': commentController.text,
                  'timestamp': FieldValue.serverTimestamp(),
                };
                await FirebaseFirestore.instance.collection('feedback').add(feedback);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thank you for your feedback!')),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _showProfileDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final referralCode = userDoc.data()?['referralCode'] ?? user.uid;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Email: ${user.email}'),
            const SizedBox(height: 12),
            SelectableText('Referral Code: ${referralCode}'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy Referral Code'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: referralCode));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Referral code copied!')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPremiumDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber),
            SizedBox(width: 8),
            Text('Upgrade to Premium'),
          ],
        ),
        content: Text('Unlock premium features for only \$2.99!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Upgrade'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        isPremium = true;
      });
      await analytics.logEvent(
        name: 'premium_upgrade',
        parameters: {
          'user_id': FirebaseAuth.instance.currentUser?.uid ?? '',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You are now a Premium user!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kRwandaBlue,
        title: Row(
          children: [
            const Text('Product Catalog', style: TextStyle(color: Colors.white)),
            if (isPremium) ...[
              SizedBox(width: 8),
              Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
              Text('Premium', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ],
            const Spacer(),
            Icon(Icons.wb_sunny, color: kRwandaSun, size: 28),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: Icon(Icons.workspace_premium),
                label: Text(isPremium ? 'You are Premium!' : 'Upgrade to Premium'),
                onPressed: isPremium ? null : _showPremiumDialog,
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('announcements').orderBy('timestamp', descending: true).limit(1).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                final msg = (snapshot.data!.docs.first.data() as Map<String, dynamic>)['message'] ?? '';
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kRwandaYellow,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.campaign, color: kRwandaBlue),
                      const SizedBox(width: 8),
                      Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kRwandaBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.list_alt),
                label: const Text('My Bookings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserBookingStatusScreen()),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kRwandaGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.account_circle),
                label: const Text('My Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => _showProfileDialog(context),
              ),
            ),
          ),
          if (!kIsWeb) AdBanner(), // Only show AdMob banner on mobile
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _productsRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No products available.'));
                }
                final products = docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isPremium
                            ? const BorderSide(color: Colors.amber, width: 2)
                            : BorderSide.none,
                      ),
                      elevation: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(product.name, style: TextStyle(color: kRwandaBlue, fontWeight: FontWeight.bold)),
                            subtitle: Text('Qty:  {product.quantity} | Price:  {product.price}\n {product.description}'),
                            isThreeLine: true,
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kRwandaGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: product.quantity > 0
                                  ? () => _bookProduct(context, product)
                                  : null,
                              child: const Text('Book'),
                            ),
                          ),
                          if (isPremium)
                            Padding(
                              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.star, color: Colors.amber, size: 18),
                                  SizedBox(width: 6),
                                  Expanded(child: Text('Premium Tip: Book in bulk for better deals!', style: TextStyle(color: Colors.amber[800], fontStyle: FontStyle.italic))),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Simulated AdMob banner
          Container(
            decoration: BoxDecoration(
              color: kRwandaGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 60,
            width: double.infinity,
            alignment: Alignment.center,
            child: const Text('AdMob Banner (Simulated)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kRwandaYellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.feedback),
              label: const Text('Leave Feedback'),
              onPressed: () => _showFeedbackDialog(context),
            ),
          ),
        ],
      ),
    );
  }
} 