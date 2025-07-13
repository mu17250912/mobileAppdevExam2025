import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../models/medication.dart';
import '../medications/add_medication_screen.dart';
import '../settings/profile_screen.dart';
import '../medications/medication_history_screen.dart';
import '../app/analytics_service.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'package:confetti/confetti.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  Future<void> _unlockPremium(BuildContext context, int coins, String uid, DateTime? premiumUntil) async {
    if (premiumUntil != null && premiumUntil.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Premium already active until ${premiumUntil.toLocal().toString().split(" ")[0]}')),
      );
      return;
    }
    if (coins < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins to unlock premium.')),);
      return;
    }
    final newPremiumUntil = DateTime.now().add(const Duration(days: 7));
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'coins': coins - 50,
      'premiumUntil': newPremiumUntil.toIso8601String(),
    }, SetOptions(merge: true));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Premium Unlocked!'),
        content: Text('You are now premium until ${newPremiumUntil.toLocal().toString().split(" ")[0]}'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements & Rewards')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final coins = data['coins'] ?? 0;
          final badges = List<String>.from(data['badges'] ?? []);
          final premiumUntilStr = data['premiumUntil'] as String?;
          final premiumUntil = premiumUntilStr != null ? DateTime.tryParse(premiumUntilStr) : null;
          final isPremium = premiumUntil != null && premiumUntil.isAfter(DateTime.now());
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 32),
                    const SizedBox(width: 8),
                    Text('Coins: $coins', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                if (isPremium)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text('Premium active until ${premiumUntil!.toLocal().toString().split(" ")[0]}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  )
                else
                  ElevatedButton.icon(
                    icon: const Icon(Icons.star),
                    label: const Text('Unlock Premium for 1 Week (50 coins)'),
                    onPressed: () => _unlockPremium(context, coins, uid, premiumUntil),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                  ),
                const SizedBox(height: 24),
                const Text('Badges:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (badges.isEmpty)
                  const Text('No badges yet. Complete goals to earn badges!'),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: badges.map((badge) => Chip(label: Text(badge, style: const TextStyle(fontSize: 16)), avatar: const Icon(Icons.emoji_events, color: Colors.orange))).toList(),
                ),
                const SizedBox(height: 32),
                const Text('More rewards and features coming soon!', style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _webReminderMessage;
  int _selectedIndex = 0;
  final ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 2));

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _showConfetti() {
    _confettiController.play();
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return _MedicationListPage();
      case 1:
        return AddMedicationScreen();
      case 2:
        return MedicationHistoryScreen();
      default:
        return _MedicationListPage();
    }
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      NotificationService.webReminderCallback = (dateTime, body) {
        setState(() {
          _webReminderMessage = body;
        });
      };
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          if (!context.mounted) return const SizedBox.shrink();
          Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final uid = snapshot.data!.uid;
        return Scaffold(
          appBar: AppBar(
            title: const Text('MedTrack'),
            actions: [
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                  final coins = data['coins'] ?? 0;
                  return Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber),
                      Text(' $coins', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                    ],
                  );
                },
              ),
            ],
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Color(0xFF673AB7)),
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.medical_services, color: Colors.white, size: 48),
                      SizedBox(height: 8),
                      Text('Medical Reminder', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Home'),
                  selected: _selectedIndex == 0,
                  onTap: () {
                    setState(() => _selectedIndex = 0);
                    Navigator.pop(context);
                  },
                ),
                          ListTile(
                            leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(onShowAchievements: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsScreen()));
                    })));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.emoji_events),
                  title: const Text('Achievements'),
                            onTap: () {
                              Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsScreen()));
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.history),
                            title: const Text('Medication History'),
                  selected: _selectedIndex == 2,
                            onTap: () {
                    setState(() => _selectedIndex = 2);
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.settings),
                            title: const Text('Settings'),
                            onTap: () {
                              Navigator.pop(context);
                              showModalBottomSheet(
                                context: context,
                      builder: (context) => _SettingsModal(),
                                              );
                                            },
                                          ),
                const Divider(),
                          ListTile(
                            leading: const Icon(Icons.logout),
                            title: const Text('Logout'),
                            onTap: () async {
                              Navigator.pop(context);
                              await FirebaseAuth.instance.signOut();
                              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                            },
                          ),
                        ],
                      ),
                    ),
          body: Stack(
            children: [
              if (_selectedIndex == 0) ...[
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                    final dailyCompletions = data['dailyCompletions'] ?? 0;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (dailyCompletions < 3)
                          Card(
                            color: Colors.amber.shade100,
                            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            child: ListTile(
                              leading: const Icon(Icons.emoji_events, color: Colors.orange),
                              title: Text('Daily Goal: Take 3 meds today (${dailyCompletions}/3)'),
                            ),
                          ),
                        Expanded(child: _getPage(_selectedIndex)),
                      ],
                    );
                  },
                ),
              ] else ...[
                _getPage(_selectedIndex),
              ],
              if (_webReminderMessage != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Material(
                    color: Colors.amber.shade200,
                    elevation: 4,
                    child: ListTile(
                      leading: const Icon(Icons.alarm, color: Colors.deepPurple),
                      title: Text(_webReminderMessage!),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _webReminderMessage = null),
                      ),
                    ),
                  ),
                ),
              // Confetti animation overlay
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [Colors.amber, Colors.deepPurple, Colors.green, Colors.orange],
                  numberOfParticles: 30,
                  maxBlastForce: 20,
                  minBlastForce: 8,
                  emissionFrequency: 0.1,
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onBottomNavTap,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
            ],
          ),
        );
      },
    );
  }
}

class _MedicationListPage extends StatelessWidget {
  const _MedicationListPage();

  Future<void> _markAsTaken(BuildContext context, String medId, String medName) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final userDoc = await userDocRef.get();
    final userData = userDoc.data() ?? {};
    // Get or initialize gamification fields
    int dailyCompletions = userData['dailyCompletions'] ?? 0;
    int totalCompletions = userData['totalCompletions'] ?? 0;
    int streak = userData['streak'] ?? 0;
    int coins = userData['coins'] ?? 0;
    String? lastCompletionDateStr = userData['lastCompletionDate'];
    DateTime? lastCompletionDate = lastCompletionDateStr != null ? DateTime.tryParse(lastCompletionDateStr) : null;
    List<dynamic> badges = userData['badges'] ?? [];
    // Update daily completions
    if (lastCompletionDate == null || lastCompletionDate.year != today.year || lastCompletionDate.month != today.month || lastCompletionDate.day != today.day) {
      dailyCompletions = 1;
    } else {
      dailyCompletions += 1;
    }
    // Update streak
    if (lastCompletionDate != null && lastCompletionDate.difference(today).inDays == -1) {
      streak += 1;
    } else if (lastCompletionDate == null || lastCompletionDate.isBefore(today)) {
      streak = 1;
    }
    // Update total completions and coins
    totalCompletions += 1;
    coins += 1; // 1 coin per completion
    // Badge logic
    List<String> newBadges = [];
    if (dailyCompletions >= 3 && !badges.contains('Daily Goal')) {
      badges.add('Daily Goal');
      newBadges.add('Daily Goal');
    }
    if (streak >= 7 && !badges.contains('7-Day Streak')) {
      badges.add('7-Day Streak');
      newBadges.add('7-Day Streak');
    }
    if (totalCompletions >= 100 && !badges.contains('Pill Master')) {
      badges.add('Pill Master');
      newBadges.add('Pill Master');
    }
    // Update user doc
    await userDocRef.set({
      'dailyCompletions': dailyCompletions,
      'totalCompletions': totalCompletions,
      'streak': streak,
      'coins': coins,
      'lastCompletionDate': today.toIso8601String(),
      'badges': badges,
    }, SetOptions(merge: true));
    // Add to medication_history
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('medication_history')
        .add({
      'medicationName': medName,
      'status': 'taken',
      'timestamp': now.toIso8601String(),
    });
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('medications')
        .doc(medId)
        .update({'lastTaken': now.toIso8601String()});
    // Show reward dialog/snackbar
    if (newBadges.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🎉 Badge Unlocked!'),
          content: Text('You unlocked: ${newBadges.join(", ")}'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      (context as Element).findAncestorStateOfType<_HomeScreenState>()?._showConfetti();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$medName marked as taken! +1 coin')), // show coin reward
      );
      (context as Element).findAncestorStateOfType<_HomeScreenState>()?._showConfetti();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Not logged in'));
    }
    return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('medications')
                .snapshots(),
            builder: (context, medSnapshot) {
              if (medSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = medSnapshot.data?.docs ?? [];
              final meds = docs.map((doc) => Medication.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: Colors.deepPurple.shade50,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.alarm, color: Colors.deepPurple, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              meds.isNotEmpty
                                  ? 'Next Medication:  ${meds.first.name} in 1h 20min'
                                  : 'No medications scheduled',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                          MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Medication'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...meds.map((med) => Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.medication, size: 36, color: med.isActive ? Colors.deepPurple : Colors.grey),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          med.name,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          med.dosage,
                                          style: const TextStyle(fontSize: 15, color: Colors.black54),
                                        ),
                                        const Spacer(),
                                        Switch(
                                          value: med.isActive,
                                          onChanged: (val) {
                                            FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(uid)
                                                .collection('medications')
                                                .doc(med.id)
                                                .update({'isActive': val});
                                          },
                                          activeColor: Colors.green,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          med.isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            color: med.isActive ? Colors.green : Colors.grey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      med.frequency,
                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          med.nextDose,
                                          style: const TextStyle(fontSize: 13, color: Colors.deepPurple),
                                        ),
                                        if (!med.isActive)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 8),
                                            child: Icon(Icons.schedule, size: 18, color: Colors.grey),
                                          ),
                                        if (med.isActive && med.frequency.contains('Weekly'))
                                          const Padding(
                                            padding: EdgeInsets.only(left: 8),
                                            child: Icon(Icons.alarm, size: 18, color: Colors.deepPurple),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.check),
                                label: const Text('Mark as Taken'),
                                onPressed: () => _markAsTaken(context, med.id, med.name),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              );
            },
    );
  }
}

class _SettingsModal extends StatefulWidget {
  @override
  State<_SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<_SettingsModal> {
  // Remove _isDark and its usage in initState

  void _toggleTheme() {
    // In a real app, use Provider or similar to update the app theme globally
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Theme toggling not implemented globally.')),
    );
  }

  Future<void> _changePassword() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New Password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Change'),
          ),
        ],
      ),
    );
    if (result != null && result.length >= 6) {
      try {
        await FirebaseAuth.instance.currentUser?.updatePassword(result);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        final uid = user?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).delete();
          final meds = await FirebaseFirestore.instance.collection('users').doc(uid).collection('medications').get();
          for (var doc in meds.docs) {
            await doc.reference.delete();
          }
        }
        await user?.delete();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _helpAndSupport() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@medtrackapp.com',
      query: 'subject=Help & Support for MedTrack',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open email app.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            onTap: _changePassword,
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete Account'),
            onTap: _deleteAccount,
          ),
          ListTile(
            leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            title: const Text('Change Theme'),
            onTap: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: _helpAndSupport,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.more_horiz),
            title: const Text('More features coming soon!'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
} 