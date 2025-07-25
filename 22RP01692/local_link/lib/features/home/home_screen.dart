import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/service_model.dart';
import '../../services/auth_service.dart';
import 'search_bar.dart';
import 'service_list.dart';
import '../bookings/bookings_screen.dart';
import 'package:intl/intl.dart';
import '../profile/edit_profile_screen.dart';
import '../user/user_premium_screen.dart';
import '../user/user_dashboard_screen.dart';
import '../user/freemium_model_screen.dart';
import '../payment/payment_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Service> _services = [];
  bool _loading = true;
  User? _currentUser;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // _loadServices(); // Remove this, we will use StreamBuilder
  }

  void _loadUserData() {
    _currentUser = FirebaseAuth.instance.currentUser;
    setState(() {});
  }

  Future<void> _loadServices() async {
    setState(() => _loading = true);
    // Simulate loading
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _services = [
        Service(
          id: '1',
          name: 'Plumber Pro',
          description: 'Professional plumbing services for all your needs',
          rating: 4.5,
          lat: 37.7749,
          lng: -122.4194,
          category: 'Plumbing',
        ),
        Service(
          id: '2',
          name: 'Electrician Express',
          description: 'Fast and reliable electrical services',
          rating: 4.8,
          lat: 37.7849,
          lng: -122.4094,
          category: 'Electrical',
        ),
        Service(
          id: '3',
          name: 'Cleaning Masters',
          description: 'Professional cleaning services',
          rating: 4.2,
          lat: 37.7649,
          lng: -122.4294,
          category: 'Cleaning',
        ),
        Service(
          id: '4',
          name: 'Handyman Helper',
          description: 'General repair and maintenance',
          rating: 4.6,
          lat: 37.7549,
          lng: -122.4394,
          category: 'Handyman',
        ),
      ];
      _loading = false;
    });
  }

  Widget _buildTabContent() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildSearchTab();
      case 2:
        return _buildBookingsTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? constraints.maxWidth * 0.15 : 0,
                vertical: 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting Card
                  Container(
                    margin: const EdgeInsets.only(top: 32, bottom: 24),
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFF667EEA).withOpacity(0.1),
                          child: Text(
                            _currentUser?.email?.substring(0, 1).toUpperCase() ?? 'G',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF667EEA),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${_currentUser?.email?.split('@')[0] ?? 'Guest'}! 👋',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Find trusted local service providers',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.account_circle, color: Color(0xFF667EEA)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const UserDashboardScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Service Categories
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Service Categories',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        _buildCategoryCard('Plumbing', Icons.plumbing, Colors.blue),
                        _buildCategoryCard('Electrical', Icons.electrical_services, Colors.orange),
                        _buildCategoryCard('Cleaning', Icons.cleaning_services, Colors.green),
                        _buildCategoryCard('Handyman', Icons.build, Colors.purple),
                        _buildCategoryCard('Landscaping', Icons.landscape, Colors.brown),
                        _buildCategoryCard('Moving', Icons.local_shipping, Colors.red),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: CustomSearchBar(
                      controller: TextEditingController(),
                      onChanged: (val) {},
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Nearby Services
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nearby Services',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'View All',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Dynamic Services List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('services').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error:  [31m [1m [4m'));
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Center(child: Text('No services available.'));
                        }
                        final services = docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return Service(
                            id: doc.id,
                            name: data['name'] ?? '',
                            description: data['description'] ?? '',
                            rating: (data['rating'] ?? 0).toDouble(),
                            lat: (data['lat'] ?? 0).toDouble(),
                            lng: (data['lng'] ?? 0).toDouble(),
                            category: data['category'] ?? '',
                          );
                        }).toList();
                        return ServiceList(
                          services: services,
                          onBook: (service) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Book: ${service.name}')),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CustomSearchBar(
            controller: TextEditingController(),
            onChanged: (val) {},
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Search for services',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text('Please log in to view your bookings.'));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          // .orderBy('createdAt', descending: true) // Removed to avoid index
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error:  ${snapshot.error}'));
        }
        var bookings = snapshot.data?.docs ?? [];
        // Sort in Dart if needed
        bookings.sort((a, b) => (b['createdAt'] ?? '').toString().compareTo((a['createdAt'] ?? '').toString()));
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Your Bookings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No bookings yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BookingsScreen()),
                    );
                  },
                  child: const Text('Browse Services'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final data = bookings[index].data() as Map<String, dynamic>;
            final Timestamp? dateTs = data['date'] as Timestamp?;
            final DateTime? date = dateTs?.toDate();
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 3,
              child: ListTile(
                leading: Icon(Icons.home_repair_service, color: Colors.blue[700]),
                title: Text(data['serviceType']?.toString().toUpperCase() ?? 'Service'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (date != null)
                      Text('Date: ${DateFormat('yyyy-MM-dd – kk:mm').format(date)}'),
                    Text('Status: ${data['status'] ?? 'pending'}'),
                    Text('Price: ${data['price'] ?? ''} frw'),
                  ],
                ),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(data['serviceType']?.toString().toUpperCase() ?? 'Service'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tier: ${data['serviceTier'] ?? ''}'),
                          Text('Contact: ${data['contactname']} (${data['contactphone']})'),
                          Text('Location: ${data['location']}'),
                          Text('Notes: ${data['notes']}'),
                          Text('Payment: ${data['paymentstatus']}'),
                          Text('Status: ${data['status']}'),
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
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // User Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    _currentUser?.email?.substring(0, 1).toUpperCase() ?? 'G',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentUser?.email?.split('@')[0] ?? 'Guest',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _currentUser?.email ?? 'guest@example.com',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Menu Items
          _buildMenuItem(Icons.person, 'Edit Profile', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditProfileScreen()),
            );
          }),
          _buildMenuItem(Icons.star, 'Premium Features', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserPremiumScreen()),
            );
          }),
          _buildMenuItem(Icons.dashboard, 'Dashboard', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserDashboardScreen()),
            );
          }),

          _buildMenuItem(Icons.compare_arrows, 'Free vs Premium', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FreemiumModelScreen()),
            );
          }),
          _buildMenuItem(Icons.payment, 'Payment History', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PaymentHistoryScreen()),
            );
          }),
          _buildMenuItem(Icons.notifications, 'Notifications', () {}),
          _buildMenuItem(Icons.help, 'Help & Support', () {}),
          _buildMenuItem(Icons.settings, 'Settings', () {}),
          
          const Spacer(),
          
          // Sign Out Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await _authService.logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Sign Out'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingsScreen(serviceType: title),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Link'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildTabContent(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
} 