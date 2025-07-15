import 'dart:async';
import 'package:flutter/material.dart';
import 'car_details_screen.dart';
import 'admin_panel_screen.dart';
import 'notifications_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userRole = 'user'; // 'admin' or 'user'
  String userName = '';

  final List<Map<String, dynamic>> cars = [
    {
      'brand': 'Toyota', 'model': 'Corolla', 'price': 50000, 'available': true, 'image': 'https://cdn.pixabay.com/photo/2012/05/29/00/43/car-49278_1280.jpg',
    },
    {
      'brand': 'Honda', 'model': 'Civic', 'price': 60000, 'available': false, 'image': 'https://cdn.pixabay.com/photo/2015/01/19/13/51/car-604019_1280.jpg',
    },
    {
      'brand': 'Ford', 'model': 'Focus', 'price': 55000, 'available': true, 'image': 'https://cdn.pixabay.com/photo/2016/11/29/09/32/auto-1868726_1280.jpg',
    },
    {
      'brand': 'BMW', 'model': '3 Series', 'price': 120000, 'available': true, 'image': 'https://cdn.pixabay.com/photo/2017/01/06/19/15/bmw-1957037_1280.jpg',
    },
    {
      'brand': 'Mercedes', 'model': 'C-Class', 'price': 130000, 'available': false, 'image': 'https://cdn.pixabay.com/photo/2015/01/19/13/51/car-604019_1280.jpg',
    },
    {
      'brand': 'Audi', 'model': 'A4', 'price': 110000, 'available': true, 'image': 'https://cdn.pixabay.com/photo/2012/05/29/00/43/car-49278_1280.jpg',
    },
    {
      'brand': 'Volkswagen', 'model': 'Golf', 'price': 70000, 'available': true, 'image': 'https://cdn.pixabay.com/photo/2016/11/29/09/32/auto-1868726_1280.jpg',
    },
    {
      'brand': 'Nissan', 'model': 'Altima', 'price': 65000, 'available': false, 'image': 'https://cdn.pixabay.com/photo/2017/01/06/19/15/bmw-1957037_1280.jpg',
    },
    {
      'brand': 'Hyundai', 'model': 'Elantra', 'price': 60000, 'available': true, 'image': 'https://cdn.pixabay.com/photo/2012/05/29/00/43/car-49278_1280.jpg',
    },
    {
      'brand': 'Kia', 'model': 'Optima', 'price': 62000, 'available': true, 'image': 'https://cdn.pixabay.com/photo/2015/01/19/13/51/car-604019_1280.jpg',
    },
    {
      'brand': 'Mazda', 'model': 'Mazda3', 'price': 63000, 'available': false, 'image': 'https://cdn.pixabay.com/photo/2016/11/29/09/32/auto-1868726_1280.jpg',
    },
    {
      'brand': 'Chevrolet', 'model': 'Malibu', 'price': 67000, 'available': true, 'image': 'https://cdn.pixabay.com/photo/2017/01/06/19/15/bmw-1957037_1280.jpg',
    },
    {
      'brand': 'Subaru', 'model': 'Impreza', 'price': 68000, 'available': true, 'image': 'https://cdn.pixabay.com/photo/2012/05/29/00/43/car-49278_1280.jpg',
    },
    {
      'brand': 'Peugeot', 'model': '308', 'price': 71000, 'available': false, 'image': 'https://cdn.pixabay.com/photo/2015/01/19/13/51/car-604019_1280.jpg',
    },
    {
      'brand': 'Renault', 'model': 'Megane', 'price': 72000, 'available': true, 'image': 'https://cdn.pixabay.com/photo/2016/11/29/09/32/auto-1868726_1280.jpg',
    },
    {
      'brand': 'Fiat', 'model': 'Tipo', 'price': 69000, 'available': true, 'image': 'https://cdn.pixabay.com/photo/2017/01/06/19/15/bmw-1957037_1280.jpg',
    },
    {
      'brand': 'Jeep', 'model': 'Compass', 'price': 90000, 'available': false, 'image': 'https://cdn.pixabay.com/photo/2012/05/29/00/43/car-49278_1280.jpg',
    },
    {
      'brand': 'Land Rover', 'model': 'Discovery', 'price': 200000, 'available': true, 'image': 'https://cdn.pixabay.com/photo/2015/01/19/13/51/car-604019_1280.jpg',
    },
    {
      'brand': 'Volvo', 'model': 'S60', 'price': 115000, 'available': true, 'image': 'https://cdn.pixabay.com/photo/2016/11/29/09/32/auto-1868726_1280.jpg',
    },
    {
      'brand': 'Tesla', 'model': 'Model 3', 'price': 250000, 'available': true, 'image': 'https://cdn.pixabay.com/photo/2017/01/06/19/15/bmw-1957037_1280.jpg',
    },
  ];
  String search = '';
  StreamSubscription? _carSubscription;
  DateTime? _lastCarTimestamp;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _showLoginDialog);
    _listenForNewCars();
  }

  void _showLoginDialog() async {
    String tempRole = userRole;
    String tempName = userName;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Your Name'),
              onChanged: (v) => tempName = v,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: tempRole,
              items: const [
                DropdownMenuItem(value: 'user', child: Text('Standard User')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (v) => tempRole = v ?? 'user',
              decoration: const InputDecoration(labelText: 'Role'),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                userRole = tempRole;
                userName = tempName.isEmpty ? (userRole == 'admin' ? 'Admin' : 'User') : tempName;
              });
              Navigator.pop(context);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _listenForNewCars() {
    _carSubscription = FirebaseFirestore.instance
        .collection('cars')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docChanges.isNotEmpty) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final car = change.doc.data();
            final createdAt = DateTime.tryParse(car?['createdAt'] ?? '');
            // Only notify for cars added after the user opened the app
            if (_lastCarTimestamp == null || (createdAt != null && createdAt.isAfter(_lastCarTimestamp!))) {
              _lastCarTimestamp = createdAt ?? DateTime.now();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('New car added: ${car?['brand']} ${car?['model']}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _carSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCars = cars.where((car) {
      final query = search.toLowerCase();
      return car['brand'].toLowerCase().contains(query) ||
          car['model'].toLowerCase().contains(query);
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.directions_car, color: Colors.white),
            const SizedBox(width: 8),
            const Text('CarRent', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
          if (userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
                );
              },
            ),
        ],
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFE3E3F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: userRole == 'admin' ? Colors.deepPurple : Colors.blue,
                    child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Welcome, $userName!\nRole: ${userRole == 'admin' ? 'Admin' : 'Standard User'}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search cars...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) => setState(() => search = value),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: filteredCars.length,
                itemBuilder: (context, index) {
                  final car = filteredCars[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(car['image'], width: 70, height: 70, fit: BoxFit.cover),
                      ),
                      title: Text('${car['brand']} ${car['model']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Price: ${car['price']} RWF/day', style: const TextStyle(color: Colors.deepPurple)),
                          Text(car['available'] ? 'Available' : 'Not Available', style: TextStyle(color: car['available'] ? Colors.green : Colors.red)),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.deepPurple),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CarDetailsScreen(car: car),
                          ),
                        );
                      },
                    ),
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