import 'package:flutter/material.dart';
import '../services/data_seeder.dart';
import '../services/firebase_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final DataSeeder _dataSeeder = DataSeeder();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F5E8), // Soft green background
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Firebase Data Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Seed Data Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _seedData,
              icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload),
              label: Text(_isLoading ? 'Seeding Data...' : 'Seed Firebase Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Clear Data Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _clearData,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Clear All Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Data Status
            const Text(
              'Data Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Status Cards
            Expanded(
              child: FutureBuilder(
                future: _getDataStatus(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  
                  final status = snapshot.data as Map<String, int>;
                  
                  return ListView(
                    children: [
                      _buildStatusCard('Books', status['books'] ?? 0, Icons.book, Colors.blue),
                      _buildStatusCard('Categories', status['categories'] ?? 0, Icons.category, Colors.green),
                      _buildStatusCard('Users', status['users'] ?? 0, Icons.people, Colors.orange),
                      _buildStatusCard('Orders', status['orders'] ?? 0, Icons.shopping_cart, Colors.purple),
                      _buildStatusCard('Favorites', status['favorites'] ?? 0, Icons.favorite, Colors.red),
                      _buildStatusCard('Reviews', status['reviews'] ?? 0, Icons.rate_review, Colors.teal),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, int count, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Text('$count items'),
        trailing: Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Future<Map<String, int>> _getDataStatus() async {
    try {
      final books = await _firebaseService.getAllBooks();
      final categories = await _firebaseService.getAllCategories();
      
      // Get counts for other collections
      final usersSnapshot = await _firebaseService.firestore.collection(FirebaseService.usersCollection).get();
      final ordersSnapshot = await _firebaseService.firestore.collection(FirebaseService.ordersCollection).get();
      final favoritesSnapshot = await _firebaseService.firestore.collection(FirebaseService.favoritesCollection).get();
      final reviewsSnapshot = await _firebaseService.firestore.collection(FirebaseService.reviewsCollection).get();
      
      return {
        'books': books.length,
        'categories': categories.length,
        'users': usersSnapshot.docs.length,
        'orders': ordersSnapshot.docs.length,
        'favorites': favoritesSnapshot.docs.length,
        'reviews': reviewsSnapshot.docs.length,
      };
    } catch (e) {
      return {
        'books': 0,
        'categories': 0,
        'users': 0,
        'orders': 0,
        'favorites': 0,
        'reviews': 0,
      };
    }
  }

  Future<void> _seedData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _dataSeeder.seedAllData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Data seeded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh the status
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error seeding data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to clear all data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _dataSeeder.clearAllData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ All data cleared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh the status
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error clearing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 