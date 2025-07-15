import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AvailableCarsScreen extends StatefulWidget {
  const AvailableCarsScreen({super.key});
  
  @override
  _AvailableCarsScreenState createState() => _AvailableCarsScreenState();
}

class _AvailableCarsScreenState extends State<AvailableCarsScreen> {
  int _selectedCategory = 0;
  int _selectedBottomNav = 0;
  String? _searchQuery;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _fetchUserPremiumStatus();
  }

  Future<void> _fetchUserPremiumStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final sub = doc.data()?['subscription'];
    setState(() {
      _isPremium = sub != null && sub['status'] == 'active';
    });
  }

  final List<String> categories = ['All', 'Luxury', 'SUV', 'Sedan'];
  final List<Map<String, dynamic>> cars = [
    {
      'name': 'BMW 3 Series',
      'price': '\$89/day',
      'image': 'assets/images/BMW 3 Series.jpeg',
      'category': 'Luxury',
    },
    {
      'name': 'Mercedes GLE',
      'price': '\$145/day',
      'image': 'assets/images/Mercedes GLE.jpeg',
      'category': 'SUV',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        leading: (ModalRoute.of(context)?.canPop ?? false)
            ? BackButton()
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset('assets/images/logo.png', height: 32),
              ),
        title: const Text('Available Cars'),
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
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
        ],
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Available Cars', style: theme.textTheme.displayMedium?.copyWith(color: theme.colorScheme.primary)),
                FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/premium_unlock'),
                  icon: const Icon(Icons.star, size: 16),
                  label: const Text('Premium'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(80, 32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or model',
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = _selectedCategory == index;
                  return ChoiceChip(
                    label: Text(categories[index]),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.secondary,
                    backgroundColor: theme.colorScheme.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? theme.colorScheme.onSecondary : theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = index;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchCars(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final cars = snapshot.data!;
                  if (cars.isEmpty) {
                    return const Center(child: Text('No cars available.'));
                  }
                  final filteredCars = cars.where((car) {
                  final matchesCategory = _selectedCategory == 0 || car['category'] == categories[_selectedCategory];
                  final matchesSearch = _searchQuery == null || _searchQuery!.isEmpty || car['name'].toLowerCase().contains(_searchQuery!.toLowerCase());
                  return matchesCategory && matchesSearch;
                  }).toList();
                  return ListView(
                    children: filteredCars.map((car) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 18),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/car_details_screen',
                              arguments: car['doc'].id, // Pass only the car ID
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                                buildCarImage(car['image']),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(car['name'], style: theme.textTheme.headlineMedium),
                                          ),
                                          if (car['isPremium'])
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.amber,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                'PREMIUM',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                  const SizedBox(height: 4),
                                  Text(car['price'], style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.secondary)),
                                  const SizedBox(height: 2),
                                  Text(car['category'], style: theme.textTheme.bodyMedium),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey),
                          ],
                        ),
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
      ),
      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
        builder: (context, snapshot) {
          int unreadCount = 0;
          if (snapshot.hasData && userId != null) {
            unreadCount = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final isForUser = data['userId'] == null || data['userId'] == userId;
              final isRead = data['readBy'] != null && (data['readBy'] as List).contains(userId);
              return isForUser && !isRead;
            }).length;
          }
          return NavigationBar(
        selectedIndex: _selectedBottomNav,
        onDestinationSelected: (index) {
          setState(() {
            _selectedBottomNav = index;
          });
          if (index == 1) {
            Navigator.pushNamed(context, '/profile');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/my_bookings_screen');
              } else if (index == 3) {
                Navigator.pushNamed(context, '/notifications');
          }
        },
            destinations: [
              const NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
              const NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
              const NavigationDestination(icon: Icon(Icons.calendar_today), label: 'Bookings'),
              NavigationDestination(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
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
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
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
                ),
                label: 'Notifications',
              ),
        ],
        height: 70,
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.secondary.withOpacity(0.1),
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchCars() async {
    final carsSnap = await FirebaseFirestore.instance.collection('cars').get();
    final cars = carsSnap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'name': data['name'] ?? '',
        'price': data['price'] != null ? 'FRW${data['price']}/day' : '',
        'image': data['image'] ?? '',
        'category': data['type'] ?? '',
        'doc': doc,
        'driverOptions': data['driverOptions'] ?? [],
        'decorationOptions': data['decorationOptions'] ?? [],
        'raw': data,
        'isPremium': false,
      };
    }).toList();
    if (_isPremium) {
      final premiumSnap = await FirebaseFirestore.instance.collection('premium_cars').get();
      cars.addAll(premiumSnap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'name': data['name'] ?? '',
          'price': data['price'] != null ? 'FRW${data['price']}/day' : '',
          'image': data['image'] ?? '',
          'category': data['type'] ?? '',
          'doc': doc,
          'driverOptions': [],
          'decorationOptions': [],
          'raw': data,
          'isPremium': true,
        };
      }));
    }
    return cars;
  }
}

Widget buildCarImage(String imagePath) {
  if (imagePath.startsWith('assets/') && imagePath.trim() != 'assets/images/' && imagePath.trim().isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        imagePath,
        width: 100,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.directions_car, size: 60),
      ),
    );
  } else if (imagePath.isNotEmpty && !imagePath.startsWith('assets/')) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imagePath,
        width: 100,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Icon(Icons.directions_car, size: 60),
      ),
    );
  } else {
    return Icon(Icons.directions_car, size: 60);
  }
}