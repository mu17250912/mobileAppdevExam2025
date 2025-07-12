import 'package:flutter/material.dart';
import '../models/bmi_entry.dart';
import '../services/bmi_firebase_service.dart';
import 'dashboard_screen.dart';
import 'calculator_screen.dart';
import 'profile_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/app_drawer.dart';
import 'login_screen.dart';
import 'user_bmi_records_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/profile_service.dart';
import 'dart:io';
import 'recommendations_screen.dart';
import 'settings_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final BMIFirebaseService historyService = BMIFirebaseService();

  Future<List<BMIEntry>>? _entriesFuture;
  File? _profileImage;
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _loadProfilePhoto();
  }

  void _loadEntries() {
    final userId = LoginScreen.loggedInUserId ?? '';
    print('Loading entries for userId: ' + userId);
    setState(() {
      _entriesFuture = historyService.getUserEntries(userId);
    });
  }

  Future<void> _loadProfilePhoto() async {
    final photo = await _profileService.getProfilePhoto();
    if (photo != null) {
      setState(() {
        _profileImage = photo;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'today, ${_formatTime(date)}';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'yesterday, ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getUserName() {
    final email = LoginScreen.loggedInEmail ?? '';
    if (email.isEmpty) return 'User';
    // Extract name from email (before @ symbol)
    final name = email.split('@')[0];
    // Capitalize first letter
    return name.isNotEmpty ? name[0].toUpperCase() + name.substring(1) : 'User';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI History'),
        backgroundColor: Colors.indigo[400],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEntries,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile Section
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.indigo[400],
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : null,
                  child: _profileImage == null
                      ? const Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome ${_getUserName()} to FitTrack BMI',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'View your BMI history',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<List<BMIEntry>>(
                future: _entriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    print('Error fetching history: ${snapshot.error}');
                    return const Center(child: Text('Error loading history'));
                  }
                  final entries = snapshot.data ?? [];
                  print("Fetched entries for user: '${LoginScreen.loggedInUserId}' -> $entries");
                  if (entries.isEmpty) {
                    return const Center(child: Text('No history yet.', style: TextStyle(fontSize: 18)));
                  }
                  // BMI Trend Chart
                  return ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Icon(Icons.monitor_heart, color: Colors.indigo[400]),
                          title: Text('${entry.bmi.toStringAsFixed(1)} - ${entry.category}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_formatDate(entry.date)),
                              if (entry.weight != null && entry.height != null)
                                Text('Weight: ${entry.weight} kg, Height: ${entry.height} m'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete Entry',
                            onPressed: () async {
                              if (entry.id != null) {
                                await historyService.deleteEntry(LoginScreen.loggedInUserId ?? '', entry.id!);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Entry deleted'), backgroundColor: Colors.red),
                                );
                                _loadEntries();
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // --- Raw Firestore Data Section ---
            FutureBuilder<List<Map<String, dynamic>>>(
              future: historyService.getUserBMIRecordsRaw(LoginScreen.loggedInUserId ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading raw Firestore data'));
                }
                final rawEntries = snapshot.data ?? [];
                if (rawEntries.isEmpty) {
                  return const Center(child: Text('No raw Firestore records found.', style: TextStyle(fontSize: 16)));
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Raw Firestore Records:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        itemCount: rawEntries.length,
                        itemBuilder: (context, index) {
                          final record = rawEntries[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text('BMI: 9${record['bmi'] ?? '-'}'),
                              subtitle: Text('Date: ${record['date'] ?? '-'} | Category: ${record['category'] ?? '-'}'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserBMIRecordsScreen()),
                );
              },
              child: const Text('View All Raw Firestore Records'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[400],
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete All History'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete All History'),
                    content: const Text('Are you sure you want to delete all your BMI history? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete All', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await historyService.deleteAllEntries(LoginScreen.loggedInUserId ?? '');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All history deleted'), backgroundColor: Colors.red),
                  );
                  _loadEntries();
                }
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const CalculatorScreen()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          } else if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const RecommendationsScreen()),
            );
          } else if (index == 5) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          }
        },
      ),
    );
  }
} 