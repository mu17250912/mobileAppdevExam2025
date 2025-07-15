import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class MyBookingsScreen extends StatefulWidget {
  @override
  _MyBookingsScreenState createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  int _selectedBottomNav = 2;
  String _searchQuery = '';
  String _selectedStatus = 'All';
  final List<String> _statusOptions = ['All', 'PENDING', 'CONFIRMED', 'COMPLETED', 'CANCELLED'];

  @override
  void initState() {
    super.initState();
    // No longer set _bookingsStream here
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        if (user == null) {
          return Scaffold(
            backgroundColor: theme.colorScheme.primary,
            body: Center(child: Text('Please log in to view your bookings.', style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.onPrimary))),
          );
        }
        final bookingsStream = FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots();
        final args = ModalRoute.of(context)!.settings.arguments;
        Map<String, dynamic>? newBooking;
        if (args != null && args is Map<String, dynamic>) {
          newBooking = args;
        }
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/available_cars_screen',
                  (route) => false,
                );
              },
            ),
            title: const Text('My Bookings'),
            backgroundColor: theme.colorScheme.primary,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text('Filter by status: '),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedStatus,
                      items: _statusOptions.map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      )).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedStatus = value);
                      },
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 180,
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Search',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: bookingsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: theme.colorScheme.secondary));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      // Try fallback query without orderBy if no data
                      return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        future: FirebaseFirestore.instance
                            .collection('bookings')
                            .where('userId', isEqualTo: user.uid)
                            .get(),
                        builder: (context, fbSnapshot) {
                          if (fbSnapshot.hasError) {
                            return Center(child: Text('Error: ${fbSnapshot.error}'));
                          }
                          if (!fbSnapshot.hasData || fbSnapshot.data!.docs.isEmpty) {
                            return Center(child: Text('No bookings found.', style: theme.textTheme.headlineMedium));
                          }
                          final bookings = fbSnapshot.data!.docs;
                          return _buildBookingsList(bookings, theme);
                        },
                      );
                    }
                    final bookings = snapshot.data!.docs;
                    return _buildBookingsList(bookings, theme);
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedBottomNav,
            onDestinationSelected: (index) {
              setState(() {
                _selectedBottomNav = index;
              });
              if (index == 0) {
                Navigator.pushNamed(context, '/available_cars_screen');
              } else if (index == 1) {
                Navigator.pushNamed(context, '/profile');
              } else if (index == 2) {
                Navigator.pushNamed(context, '/my_bookings_screen');
              }
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
              NavigationDestination(icon: Icon(Icons.calendar_today), label: 'Bookings'),
            ],
            height: 70,
            backgroundColor: theme.colorScheme.surface,
            indicatorColor: theme.colorScheme.secondary.withOpacity(0.1),
          ),
        );
      },
    );
  }

  Widget _buildBookingsList(List<QueryDocumentSnapshot<Map<String, dynamic>>> bookings, ThemeData theme) {
    // Apply filtering and search
    final filtered = bookings.where((doc) {
      final booking = doc.data();
      final status = booking['status'] ?? 'PENDING';
      final carName = (booking['carName'] ?? booking['car'] ?? '').toString().toLowerCase();
      final dateRaw = booking['date'] ?? '';
      final dateStr = dateRaw is String ? dateRaw : '';
      final matchesStatus = _selectedStatus == 'All' || status == _selectedStatus;
      final matchesSearch = _searchQuery.isEmpty || carName.contains(_searchQuery.toLowerCase()) || dateStr.contains(_searchQuery);
      return matchesStatus && matchesSearch;
    }).toList();
    if (filtered.isEmpty) {
      return Center(child: Text('No bookings found.', style: theme.textTheme.headlineMedium));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
      children: [
        ...filtered.map((doc) {
          final booking = doc.data();
          final carName = booking['carName'] ?? booking['car'] ?? 'Unknown';
          final dateRaw = booking['date'] ?? '';
          final timeRaw = booking['time'] ?? '';
          String dateDisplay = '';
          if (dateRaw is String && dateRaw.isNotEmpty) {
            try {
              final parsed = DateTime.parse(dateRaw);
              dateDisplay = DateFormat('yyyy-MM-dd').format(parsed);
            } catch (_) {
              dateDisplay = dateRaw;
            }
          }
          String timeDisplay = '';
          if (timeRaw is String && timeRaw.isNotEmpty) {
            timeDisplay = timeRaw;
          }
          final withDriver = booking['withDriver'] == true;
          final withDecoration = booking['withDecoration'] == true;
          final specialRequest = booking['specialRequest'] ?? booking['specialRequest'] ?? '';
          final status = booking['status'] ?? 'PENDING';
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(carName, style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: (status == 'CONFIRMED' ? theme.colorScheme.secondary.withOpacity(0.2) : status == 'CANCELLED' ? theme.colorScheme.error.withOpacity(0.2) : status == 'COMPLETED' ? Colors.green.withOpacity(0.2) : theme.colorScheme.primary.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: (status == 'CONFIRMED' ? theme.colorScheme.secondary : status == 'CANCELLED' ? theme.colorScheme.error : status == 'COMPLETED' ? Colors.green : theme.colorScheme.primary),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (dateDisplay.isNotEmpty)
                    Text('Date: $dateDisplay', style: theme.textTheme.bodyLarge),
                  if (timeDisplay.isNotEmpty)
                    Text('Time: $timeDisplay', style: theme.textTheme.bodyLarge),
                  Text('With Driver: ${withDriver ? 'Yes' : 'No'}', style: theme.textTheme.bodyMedium),
                  Text('With Decoration: ${withDecoration ? 'Yes' : 'No'}', style: theme.textTheme.bodyMedium),
                  if (specialRequest.isNotEmpty)
                    Text('Special: $specialRequest', style: theme.textTheme.bodyMedium),
                  if (status == 'COMPLETED')
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: booking['feedback'] != null && booking['feedback'].toString().isNotEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Your Feedback:', style: theme.textTheme.bodyLarge),
                              Text(booking['feedback'], style: theme.textTheme.bodyMedium),
                              if (booking['rating'] != null)
                                Row(
                                  children: [
                                    Text('Your Rating: ', style: theme.textTheme.bodyMedium),
                                    RatingBarIndicator(
                                      rating: (booking['rating'] as num).toDouble(),
                                      itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
                                      itemCount: 5,
                                      itemSize: 20.0,
                                    ),
                                  ],
                                ),
                            ],
                          )
                        : ElevatedButton.icon(
                            icon: Icon(Icons.rate_review),
                            label: Text('Leave Feedback'),
                            onPressed: () async {
                              double rating = 5.0;
                              final feedbackController = TextEditingController();
                              final result = await showDialog<Map<String, dynamic>>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Leave Feedback'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('How would you rate your experience?'),
                                      RatingBar.builder(
                                        initialRating: 5.0,
                                        minRating: 1,
                                        direction: Axis.horizontal,
                                        allowHalfRating: true,
                                        itemCount: 5,
                                        itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
                                        onRatingUpdate: (value) => rating = value,
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: feedbackController,
                                        decoration: InputDecoration(
                                          labelText: 'Feedback',
                                          border: OutlineInputBorder(),
                                        ),
                                        minLines: 2,
                                        maxLines: 4,
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context, {
                                          'feedback': feedbackController.text.trim(),
                                          'rating': rating,
                                        });
                                      },
                                      child: Text('Submit'),
                                    ),
                                  ],
                                ),
                              );
                              if (result != null && (result['feedback'] as String).isNotEmpty) {
                                await FirebaseFirestore.instance.collection('bookings').doc(doc.id).update({
                                  'feedback': result['feedback'],
                                  'rating': result['rating'],
                                });
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Thank you for your feedback!')),
                                );
                              }
                            },
                          ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.info_outline),
                          label: const Text('View Details'),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: theme.colorScheme.onSecondary,
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/booking_confirmation_screen',
                              arguments: {...booking, 'id': doc.id},
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.repeat),
                          label: const Text('Rebook'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            side: BorderSide(color: theme.colorScheme.primary),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/car_details_screen',
                              arguments: booking['carId'], // Pass only the carId
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (status == 'PENDING' || status == 'CONFIRMED')
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                              side: BorderSide(color: theme.colorScheme.error),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () async {
                              final result = await Navigator.pushNamed(
                                context,
                                '/booking_cancellation_screen',
                                arguments: {'id': doc.id, ...booking},
                              );
                              if (result is Map && result['cancelled'] == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Booking cancelled.')),
                                );
                                setState(() {}); // Refresh
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
} 