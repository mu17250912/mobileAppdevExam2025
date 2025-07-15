import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class DocumentSnapshotFake implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic> _data;
  DocumentSnapshotFake(this._data);
  @override
  Map<String, dynamic>? data([options]) => _data;
  @override
  bool get exists => true;
  // Implement only the used members, throw for others
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdminPremiumScreen extends StatefulWidget {
  final int initialTabIndex;
  const AdminPremiumScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AdminPremiumScreen> createState() => _AdminPremiumScreenState();
}

class _AdminPremiumScreenState extends State<AdminPremiumScreen> with SingleTickerProviderStateMixin {
  String _userSearch = '';
  bool _showPremiumOnly = false;
  int _selectedTabIndex = 0;
  late TabController _tabController;
  final List<String> _bookingStatusOptions = ['All', 'PENDING', 'CONFIRMED', 'REJECTED', 'COMPLETED', 'CANCELLED'];
  String _bookingSearch = '';
  String _selectedBookingStatus = 'All';
  DateTime? _selectedDate;
  String _userSearchQuery = '';

  // Add a cache for user names to avoid repeated lookups
  final Map<String, String> _userNameCache = {};

  // Helper function for image path validation
  bool _isValidImagePath(String path) {
    final validExtensions = ['.png', '.jpg', '.jpeg', '.gif'];
    return path.isNotEmpty && validExtensions.any((ext) => path.toLowerCase().endsWith(ext));
  }

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _tabController = TabController(length: 7, vsync: this, initialIndex: _selectedTabIndex);
    _tabController.addListener(() {
      if (_tabController.index != _selectedTabIndex) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Define tab titles in order INSIDE the build method
    final tabTitles = [
      'Requests',
      'Dashboard',
      'Users',
      'Premium Cars',
      'Manage Cars',
      'Notifications',
      'Profile',
    ];
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            return AppBar(
              backgroundColor: theme.colorScheme.primary,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  Image.asset('assets/images/logo.png', height: 32),
                  const SizedBox(width: 8),
                  Text(
                    'CeremoCar',
                    style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    tabTitles[_tabController.index],
                    style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestsTab(theme),
          _buildAnalyticsDashboard(theme),
          _buildUserTab(theme),
          _buildPremiumCarsTab(theme),
          _buildManageCarsTab(theme),
          NotificationsScreen(showAppBar: false),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTabIndex = index;
            _tabController.index = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.assignment), label: 'Requests'),
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.star), label: 'Premium Cars'),
          NavigationDestination(icon: Icon(Icons.directions_car), label: 'Manage Cars'),
          NavigationDestination(icon: Icon(Icons.notifications), label: 'Notifications'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
        height: 70,
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.secondary.withOpacity(0.1),
      ),
    );
  }

  Widget _buildAnalyticsDashboard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Analytics Dashboard', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return const CircularProgressIndicator();
                final users = userSnap.data!.docs;
                final premiumCount = users.where((u) {
                  final data = u.data() as Map<String, dynamic>;
                  return data['subscription'] != null && data['subscription']['status'] == 'active';
                }).length;
                return Row(
                  children: [
                    _dashboardCard('Total Users', users.length.toString(), Icons.people, theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    _dashboardCard('Premium Users', premiumCount.toString(), Icons.star, Colors.amber),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
              builder: (context, bookSnap) {
                if (!bookSnap.hasData) return const CircularProgressIndicator();
                final bookings = bookSnap.data!.docs;
                double totalRevenue = 0;
                for (var doc in bookings) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['carPrice'] != null) {
                    totalRevenue += double.tryParse(data['carPrice'].toString()) ?? 0;
                  }
                }
                return Row(
                  children: [
                    _dashboardCard('Total Bookings', bookings.length.toString(), Icons.calendar_today, theme.colorScheme.secondary),
                    const SizedBox(width: 12),
                    _dashboardCard('Revenue', 'FRW${totalRevenue.toStringAsFixed(2)}', Icons.attach_money, Colors.green),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text('Recent Premium Purchases', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return const CircularProgressIndicator();
                final users = userSnap.data!.docs;
                final purchases = <Map<String, dynamic>>[];
                for (var user in users) {
                  final data = user.data() as Map<String, dynamic>;
                  if (data['purchases'] != null) {
                    for (var p in List.from(data['purchases'])) {
                      purchases.add({
                        ...p,
                        'user': data['name'] ?? user.id,
                        'date': data['lastPurchaseDate'],
                      });
                    }
                  }
                }
                purchases.sort((a, b) => (b['date']?.millisecondsSinceEpoch ?? 0).compareTo(a['date']?.millisecondsSinceEpoch ?? 0));
                return purchases.isEmpty
                    ? const Text('No premium purchases yet.')
                    : Column(
                        children: purchases.take(5).map((p) => ListTile(
                          leading: const Icon(Icons.star, color: Colors.amber),
                          title: Text('${p['carName'] ?? ''} (${p['price'] ?? ''})'),
                          subtitle: Text('By: ${p['user']}'),
                        )).toList(),
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalyticsSummary(),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search users by name or email',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (val) => setState(() => _userSearch = val.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: 12),
              FilterChip(
                label: const Text('Premium Only'),
                selected: _showPremiumOnly,
                onSelected: (val) => setState(() => _showPremiumOnly = val),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = snapshot.data!.docs;
                final filtered = users.where((user) {
                  final data = user.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final isPremium = (data['subscription'] != null && data['subscription']['status'] == 'active');
                  final matchesSearch = _userSearch.isEmpty || name.contains(_userSearch) || email.contains(_userSearch);
                  final matchesPremium = !_showPremiumOnly || isPremium;
                  return matchesSearch && matchesPremium;
                }).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    final data = user.data() as Map<String, dynamic>;
                    final isPremium = (data['subscription'] != null && data['subscription']['status'] == 'active');
                    final plan = data['subscription'] != null ? (data['subscription']['plan'] ?? 'None') : 'None';
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(data['name'] ?? user.id),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: ${data['email'] ?? ''}'),
                            Text('Plan: $plan'),
                            Text('Status: ${isPremium ? 'Premium' : 'Standard'}'),
                          ],
                        ),
                        trailing: isPremium
                            ? ElevatedButton(
                                onPressed: () => _confirmSetPremium(user.id, false),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Revoke'),
                              )
                            : ElevatedButton(
                                onPressed: () => _confirmSetPremium(user.id, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text('Grant'),
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
    );
  }

  Widget _buildRequestsTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // User search
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search by user name or email',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (val) => setState(() => _userSearchQuery = val.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: 12),
              // Status filter
              DropdownButton<String>(
                value: _selectedBookingStatus,
                items: _bookingStatusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => _selectedBookingStatus = val!),
              ),
              const SizedBox(width: 12),
              // Date filter
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(_selectedDate == null ? 'Filter Date' : _selectedDate!.toString().split(' ')[0]),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                style: OutlinedButton.styleFrom(minimumSize: const Size(120, 40)),
              ),
              if (_selectedDate != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear date filter',
                  onPressed: () => setState(() => _selectedDate = null),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('bookings').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final bookings = snapshot.data!.docs;
                final filtered = bookings.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'PENDING';
                  final car = (data['carName'] ?? '').toString().toLowerCase();
                  final user = (data['userName'] ?? data['userId'] ?? '').toString().toLowerCase();
                  final dateStr = (data['date'] ?? '').toString();
                  final matchesStatus = _selectedBookingStatus == 'All' || status == _selectedBookingStatus;
                  final matchesUser = _userSearchQuery.isEmpty || user.contains(_userSearchQuery);
                  final matchesDate = _selectedDate == null || (dateStr.isNotEmpty && dateStr.startsWith(_selectedDate!.toIso8601String().split('T')[0]));
                  return matchesStatus && matchesUser && matchesDate;
                }).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No booking requests found.'));
                }
                return ListView(
                  children: filtered.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'PENDING';
                    final car = data['carName'] ?? 'Unknown';
                    final userId = data['userId'] ?? '';
                    final date = data['date'] ?? '';
                    final time = data['time'] ?? '';
                    final specialRequest = data['specialRequest'] ?? '';
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    ' A0${data['carName'] ?? 'Unknown'} - ${date.split('T').first}',
                                    style: theme.textTheme.headlineMedium,
                                  ),
                                ),
                                if (status.toLowerCase() == 'rejected' || status.toLowerCase() == 'cancelled' || status.toLowerCase() == 'completed')
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: status.toLowerCase() == 'rejected'
                                          ? Colors.red
                                          : status.toLowerCase() == 'cancelled'
                                              ? Colors.red.shade300
                                              : Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                              future: _getUserDoc(userId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Text('User: ...', style: TextStyle(fontStyle: FontStyle.italic));
                                }
                                if (!snapshot.hasData || !snapshot.data!.exists) {
                                  return Text('User: $userId', style: theme.textTheme.bodyMedium);
                                }
                                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                                final userName = userData?['name'] ?? userId;
                                final userEmail = userData?['email'] ?? '';
                                final userPhone = userData?['phone'] ?? '';
                                String userLine = 'User: $userName';
                                if (userEmail.isNotEmpty && userPhone.isNotEmpty) {
                                  userLine += ' ($userEmail, $userPhone)';
                                } else if (userEmail.isNotEmpty) {
                                  userLine += ' ($userEmail)';
                                } else if (userPhone.isNotEmpty) {
                                  userLine += ' ($userPhone)';
                                }
                                return Text(userLine, style: theme.textTheme.bodyMedium);
                              },
                            ),
                            if (time.isNotEmpty) Text('Time: $time', style: theme.textTheme.bodyMedium),
                            if (specialRequest.isNotEmpty) Text('Request: $specialRequest', style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (status.toLowerCase() == 'pending') ...[
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.check),
                                    label: const Text('Confirm'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    onPressed: () => _handleBookingAction(doc.id, data, 'CONFIRMED', 'Booking Confirmed', 'Your booking for $car on $date has been confirmed.'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.close),
                                    label: const Text('Reject'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () => _handleBookingAction(doc.id, data, 'REJECTED', 'Booking Rejected', 'Your booking for $car on $date was rejected.'),
                                  ),
                                ],
                                if (status.toLowerCase() == 'confirmed') ...[
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.done_all),
                                    label: const Text('Complete'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                    onPressed: () => _handleBookingAction(doc.id, data, 'COMPLETED', 'Booking Completed', 'Your booking for $car on $date is completed.'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.cancel),
                                    label: const Text('Cancel'),
                                    style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error),
                                    onPressed: () => _handleBookingAction(doc.id, data, 'CANCELLED', 'Booking Cancelled', 'Your booking for $car on $date has been cancelled by admin.'),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleBookingAction(String bookingId, Map<String, dynamic> data, String newStatus, String notifTitle, String notifMsg) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Action'),
        content: Text('Are you sure you want to set this booking to "$newStatus"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'status': newStatus});
      // User notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': data['userId'],
        'title': notifTitle,
        'message': notifMsg,
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [],
      });
      // Admin notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': null,
        'title': notifTitle,
        'message': 'Booking for ${data['carName'] ?? 'a car'} on ${data['date'] ?? ''} is now $newStatus.',
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [],
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking updated.')));
      setState(() {});
    }
  }

  Widget _buildAnalyticsSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final users = snapshot.data!.docs;
        final premiumCount = users.where((user) {
          final data = user.data() as Map<String, dynamic>;
          return data['subscription'] != null && data['subscription']['status'] == 'active';
        }).length;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Chip(label: Text('Total Users: ${users.length}')),
              const SizedBox(width: 8),
              Chip(label: Text('Premium Users: $premiumCount')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumCarsTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Premium Cars', style: theme.textTheme.headlineSmall),
              ElevatedButton.icon(
                onPressed: _showAddCarDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Car'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('premium_cars').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final cars = snapshot.data!.docs;
                if (cars.isEmpty) {
                  return const Center(child: Text('No premium cars found.'));
                }
                return ListView.builder(
                  itemCount: cars.length,
                  itemBuilder: (context, index) {
                    final car = cars[index];
                    final data = car.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ExpansionTile(
                        leading: data['image'] != null && _isValidImagePath(data['image'].toString())
                            ? (data['image'].toString().startsWith('assets/')
                                ? Image.asset(data['image'], width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 40))
                                : Image.network(data['image'], width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 40)))
                            : const Icon(Icons.directions_car, size: 40),
                        title: Text(data['name'] ?? car.id),
                        subtitle: Text('Price: ${data['price'] ?? ''}\n${data['description'] ?? ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditCarDialog(car),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeleteCar(car.id, isPremium: true),
                            ),
                          ],
                        ),
                        children: [
                          FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance.collection('users').where('unlockedCars', arrayContains: car.id).get(),
                            builder: (context, userSnap) {
                              if (!userSnap.hasData) return const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator());
                              final unlockedUsers = userSnap.data!.docs;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Text('Unlocked by: ${unlockedUsers.length} user(s)', style: theme.textTheme.bodyMedium),
                                  ),
                                  ...unlockedUsers.map((userDoc) {
                                    final userData = userDoc.data() as Map<String, dynamic>;
                                    return ListTile(
                                      title: Text(userData['name'] ?? userDoc.id),
                                      subtitle: Text(userData['email'] ?? ''),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                                        tooltip: 'Revoke Access',
                                        onPressed: () => _confirmRevokeCarAccess(userDoc.id, car.id),
                                      ),
                                    );
                                  }).toList(),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.add),
                                      label: const Text('Grant Access to User'),
                                      onPressed: () => _showGrantCarAccessDialog(car.id),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageCarsTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Manage Cars', style: theme.textTheme.headlineSmall),
              ElevatedButton.icon(
                onPressed: _showAddRegularCarDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Car'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('cars').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final cars = snapshot.data!.docs;
                if (cars.isEmpty) {
                  return const Center(child: Text('No cars found. Add a new car!'));
                }
                return ListView.builder(
                  itemCount: cars.length,
                  itemBuilder: (context, index) {
                    final car = cars[index];
                    final data = car.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ExpansionTile(
                        leading: data['image'] != null && _isValidImagePath(data['image'].toString())
                            ? (data['image'].toString().startsWith('assets/')
                                ? Image.asset(data['image'], width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 40))
                                : Image.network(data['image'], width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 40)))
                            : const Icon(Icons.directions_car, size: 40),
                        title: Text(data['name'] ?? car.id),
                        subtitle: Text('Price: ${data['price'] ?? ''}\n${data['description'] ?? ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditCarDialog(car),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeleteCar(car.id, isPremium: false),
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
    );
  }

  Future<List<String>> _fetchAllCarNames() async {
    final carsSnap = await FirebaseFirestore.instance.collection('cars').get();
    final premiumSnap = await FirebaseFirestore.instance.collection('premium_cars').get();

    final carNames = <String>{}; // Use a set to avoid duplicates

    for (var doc in carsSnap.docs) {
      final data = doc.data();
      if (data['name'] != null && data['name'].toString().isNotEmpty) {
        carNames.add(data['name'].toString());
      }
    }
    for (var doc in premiumSnap.docs) {
      final data = doc.data();
      if (data['name'] != null && data['name'].toString().isNotEmpty) {
        carNames.add(data['name'].toString());
      }
    }

    return carNames.toList()..sort(); // Sort alphabetically
  }

  void _showAddCarDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final imageController = TextEditingController();
    final descController = TextEditingController();
    String? error;
    String? selectedAssetImage;
    String? selectedBrand;
    String? selectedType;
    final brands = ['BMW', 'Mercedes', 'Audi', 'Lexus', 'Tesla', 'Other'];
    final types = ['Sedan', 'SUV', 'Luxury', 'Sports', 'Electric', 'Other'];
    
    // Load available asset images
    final List<String> assetImages = [
      'assets/images/google_logo.png',
      'assets/images/Mercedes Benz C Class.gif',
      'assets/images/Mercedes Benz E Class.gif',
      'assets/images/Hummer 2.jpg',
      'assets/images/Pickup Trucks.jpg',
      'assets/images/Jaguar.gif',
      'assets/images/Chrysler.jpg',
      'assets/images/Limousin.jpg',
      'assets/images/Land Cruiser V8.jpg',
      'assets/images/Cross Country.jpg',
      'assets/images/Range Rover.jpg',
      'assets/images/logo.png',
      'assets/images/Mercedes GLE.jpeg',
      'assets/images/BMW 3 Series.jpeg',
    ];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Add Premium Car'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FutureBuilder<List<String>>(
                    future: _fetchAllCarNames(),
                    builder: (context, snapshot) {
                      final existingCarNames = snapshot.data ?? [];
                      final allOptions = ['-- Create New Car Name --', ...existingCarNames];
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            value: nameController.text.isEmpty || !existingCarNames.contains(nameController.text)
                                ? '-- Create New Car Name --'
                                : nameController.text,
                            items: allOptions.map((name) => DropdownMenuItem(
                              value: name,
                              child: Text(
                                name,
                                style: name == '-- Create New Car Name --' 
                                  ? const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)
                                  : null,
                              ),
                            )).toList(),
                            onChanged: (value) {
                              if (value != null && value != '-- Create New Car Name --') {
                                nameController.text = value;
                              } else {
                                nameController.clear();
                              }
                              setStateDialog(() {});
                            },
                            decoration: InputDecoration(
                              labelText: 'Car Name *',
                              hintText: 'Select existing or create new',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              suffixIcon: existingCarNames.isNotEmpty 
                                ? IconButton(
                                    icon: const Icon(Icons.arrow_drop_down),
                                    tooltip: '${existingCarNames.length} existing car names available',
                                    onPressed: () {},
                                  )
                                : null,
                            ),
                          ),
                          if (nameController.text.isEmpty || !existingCarNames.contains(nameController.text))
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: TextField(
                                controller: nameController,
                                decoration: InputDecoration(
                                  labelText: 'Or Type New Car Name',
                                  hintText: 'Enter custom car name',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onChanged: (value) => setStateDialog(() {}),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Asset Image Selection
                  Text('Car Image', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.grid_view),
                          label: const Text('Pick from Assets'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            elevation: 0,
                          ),
                          onPressed: () async {
                            await showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  width: 400,
                                  height: 400,
                                  child: Column(
                                    children: [
                                      Text(
                                        'Select Car Image',
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 16),
                                      Expanded(
                                        child: GridView.builder(
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3, 
                                            crossAxisSpacing: 8, 
                                            mainAxisSpacing: 8
                                          ),
                                          itemCount: assetImages.length,
                                          itemBuilder: (context, idx) {
                                            final img = assetImages[idx];
                                            return GestureDetector(
                                              onTap: () {
                                                setStateDialog(() {
                                                  selectedAssetImage = img;
                                                  imageController.text = img;
                                                });
                                                Navigator.pop(context);
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: selectedAssetImage == img 
                                                        ? Theme.of(context).colorScheme.primary 
                                                        : Colors.grey.shade300,
                                                    width: selectedAssetImage == img ? 3 : 1,
                                                  ),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.asset(
                                                    img, 
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 30),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: selectedAssetImage != null
                                                  ? () => Navigator.pop(context)
                                                  : null,
                                              child: const Text('Select'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.link),
                          label: const Text('URL'),
                          onPressed: () {
                            setStateDialog(() {
                              selectedAssetImage = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Image Preview
                  if (selectedAssetImage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          selectedAssetImage!,
                          height: 80,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 60),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedBrand,
                    items: brands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        selectedBrand = val;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Brand *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        selectedType = val;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Type *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Price *',
                      hintText: 'e.g. FRW50,000/day',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: imageController,
                    decoration: InputDecoration(
                      labelText: 'Image URL',
                      hintText: 'Paste image URL or leave blank',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onChanged: (val) => setStateDialog(() {}),
                  ),
                  if (imageController.text.isNotEmpty && selectedAssetImage == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Builder(
                          builder: (context) {
                            try {
                              if (imageController.text.startsWith('assets/')) {
                                return Image.asset(
                                  imageController.text,
                                  height: 80,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 60),
                                );
                              } else {
                                return Image.network(
                                  imageController.text,
                                  height: 80,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 60),
                                );
                              }
                            } catch (e) {
                              return const Icon(Icons.directions_car, size: 60);
                            }
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Optional details about the car',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(error!, style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: (nameController.text.trim().isEmpty || 
                         priceController.text.trim().isEmpty ||
                         selectedBrand == null ||
                         selectedType == null)
                  ? null
                  : () async {
                      final carData = {
                        'name': nameController.text.trim(),
                        'brand': selectedBrand,
                        'type': selectedType,
                        'price': priceController.text.trim(),
                        'image': imageController.text.trim(),
                        'description': descController.text.trim(),
                        'isPremium': true,
                        'createdAt': FieldValue.serverTimestamp(),
                      };
                      try {
                        await FirebaseFirestore.instance.collection('premium_cars').add(carData);
                        if (context.mounted) {
                          Navigator.pop(context);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Premium car added successfully!')),
                              );
                            }
                          });
                        }
                      } catch (e) {
                        if (context.mounted) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to add premium car: $e'), backgroundColor: Colors.red),
                              );
                            }
                          });
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                minimumSize: const Size(100, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Add Premium Car'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCarDialog(QueryDocumentSnapshot car) {
    final data = car.data() as Map<String, dynamic>;
    final nameController = TextEditingController(text: data['name'] ?? '');
    final priceController = TextEditingController(text: data['price'] ?? '');
    final imageController = TextEditingController(text: data['image'] ?? '');
    final descController = TextEditingController(text: data['description'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Premium Car'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Car Name'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
              ),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: !_isValidImagePath(imageController.text.trim()) ? null : () async {
              if (!_isValidImagePath(imageController.text.trim())) {
                return;
              }
              try {
                await FirebaseFirestore.instance.collection('premium_cars').doc(car.id).update({
                  'name': nameController.text.trim(),
                  'price': priceController.text.trim(),
                  'image': imageController.text.trim(),
                  'description': descController.text.trim(),
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Car updated successfully!')),
                      );
                    }
                  });
                }
              } catch (e) {
                if (context.mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update car: $e'), backgroundColor: Colors.red),
                      );
                    }
                  });
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showGrantCarAccessDialog(String carId) {
    final userIdController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grant Car Access'),
        content: TextField(
          controller: userIdController,
          decoration: const InputDecoration(labelText: 'User ID'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final userId = userIdController.text.trim();
              if (userId.isNotEmpty) {
                try {
                  await FirebaseFirestore.instance.collection('users').doc(userId).update({
                    'unlockedCars': FieldValue.arrayUnion([carId]),
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Car access granted successfully!')),
                        );
                      }
                    });
                  }
                } catch (e) {
                  if (context.mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to grant access: $e'), backgroundColor: Colors.red),
                        );
                      }
                    });
                  }
                }
              }
            },
            child: const Text('Grant'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCar(String carId, {bool isPremium = false}) {
    final collection = isPremium ? 'premium_cars' : 'cars';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${isPremium ? 'Premium' : 'Regular'} Car'),
        content: Text('Are you sure you want to delete this ${isPremium ? 'premium' : 'regular'} car?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection(collection).doc(carId).delete();
                if (context.mounted) {
                  Navigator.pop(context);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${isPremium ? 'Premium' : 'Regular'} car deleted successfully!')),
                      );
                    }
                  });
                }
              } catch (e) {
                if (context.mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete car: $e'), backgroundColor: Colors.red),
                      );
                    }
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmRevokeCarAccess(String userId, String carId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Car Access'),
        content: const Text('Are you sure you want to revoke this user\'s access to this car?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('users').doc(userId).update({
                  'unlockedCars': FieldValue.arrayRemove([carId]),
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Car access revoked successfully!')),
                      );
                    }
                  });
                }
              } catch (e) {
                if (context.mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to revoke access: $e'), backgroundColor: Colors.red),
                      );
                    }
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }

  void _confirmSetPremium(String userId, bool grant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(grant ? 'Grant Premium' : 'Revoke Premium'),
        content: Text(grant
            ? 'Are you sure you want to grant premium access to this user?'
            : 'Are you sure you want to revoke premium access from this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _setPremium(userId, grant);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to ${grant ? 'grant' : 'revoke'} premium: $e'), backgroundColor: Colors.red),
                      );
                    }
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: grant ? Colors.green : Colors.red),
            child: Text(grant ? 'Grant' : 'Revoke'),
          ),
        ],
      ),
    );
  }

  Future<void> _setPremium(String userId, bool grant) async {
    try {
      final sub = grant
          ? {
              'plan': 'admin_granted',
              'startDate': FieldValue.serverTimestamp(),
              'status': 'active',
            }
          : null;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'subscription': sub,
      });
      // Add notification for user
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': grant ? 'Premium Granted' : 'Premium Revoked',
        'message': grant
            ? 'You have been granted premium access by an admin.'
            : 'Your premium access has been revoked by an admin.',
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [],
      });
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(grant ? 'Premium granted.' : 'Premium revoked.')),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to ${grant ? 'grant' : 'revoke'} premium: $e'), backgroundColor: Colors.red),
            );
          }
        });
      }
      rethrow;
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserDoc(String userId) async {
    if (_userNameCache.containsKey(userId)) {
      // Return a fake doc with just the name
      return DocumentSnapshotFake({'name': _userNameCache[userId]});
    }
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['name'] != null) {
        _userNameCache[userId] = data['name'];
      }
    }
    return doc;
  }

  void _showAddRegularCarDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final imageController = TextEditingController();
    final descController = TextEditingController();
    String? error;
    String? selectedAssetImage;
    String? selectedType;
    final types = ['Sedan', 'SUV', 'Luxury', 'Sports', 'Electric', 'Other'];
    
    // Load available asset images
    final List<String> assetImages = [
      'assets/images/google_logo.png',
      'assets/images/Mercedes Benz C Class.gif',
      'assets/images/Mercedes Benz E Class.gif',
      'assets/images/Hummer 2.jpg',
      'assets/images/Pickup Trucks.jpg',
      'assets/images/Jaguar.gif',
      'assets/images/Chrysler.jpg',
      'assets/images/Limousin.jpg',
      'assets/images/Land Cruiser V8.jpg',
      'assets/images/Cross Country.jpg',
      'assets/images/Range Rover.jpg',
      'assets/images/logo.png',
      'assets/images/Mercedes GLE.jpeg',
      'assets/images/BMW 3 Series.jpeg',
    ];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Add Regular Car'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FutureBuilder<List<String>>(
                    future: _fetchAllCarNames(),
                    builder: (context, snapshot) {
                      final existingCarNames = snapshot.data ?? [];
                      final allOptions = ['-- Create New Car Name --', ...existingCarNames];
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            value: nameController.text.isEmpty || !existingCarNames.contains(nameController.text)
                                ? '-- Create New Car Name --'
                                : nameController.text,
                            items: allOptions.map((name) => DropdownMenuItem(
                              value: name,
                              child: Text(
                                name,
                                style: name == '-- Create New Car Name --' 
                                  ? const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)
                                  : null,
                              ),
                            )).toList(),
                            onChanged: (value) {
                              if (value != null && value != '-- Create New Car Name --') {
                                nameController.text = value;
                              } else {
                                nameController.clear();
                              }
                              setStateDialog(() {});
                            },
                            decoration: InputDecoration(
                              labelText: 'Car Name *',
                              hintText: 'Select existing or create new',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              suffixIcon: existingCarNames.isNotEmpty 
                                ? IconButton(
                                    icon: const Icon(Icons.arrow_drop_down),
                                    tooltip: '${existingCarNames.length} existing car names available',
                                    onPressed: () {},
                                  )
                                : null,
                            ),
                          ),
                          if (nameController.text.isEmpty || !existingCarNames.contains(nameController.text))
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: TextField(
                                controller: nameController,
                                decoration: InputDecoration(
                                  labelText: 'Or Type New Car Name',
                                  hintText: 'Enter custom car name',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onChanged: (value) => setStateDialog(() {}),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Asset Image Selection
                  Text('Car Image', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.grid_view),
                          label: const Text('Pick from Assets'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            elevation: 0,
                          ),
                          onPressed: () async {
                            await showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  width: 400,
                                  height: 400,
                                  child: Column(
                                    children: [
                                      Text(
                                        'Select Car Image',
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 16),
                                      Expanded(
                                        child: GridView.builder(
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3, 
                                            crossAxisSpacing: 8, 
                                            mainAxisSpacing: 8
                                          ),
                                          itemCount: assetImages.length,
                                          itemBuilder: (context, idx) {
                                            final img = assetImages[idx];
                                            return GestureDetector(
                                              onTap: () {
                                                setStateDialog(() {
                                                  selectedAssetImage = img;
                                                  imageController.text = img;
                                                });
                                                Navigator.pop(context);
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: selectedAssetImage == img 
                                                        ? Theme.of(context).colorScheme.primary 
                                                        : Colors.grey.shade300,
                                                    width: selectedAssetImage == img ? 3 : 1,
                                                  ),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.asset(
                                                    img, 
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 30),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: selectedAssetImage != null
                                                  ? () => Navigator.pop(context)
                                                  : null,
                                              child: const Text('Select'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.link),
                          label: const Text('URL'),
                          onPressed: () {
                            setStateDialog(() {
                              selectedAssetImage = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Image Preview
                  if (selectedAssetImage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          selectedAssetImage!,
                          height: 80,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 60),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        selectedType = val;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Type *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    onChanged: (_) => setStateDialog(() {}),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Price *',
                      hintText: 'e.g. FRW50,000/day',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: imageController,
                    onChanged: (_) => setStateDialog(() {}),
                    decoration: InputDecoration(
                      labelText: 'Image URL',
                      hintText: 'Paste image URL or leave blank',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  if (imageController.text.isNotEmpty && selectedAssetImage == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Builder(
                          builder: (context) {
                            try {
                              if (imageController.text.startsWith('assets/')) {
                                return Image.asset(
                                  imageController.text,
                                  height: 80,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 60),
                                );
                              } else {
                                return Image.network(
                                  imageController.text,
                                  height: 80,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 60),
                                );
                              }
                            } catch (e) {
                              return const Icon(Icons.directions_car, size: 60);
                            }
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    onChanged: (_) => setStateDialog(() {}),
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Optional details about the car',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(error!, style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: (nameController.text.trim().isEmpty || 
                         priceController.text.trim().isEmpty ||
                         selectedType == null)
                  ? null
                  : () async {
                      final carData = {
                        'name': nameController.text.trim(),
                        'type': selectedType,
                        'price': priceController.text.trim(),
                        'image': imageController.text.trim(),
                        'description': descController.text.trim(),
                        'available': true,
                        'createdAt': FieldValue.serverTimestamp(),
                      };
                      try {
                        await FirebaseFirestore.instance.collection('cars').add(carData);
                        if (context.mounted) {
                          Navigator.pop(context);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Regular car added successfully!')),
                              );
                            }
                          });
                        }
                      } catch (e) {
                        if (context.mounted) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to add regular car: $e'), backgroundColor: Colors.red),
                              );
                            }
                          });
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                minimumSize: const Size(100, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Add Regular Car'),
            ),
          ],
        ),
      ),
    );
  }
} 