import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NearbyVendorsPage extends StatefulWidget {
  const NearbyVendorsPage({Key? key}) : super(key: key);

  @override
  State<NearbyVendorsPage> createState() => _NearbyVendorsPageState();
}

class _NearbyVendorsPageState extends State<NearbyVendorsPage> {
  String _selectedFilter = 'All';
  double _distance = 5.0; // km

  // Remove manual _vendors list

  List<Map<String, dynamic>> get _filteredVendors => [];

  void _showVendorDetails(Map<String, dynamic> vendor, List<Map<String, dynamic>> products) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vendor['vendorName'] ?? vendor['vendorEmail'] ?? 'Vendor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (products.isNotEmpty)
              Image.asset(
                products.first['image'],
                width: 200,
                height: 120,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 16),
            Text('Email: ${vendor['vendorEmail'] ?? ''}'),
            if ((vendor['vendorName'] ?? '').isNotEmpty)
              Text('Type: ${vendor['vendorName']}'),
            if ((vendor['location'] ?? '').isNotEmpty)
              Text('Location: ${vendor['location']}'),
            Text('Vendor ID: ${vendor['vendorId'] ?? ''}'),
            const SizedBox(height: 8),
            const Text('Products:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...products.map((p) => Text('• ${p['name']} (${p['price']} FRW)')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9C7B7B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9C7B7B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Nearby Vendors', style: TextStyle(color: Colors.black)),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No vendors found.'));
          }
          final products = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
          // Group products by vendorId
          final Map<String, List<Map<String, dynamic>>> vendorProducts = {};
          for (var p in products) {
            final vendorId = p['vendorId'] ?? 'unknown';
            vendorProducts.putIfAbsent(vendorId, () => []).add(p);
          }
          // Fetch vendor info from users collection
          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('users').get(),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final userDocs = userSnap.data?.docs ?? [];
              final Map<String, Map<String, dynamic>> userInfo = {
                for (var doc in userDocs)
                  doc.id: doc.data() as Map<String, dynamic>
              };
              final vendors = vendorProducts.entries.map((e) {
                final firstProduct = e.value.first;
                final user = userInfo[e.key] ?? {};
                return {
                  'vendorId': e.key,
                  'vendorEmail': firstProduct['vendorEmail'] ?? '',
                  'vendorName': user['type'] ?? '',
                  'location': user['location'] ?? '',
                  'products': e.value,
                };
              }).toList();
              return ListView.builder(
                itemCount: vendors.length,
                itemBuilder: (context, index) {
                  final vendor = vendors[index];
                  final vendorProductsList = vendor['products'] as List<Map<String, dynamic>>;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: vendorProductsList.isNotEmpty
                          ? Image.asset(vendorProductsList.first['image'], width: 50, height: 50, fit: BoxFit.cover)
                          : const Icon(Icons.store, size: 40),
                      title: Text(vendor['vendorEmail'] ?? 'Vendor', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((vendor['vendorName'] ?? '').isNotEmpty)
                            Text('Type: ${vendor['vendorName']}'),
                          if ((vendor['location'] ?? '').isNotEmpty)
                            Text('Location: ${vendor['location']}'),
                          Text('Products: ${vendorProductsList.length}'),
                        ],
                      ),
                      onTap: () => _showVendorDetails(vendor, vendorProductsList),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF9C7B7B),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle, color: Colors.blue),
            label: 'My Profile',
          ),
        ],
      ),
    );
  }
} 