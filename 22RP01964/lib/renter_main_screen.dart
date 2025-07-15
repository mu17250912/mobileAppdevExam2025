import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'property_model.dart';
import 'payment_page.dart'; // Added import for PaymentPage
import 'package:firebase_auth/firebase_auth.dart'; // Added import for FirebaseAuth
import 'payment_service.dart'; // Added import for PaymentService
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart'; // Added import for LoginScreen

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          // Sort by createdAt descending in Dart
          docs.sort((a, b) {
            final aDate =
                (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
            final bDate =
                (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
            return bDate.compareTo(aDate);
          });
          if (docs.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final notif = docs[index];
              final isUnread = notif['status'] == 'unread';
              final title = notif['title'] ?? '';
              final message = notif['message'] ?? '';
              final createdAt = (notif['createdAt'] as Timestamp?)?.toDate();
              return ListTile(
                tileColor: isUnread ? Colors.grey[100] : null,
                leading: Icon(
                  isUnread ? Icons.notifications_active : Icons.notifications,
                  color: isUnread ? kPrimaryColor : Colors.grey,
                ),
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message),
                    if (createdAt != null)
                      Text(
                        '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                trailing: isUnread
                    ? IconButton(
                        icon: const Icon(
                          Icons.mark_email_read,
                          color: kPrimaryColor,
                        ),
                        tooltip: 'Mark as read',
                        onPressed: () async {
                          await notif.reference.update({'status': 'read'});
                        },
                      )
                    : null,
                onTap: () async {
                  if (isUnread) {
                    await notif.reference.update({'status': 'read'});
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class RenterMainScreen extends StatefulWidget {
  const RenterMainScreen({Key? key}) : super(key: key);

  @override
  State<RenterMainScreen> createState() => _RenterMainScreenState();
}

class _RenterMainScreenState extends State<RenterMainScreen> {
  static _RenterMainScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<_RenterMainScreenState>();
  int _selectedIndex = 0;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _listenForUnreadNotifications();
  }

  void _listenForUnreadNotifications() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          final unread = snapshot.docs
              .where((doc) => doc['status'] == 'unread')
              .length;
          setState(() {
            _unreadCount = unread;
          });
        });
  }

  static final List<Widget> _screens = <Widget>[
    _RenterHomeScreen(),
    _RenterBrowseScreen(),
    _RenterBookingsScreen(),
    _RenterProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  PreferredSizeWidget _buildAppBar() {
    String title;
    switch (_selectedIndex) {
      case 0:
        title = 'Home';
        break;
      case 1:
        title = 'Browse';
        break;
      case 2:
        title = 'My Bookings';
        break;
      case 3:
        title = 'My Profile';
        break;
      default:
        title = '';
    }
    return AppBar(
      title: Text(title),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                );
              },
            ),
            if (_unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Browse'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// Convert _RenterHomeScreen to a StatefulWidget for search/filter and tap-to-details:
class _RenterHomeScreen extends StatefulWidget {
  @override
  State<_RenterHomeScreen> createState() => _RenterHomeScreenState();
}

class _RenterHomeScreenState extends State<_RenterHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.home, color: kPrimaryColor),
            const SizedBox(width: 8),
            Text(
              'Welcome to EasyRent!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search properties...',
                  prefixIcon: Icon(Icons.search, color: kPrimaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 28),
              // Welcome message
              Text(
                'Find your next home or investment',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Browse featured properties, book instantly, and enjoy a seamless renting experience.',
                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
              ),
              const SizedBox(height: 28),
              // Featured Properties Carousel
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Featured Properties',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  TextButton(
                    onPressed: () {
                      final parentState = _RenterMainScreenState.of(context);
                      if (parentState != null) {
                        parentState.setState(() {
                          parentState._selectedIndex =
                              1; // Switch to Browse tab
                        });
                      }
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('properties')
                    .where('status', isEqualTo: 'available')
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          3,
                          (index) => Container(
                            width: 320,
                            margin: const EdgeInsets.only(
                              right: 16,
                              top: 8,
                              bottom: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: kPrimaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: \\${snapshot.error}'));
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('No featured properties found.'),
                    );
                  }
                  var properties = docs
                      .map(
                        (doc) => Property.fromMap(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        ),
                      )
                      .toList();
                  // Apply search filter
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    properties = properties
                        .where(
                          (p) =>
                              p.title.toLowerCase().contains(q) ||
                              p.address.toLowerCase().contains(q) ||
                              p.category.toLowerCase().contains(q),
                        )
                        .toList();
                  }
                  if (properties.isEmpty) {
                    return const Center(
                      child: Text('No properties match your search.'),
                    );
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        properties.length,
                        (index) => Padding(
                          padding: EdgeInsets.only(
                            right: index == properties.length - 1 ? 0 : 16,
                            top: 8,
                            bottom: 8,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PropertyDetailsScreen(
                                    property: properties[index],
                                  ),
                                ),
                              );
                            },
                            child: _PropertyCardFirestore(
                              property: properties[index],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // Entertaining section: Tips, fun facts, or testimonials
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.lightbulb, color: kPrimaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Did you know?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can book a property instantly and chat with owners directly on EasyRent!',
                      style: TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'More Available Properties',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('properties')
                    .where('status', isEqualTo: 'available')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: \\${snapshot.error}'));
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('No more properties found.'),
                    );
                  }
                  // Exclude properties already shown in the featured carousel (limit 5)
                  final featuredIds = docs.take(5).map((doc) => doc.id).toSet();
                  final remainingDocs = docs
                      .where((doc) => !featuredIds.contains(doc.id))
                      .toList();
                  if (remainingDocs.isEmpty) {
                    return const Center(
                      child: Text('No more properties found.'),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: remainingDocs.length,
                    itemBuilder: (context, index) {
                      final property = Property.fromMap(
                        remainingDocs[index].data() as Map<String, dynamic>,
                        remainingDocs[index].id,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PropertyDetailsScreen(property: property),
                              ),
                            );
                          },
                          child: _PropertyCardFirestore(property: property),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RenterBrowseScreen extends StatefulWidget {
  @override
  State<_RenterBrowseScreen> createState() => _RenterBrowseScreenState();
}

class _RenterBrowseScreenState extends State<_RenterBrowseScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal() async {
    final categories = ['Apartment', 'House', 'Studio', 'Other'];
    final types = ['rent', 'sale'];
    String? selectedType = _selectedType;
    final selected = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // <-- add this
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 18,
              left: 0,
              right: 0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 18),
                const Text(
                  'Filter by Category',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                ...categories.map(
                  (cat) => ListTile(
                    title: Text(cat),
                    trailing: _selectedCategory == cat
                        ? const Icon(Icons.check, color: kPrimaryColor)
                        : null,
                    onTap: () => Navigator.pop(context, {
                      'category': cat,
                      'type': selectedType,
                    }),
                  ),
                ),
                const Divider(),
                const Text(
                  'Filter by Type',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                ...types.map(
                  (type) => ListTile(
                    title: Text(type[0].toUpperCase() + type.substring(1)),
                    trailing: selectedType == type
                        ? const Icon(Icons.check, color: kPrimaryColor)
                        : null,
                    onTap: () => Navigator.pop(context, {
                      'category': _selectedCategory,
                      'type': type,
                    }),
                  ),
                ),
                ListTile(
                  title: const Text('Clear Filter'),
                  onTap: () =>
                      Navigator.pop(context, {'category': null, 'type': null}),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null) {
      setState(() {
        _selectedCategory = selected['category'];
        _selectedType = selected['type'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Properties')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search and filters
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search by location, title... ',
                      prefixIcon: Icon(Icons.search, color: kPrimaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.filter_alt_rounded, color: kPrimaryColor),
                  onPressed: _showFilterModal,
                  tooltip: 'Filters',
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Listings grid from Firestore
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('properties')
                    .where('status', isEqualTo: 'available')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: \\${snapshot.error}'));
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('No properties found.'));
                  }
                  var properties = docs
                      .map(
                        (doc) => Property.fromMap(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        ),
                      )
                      .toList();
                  // Apply search filter
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    properties = properties
                        .where(
                          (p) =>
                              p.title.toLowerCase().contains(q) ||
                              p.address.toLowerCase().contains(q) ||
                              p.category.toLowerCase().contains(q),
                        )
                        .toList();
                  }
                  // Apply category filter
                  if (_selectedCategory != null) {
                    properties = properties
                        .where(
                          (p) =>
                              p.category.toLowerCase() ==
                              _selectedCategory!.toLowerCase(),
                        )
                        .toList();
                  }
                  // Apply type filter
                  if (_selectedType != null) {
                    properties = properties
                        .where((p) => p.propertyType == _selectedType)
                        .toList();
                  }
                  if (properties.isEmpty) {
                    return const Center(
                      child: Text('No properties match your search/filter.'),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    itemCount: properties.length,
                    itemBuilder: (context, index) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PropertyDetailsScreen(
                                    property: properties[index],
                                  ),
                                ),
                              );
                            },
                            child: _PropertyCardFirestore(
                              property: properties[index],
                            ),
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

// 1. Update PropertyDetailsScreen:
class PropertyDetailsScreen extends StatelessWidget {
  final Property property;
  const PropertyDetailsScreen({required this.property});
  @override
  Widget build(BuildContext context) {
    final isForRent = property.propertyType.toLowerCase().contains('rent');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          property.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (property.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    child: Image.network(
                      property.imageUrl,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isForRent
                                  ? kPrimaryColor.withOpacity(0.12)
                                  : Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isForRent ? 'For Rent' : 'For Sale',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isForRent
                                    ? kPrimaryColor
                                    : Colors.green[800],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.location_on,
                            color: kPrimaryColor,
                            size: 18,
                          ),
                          Flexible(
                            child: Text(
                              property.address,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        property.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'RWF ${property.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: kPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Icon(Icons.king_bed, size: 20, color: kPrimaryColor),
                          const SizedBox(width: 6),
                          Text(
                            '${property.bedrooms} bedrooms',
                            style: TextStyle(fontSize: 15),
                          ),
                          const SizedBox(width: 18),
                          Icon(Icons.bathtub, size: 20, color: kPrimaryColor),
                          const SizedBox(width: 6),
                          Text(
                            '${property.bathrooms} bathrooms',
                            style: TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (property.amenities.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Amenities:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: property.amenities
                                  .map(
                                    (a) => Chip(
                                      label: Text(
                                        a,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      backgroundColor: kPrimaryColor
                                          .withOpacity(0.08),
                                      labelStyle: const TextStyle(
                                        color: kPrimaryColor,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 18),
                          ],
                        ),
                      if (property.description != null &&
                          property.description!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              property.description!,
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 18),
                          ],
                        ),
                      const SizedBox(height: 80), // For button spacing
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Book/Buy button at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentPage(
                          initialAmount: property.price.toStringAsFixed(0),
                          // Optionally pass initialPhone if available
                          onPaymentSuccess: (txRef) async {
                            // Retrieve current user UID (buyer)
                            final buyerId =
                                FirebaseAuth.instance.currentUser?.uid ?? '';
                            await PaymentService.handlePostPayment(
                              propertyId: property.id,
                              propertyType: property.propertyType,
                              price: property.price,
                              ownerId: property.ownerId,
                              txRef: txRef,
                              buyerId: buyerId,
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingConfirmationScreen(
                                  property: property,
                                  phone:
                                      '', // You can retrieve from PaymentPage if needed
                                  amount: property.price,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    minimumSize: const Size(90, 48),
                  ),
                  child: Text(isForRent ? 'Book Now' : 'Buy Now'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 2. BookingScreen (stub, no payment logic):
class BookingScreen extends StatefulWidget {
  final Property property;
  const BookingScreen({required this.property});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isForRent = widget.property.propertyType.toLowerCase().contains(
      'rent',
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.property.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'RWF ${widget.property.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: kPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Type: ${isForRent ? 'Rent' : 'Sale'}',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Mobile Money Number',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Enter your mobile money number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() => _isLoading = true);
                          await Future.delayed(
                            const Duration(seconds: 1),
                          ); // Simulate API call
                          setState(() => _isLoading = false);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingConfirmationScreen(
                                property: widget.property,
                                phone: _phoneController.text,
                                amount: widget.property.price,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    minimumSize: const Size(90, 48),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Pay Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 3. BookingConfirmationScreen (stub):
class BookingConfirmationScreen extends StatelessWidget {
  final Property property;
  final String phone;
  final double amount;
  const BookingConfirmationScreen({
    required this.property,
    required this.phone,
    required this.amount,
  });
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 18),
            const Text(
              'Booking Successful!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 18),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Amount Paid: RWF ${amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Date: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'You will receive a confirmation email shortly.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  minimumSize: const Size(90, 48),
                ),
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyCardFirestore extends StatelessWidget {
  final Property property;
  const _PropertyCardFirestore({required this.property});

  @override
  Widget build(BuildContext context) {
    final badgeColor = property.propertyType.toLowerCase() == 'rent'
        ? kPrimaryColor
        : Colors.green[600];
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth * 0.85).clamp(260.0, 340.0);
        return Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: cardWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: property.imageUrl.isNotEmpty
                      ? Image.network(
                          property.imageUrl,
                          width: cardWidth,
                          height: 140,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: cardWidth,
                          height: 140,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.home,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              property.category[0].toUpperCase() +
                                  property.category.substring(1),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.favorite_border,
                              color: Colors.grey[500],
                            ),
                            onPressed: () {},
                            splashRadius: 18,
                            tooltip: 'Add to favorites',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        property.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'RWF ${property.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: kPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.grey[600],
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              property.address,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Replace _RenterBookingsScreen with a functional booking history tab
class _RenterBookingsScreen extends StatefulWidget {
  @override
  State<_RenterBookingsScreen> createState() => _RenterBookingsScreenState();
}

class _RenterBookingsScreenState extends State<_RenterBookingsScreen> {
  String _filter = 'all'; // all, active, completed

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Removed filter toggle
          const SizedBox(height: 0),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('buyerId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: \\${snapshot.error}'));
                }
                final docs = snapshot.data?.docs ?? [];
                // Sort by createdAt descending in Dart
                docs.sort((a, b) {
                  final aDate =
                      (a['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime(1970);
                  final bDate =
                      (b['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime(1970);
                  return bDate.compareTo(aDate);
                });
                var bookings = docs;
                // No filter, show all
                if (bookings.isEmpty) {
                  return const Center(child: Text('No bookings found.'));
                }
                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final title =
                        booking['propertyTitle'] ??
                        booking['propertyId'] ??
                        'Unknown Property';
                    final amount = booking['amount'] ?? 0;
                    final date = (booking['createdAt'] as Timestamp?)?.toDate();
                    final status = booking['status'] ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Amount Paid: RWF $amount',
                              style: TextStyle(
                                color: kPrimaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (date != null)
                              Text(
                                'Date: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                              ),
                            Text(
                              'Status: ${status[0].toUpperCase()}${status.substring(1)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        trailing: ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Receipt'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Property: $title'),
                                    Text('Amount: RWF $amount'),
                                    if (date != null)
                                      Text(
                                        'Date: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                                      ),
                                    Text(
                                      'Status: ${status[0].toUpperCase()}${status.substring(1)}',
                                    ),
                                    Text(
                                      'Transaction Ref: ${booking['txRef'] ?? ''}',
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
                          },
                          icon: const Icon(Icons.receipt_long, size: 18),
                          label: const Text('View Receipt'),
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
}

class _RenterProfileScreen extends StatefulWidget {
  @override
  State<_RenterProfileScreen> createState() => _RenterProfileScreenState();
}

class _RenterProfileScreenState extends State<_RenterProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  String? _name;
  String? _email;
  String? _phone;
  String? _role;
  String? _avatarUrl;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _showChangePassword = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _checkProvider();
  }

  void _checkProvider() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.providerData.isNotEmpty) {
      setState(() {
        _showChangePassword = user.providerData[0].providerId == 'password';
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      print('No current user in FirebaseAuth.');
      return;
    }
    print('Current UID: ${user.uid}');
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!doc.exists) {
        setState(() => _isLoading = false);
        print('No Firestore user document found for UID: ${user.uid}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user profile found in Firestore.')),
        );
        return;
      }
      final data = doc.data() ?? {};
      print('Fetched Firestore user data: ${data.toString()}');
      final firestoreName = data['name'] as String?;
      final firestoreEmail = data['email'] as String?;
      final firestorePhone = data['phone'] as String?;
      setState(() {
        _name = (firestoreName != null && firestoreName.isNotEmpty)
            ? firestoreName
            : (user.displayName ?? 'No Name');
        _email = (firestoreEmail != null && firestoreEmail.isNotEmpty)
            ? firestoreEmail
            : (user.email ?? 'No Email');
        _phone = (firestorePhone != null && firestorePhone.isNotEmpty)
            ? firestorePhone
            : '';
        _role = data['role'] ?? '';
        _avatarUrl = data['photoURL'] ?? user.photoURL ?? '';
        _nameController.text = _name ?? '';
        _phoneController.text = _phone ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error fetching user profile: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedImageBytes = result.files.single.bytes;
        _selectedImageName = result.files.single.name;
      });
    }
  }

  Future<String?> _uploadToCloudinary(
    Uint8List imageBytes,
    String fileName,
  ) async {
    const cloudName = 'dwavfe9yo';
    const uploadPreset = 'easyrent_unsigned';
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes('file', imageBytes, filename: fileName),
      );
    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);
      return data['secure_url'] as String?;
    } else {
      return null;
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String? avatarUrl = _avatarUrl;
    if (_selectedImageBytes != null && _selectedImageName != null) {
      final uploaded = await _uploadToCloudinary(
        _selectedImageBytes!,
        _selectedImageName!,
      );
      if (uploaded != null) {
        avatarUrl = uploaded;
      }
    }
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'photoURL': avatarUrl,
    }, SetOptions(merge: true));
    setState(() {
      _isEditing = false;
      _isLoading = false;
      _name = _nameController.text.trim();
      _phone = _phoneController.text.trim();
      _avatarUrl = avatarUrl;
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
              ),
              obscureText: true,
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
              final user = FirebaseAuth.instance.currentUser;
              final oldPassword = oldPasswordController.text.trim();
              final newPassword = newPasswordController.text.trim();
              final confirmPassword = confirmPasswordController.text.trim();
              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match.')),
                );
                return;
              }
              if (user != null && user.email != null) {
                try {
                  final cred = EmailAuthProvider.credential(
                    email: user.email!,
                    password: oldPassword,
                  );
                  await user.reauthenticateWithCredential(cred);
                  await user.updatePassword(newPassword);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password updated successfully.'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: kPrimaryColor.withOpacity(0.1),
                          backgroundImage: _selectedImageBytes != null
                              ? MemoryImage(_selectedImageBytes!)
                              : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                              ? NetworkImage(_avatarUrl!) as ImageProvider
                              : null,
                          child:
                              (_avatarUrl == null || _avatarUrl!.isEmpty) &&
                                  _selectedImageBytes == null
                              ? const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: kPrimaryColor,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.edit,
                                size: 18,
                                color: kPrimaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (_name != null && _name!.isNotEmpty)
                                ? _name!
                                : 'No Name',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (_email != null && _email!.isNotEmpty)
                                ? _email!
                                : 'No Email',
                            style: const TextStyle(fontSize: 15),
                          ),
                          Text(
                            (_phone != null && _phone!.isNotEmpty)
                                ? 'Phone: $_phone'
                                : 'Phone: Not set',
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (_role != null && _role!.isNotEmpty)
                            Text(
                              'Role: $_role',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isEditing ? Icons.close : Icons.edit,
                        color: kPrimaryColor,
                      ),
                      onPressed: () => setState(() => _isEditing = !_isEditing),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_isEditing)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            minimumSize: const Size.fromHeight(44),
                          ),
                          child: const Text('Save Changes'),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  )
                else ...[
                  if (_showChangePassword)
                    Padding(
                      padding: const EdgeInsets.only(top: 18.0),
                      child: Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.lock),
                          label: const Text('Change Password'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            minimumSize: const Size.fromHeight(44),
                          ),
                          onPressed: _showChangePasswordDialog,
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
  }
}
