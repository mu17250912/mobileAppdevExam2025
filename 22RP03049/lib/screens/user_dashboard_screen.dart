import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/services.dart';
import 'routes_screen.dart';
import 'user_notifications_screen.dart'; // Added import for UserNotificationsScreen
import 'package:http/http.dart' as http;
import 'my_bookings_screen.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({Key? key}) : super(key: key);

  void _showETicketDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('E-Ticket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ticket: \\${data['ticketCode'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Status: \\${data['status'] ?? ''}'),
            Text('Booked: \\${data['bookingTime'] != null ? (data['bookingTime'] as Timestamp).toDate().toString() : ''}'),
            Text('Bus: \\${data['busId'] ?? ''}'),
            Text('Seat: \\${data['seatNumber'] ?? ''}'),
          ],  
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Log dashboard opened event
    FirebaseAnalytics.instance.logEvent(name: 'dashboard_opened', parameters: {'userId': user?.uid ?? 'unknown'});
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your dashboard.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: user.uid)
                .where('unread', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.docs.length;
              }
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    tooltip: 'Notifications',
                    onPressed: () {
                      FirebaseAnalytics.instance.logEvent(name: 'notifications_viewed', parameters: {'userId': user.uid ?? 'unknown'});
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const UserNotificationsScreen()),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('userId', isEqualTo: user.uid)
                .orderBy('bookingTime', descending: true)
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return IconButton(
                  icon: const Icon(Icons.qr_code),
                  tooltip: 'View E-Ticket',
                  onPressed: null,
                );
              }
              final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
              return IconButton(
                icon: const Icon(Icons.qr_code),
                tooltip: 'View E-Ticket',
                onPressed: () => _showETicketDialog(context, data),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                final isPremium = userData != null && userData['plan'] == 'premium';
                return Row(
                  children: [
                    if (isPremium)
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Premium Member'),
                              content: const Text('Thank you for being a Premium user!\n\nYour benefits:\n- Unlimited bookings\n- Priority support\n- Access to exclusive offers'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text('Premium', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    if (!isPremium)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.star),
                        label: const Text('Go Premium'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () async {
                          showDialog(
                            context: context,
                            builder: (context) {
                              final formKey = GlobalKey<FormState>();
                              final cardController = TextEditingController();
                              final nameController = TextEditingController();
                              return AlertDialog(
                                title: const Text('Upgrade to Premium'),
                                content: Form(
                                  key: formKey,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Unlock all features with Premium!'),
                                        const SizedBox(height: 8),
                                        const Text('- Unlimited bookings'),
                                        const Text('- Priority support'),
                                        const Text('- Access to exclusive offers'),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: nameController,
                                          decoration: const InputDecoration(labelText: 'Name on Card'),
                                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                        ),
                                        TextFormField(
                                          controller: cardController,
                                          decoration: const InputDecoration(labelText: 'Card Number'),
                                          keyboardType: TextInputType.number,
                                          validator: (v) => v == null || v.length < 8 ? 'Enter a valid card number' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (formKey.currentState!.validate()) {
                                        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'plan': 'premium'});
                                        // Log analytics event
                                        await FirebaseAnalytics.instance.logEvent(name: 'upgrade_to_premium', parameters: {
                                          'userId': user.uid ?? 'unknown',
                                          'timestamp': DateTime.now().toIso8601String(),
                                        });
                                        await FirebaseAnalytics.instance.logEvent(name: 'payment_made', parameters: {
                                          'userId': user.uid ?? 'unknown',
                                          'type': 'premium_upgrade',
                                          'timestamp': DateTime.now().toIso8601String(),
                                        });
                                        // Send premium confirmation notification
                                        await FirebaseFirestore.instance.collection('notifications').add({
                                          'userId': user.uid,
                                          'title': 'Premium Activated',
                                          'message': 'Thank you for upgrading! You now have access to all premium features.',
                                          'sentAt': FieldValue.serverTimestamp(),
                                          'unread': true,
                                          'auto': true,
                                        });
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Payment successful! You are now a Premium user!')),
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
                      ),
                  ],
                );
              },
            ),
            // Add this after the Premium/Go Premium button or in a suitable place in the dashboard UI
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.payment),
              label: Text('Pay with PayPal (Simulated)'),
              onPressed: () async {
                // Simulated PayPal payment for demonstration
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('PayPal Payment'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Amount: \$10.00'),
                        Text('Description: Premium Upgrade'),
                        SizedBox(height: 16),
                        Text('This is a simulated payment for demonstration purposes.'),
                        Text('In a real app, this would redirect to PayPal.'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          // Simulate successful payment
                          try {
                            await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'plan': 'premium'});
                            // Log analytics event
                            await FirebaseAnalytics.instance.logEvent(name: 'upgrade_to_premium', parameters: {
                              'userId': user.uid ?? 'unknown',
                              'timestamp': DateTime.now().toIso8601String(),
                            });
                            await FirebaseAnalytics.instance.logEvent(name: 'payment_made', parameters: {
                              'userId': user.uid ?? 'unknown',
                              'type': 'premium_upgrade',
                              'timestamp': DateTime.now().toIso8601String(),
                            });
                            // Send premium confirmation notification
                            await FirebaseFirestore.instance.collection('notifications').add({
                              'userId': user.uid,
                              'title': 'Premium Activated',
                              'message': 'Thank you for upgrading! You now have access to all premium features.',
                              'sentAt': FieldValue.serverTimestamp(),
                              'unread': true,
                              'auto': true,
                            });
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Payment successful! You are now a Premium user!')),
                            );
                          } catch (e) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        child: Text('Confirm Payment'),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Dashboard cards
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                int totalBookings = 0;
                int upcoming = 0;
                int paidBookings = 0;
                if (snapshot.hasData) {
                  totalBookings = snapshot.data!.docs.length;
                  upcoming = snapshot.data!.docs.where((doc) => doc['status'] == 'confirmed').length;
                  paidBookings = snapshot.data!.docs.where((doc) => doc['paymentStatus'] == 'paid').length;
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _DashboardCard(
                      icon: Icons.confirmation_num,
                      label: 'Total Bookings',
                      value: totalBookings.toString(),
                      color: const Color(0xFF003366),
                    ),
                    // Total Paid card
                    _DashboardCard(
                      icon: Icons.attach_money,
                      label: 'Paid Bookings',
                      value: paidBookings.toString(),
                      color: Colors.green,
                    ),
                    _DashboardCard(
                      icon: Icons.event,
                      label: 'Upcoming Trips',
                      value: upcoming.toString(),
                      color: const Color(0xFFFFD600),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            // Quick actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Book Ticket'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD600),
                    foregroundColor: const Color(0xFF003366),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RoutesScreen()),
                    );
                  },
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('userId', isEqualTo: user.uid)
                      .orderBy('bookingTime', descending: true)
                      .limit(1)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return ElevatedButton.icon(
                        icon: const Icon(Icons.qr_code),
                        label: const Text('View E-Ticket'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003366),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: null,
                      );
                    }
                    final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                    return ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code),
                      label: const Text('View E-Ticket'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _showETicketDialog(context, data),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Referral and loyalty row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.group_add),
                  label: const Text('Refer a Friend'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Refer a Friend'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Share your referral code:'),
                            const SizedBox(height: 8),
                            SelectableText(user.uid, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.share),
                              label: const Text('Copy Code'),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: user.uid));
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Referral code copied!')),
                                );
                              },
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Loyalty badge/progress
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('userId', isEqualTo: user.uid)
                      .where('status', isEqualTo: 'confirmed')
                      .snapshots(),
                  builder: (context, snapshot) {
                    int totalBookings = 0;
                    if (snapshot.hasData) {
                      totalBookings = snapshot.data!.docs.length;
                    }
                    final bookingsToNext = 5 - (totalBookings % 5);
                    final isLoyalty = totalBookings > 0 && totalBookings % 5 == 0;
                    // Send loyalty notification if just reached a multiple of 5
                    if (isLoyalty && snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      final lastBooking = snapshot.data!.docs.first;
                      final lastBookingTime = lastBooking['bookingTime'];
                      // Only send if this is the most recent booking (avoid duplicate notifications)
                      if (lastBookingTime != null && DateTime.now().difference((lastBookingTime as Timestamp).toDate()).inSeconds < 10) {
                        FirebaseFirestore.instance.collection('notifications').add({
                          'userId': user.uid,
                          'title': 'Loyalty Discount!',
                          'message': 'Congratulations! You have earned a discount for your next booking.',
                          'sentAt': FieldValue.serverTimestamp(),
                          'unread': true,
                          'auto': true,
                        });
                      }
                    }
                    return Row(
                      children: [
                        if (isLoyalty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text('Loyalty Discount!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          )
                        else
                          Text('Bookings to next discount: $bookingsToNext', style: const TextStyle(color: Colors.purple)),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Recent Bookings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF003366))),
            const SizedBox(height: 8),
            // Recent bookings list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('userId', isEqualTo: user.uid)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No recent bookings.'));
                  }
                  final bookings = snapshot.data!.docs;
                  bookings.sort((a, b) {
                    final aTime = a['bookingTime'];
                    final bTime = b['bookingTime'];
                    if (aTime == null && bTime == null) return 0;
                    if (aTime == null) return 1;
                    if (bTime == null) return -1;
                    return (bTime as Timestamp).compareTo(aTime as Timestamp);
                  });
                  return ListView.builder(
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      final data = booking.data() as Map<String, dynamic>;
                      return Card(
                        color: const Color(0xFFF5F6FA),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.directions_bus, color: Color(0xFF003366)),
                          title: Text('Ticket: \\${data['ticketCode'] ?? ''}', style: const TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.bold)),
                          subtitle: Text('Status: \\${data['status'] ?? ''}\nPayment: \\${data['paymentStatus'] ?? ''}\nBooked: \\${data['bookingTime'] != null ? (data['bookingTime'] as Timestamp).toDate().toString() : 'Pending...'}', style: const TextStyle(color: Color(0xFF003366))),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.qr_code, color: Color(0xFF003366)),
                                tooltip: 'Show E-Ticket',
                                onPressed: () => _showETicketDialog(context, data),
                              ),
                              if (data['paymentStatus'] == 'pending')
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => _confirmPay(context, booking.id, user.uid, 2000), // Example: 2000 RWF
                                  child: const Text('Pay'),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _confirmPay(BuildContext context, String bookingId, String userId, int amount) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirm Payment'),
      content: Text('Do you want to pay $amount RWF for this booking?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              // 1. Create a payment record
              await FirebaseFirestore.instance.collection('payments').add({
                'userId': userId,
                'bookingId': bookingId,
                'amount': amount,
                'paidAt': FieldValue.serverTimestamp(),
                'status': 'success',
              });
              // 2. Update booking status
              await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'paymentStatus': 'paid'});
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment successful!')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Pay'),
        ),
      ],
    ),
  );
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _DashboardCard({required this.icon, required this.label, required this.value, required this.color, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
} 