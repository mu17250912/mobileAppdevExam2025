import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_match_management.dart';
import 'user_home.dart';
import 'admin_bet_approval.dart';
import 'admin_stats_dashboard.dart';
import 'admin_settings_help.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'admin_country_team_management.dart';
import 'admin_subscription_dashboard.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'betslip_provider.dart';
import 'auth_screen.dart';
import 'splash_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'notifications_service.dart';
import 'admin_notification_settings.dart';

Future<void> logAdminEvent(String eventName, Map<String, dynamic> params) async {
  final user = FirebaseAuth.instance.currentUser;
  await FirebaseFirestore.instance.collection('admin_events').add({
    'event': eventName,
    'params': params,
    'timestamp': FieldValue.serverTimestamp(),
    'userId': user?.uid,
    'userEmail': user?.email,
  });
}
// Example usage:
// await logAdminEvent('login', {});
// await logAdminEvent('bet_placed', {'amount': 100, 'match_id': 'abc123'});
// await logAdminEvent('match_viewed', {'match_id': 'abc123'});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (kIsWeb) {
    // ignore: deprecated_member_use
    await FirebaseFirestore.instance.enablePersistence();
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BetSlipProvider()),
      ],
      child: const BetNovaApp(),
    ),
  );
}

class BetNovaApp extends StatelessWidget {
  const BetNovaApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BetNova',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      navigatorObservers: [observer],
      home: const SplashScreenWrapper(),
    );
  }
}

// Example: Log a custom event somewhere in your app
// FirebaseAnalytics.instance.logEvent(
//   name: 'bet_placed',
//   parameters: {'amount': 100, 'user_id': 'abc123'},
// );

class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({Key? key}) : super(key: key);

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RootScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Auth error: \\${snapshot.error}')),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return const AuthScreen();
        }
        // User is logged in, check role
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.hasError) {
              return Scaffold(
                body: Center(child: Text('User data error: \\${userSnapshot.error}')),
              );
            }
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              // Sign out and show error on AuthScreen
              FirebaseAuth.instance.signOut();
              return const AuthScreen();
            }
            final role = userSnapshot.data!.get('role');
            if (role == 'admin') {
              return const AdminHome();
            } else {
              return const UserHomeScreen();
            }
          },
        );
      },
    );
  }
}

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;
  // Remove _showFooter and _scrollController from state

  final List<Widget> _pages = [
    const _AdminDashboard(),
    const AdminMatchManagement(),
    const AdminBetsOverviewPage(),
    const AdminStatsDashboard(),
    const AdminSettingsHelp(),
  ];

  // Remove _onScroll, NotificationListener, and all AppFooter usage

  @override
  void initState() {
    super.initState();
    // Remove _onScroll, NotificationListener, and all AppFooter usage
  }

  // Remove _onScroll, NotificationListener, and all AppFooter usage

  @override
  void dispose() {
    // Remove _onScroll, NotificationListener, and all AppFooter usage
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove _showFooter and _scrollController from state
      body: _pages[_selectedIndex],
      // Remove _showFooter and _scrollController from state
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.lime,
        unselectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Bets'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            const Text('BetNove', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
                              icon: StreamBuilder<int>(
                  stream: NotificationsService.getUnreadNotificationCount(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Icon(Icons.notifications, color: Colors.lime);
                    }
                    if (snapshot.hasError) {
                      return const Icon(Icons.notifications, color: Colors.lime);
                    }
                    final count = snapshot.data ?? 0;
                    return badges.Badge(
                      badgeContent: count > 0 ? Text(count.toString(), style: const TextStyle(color: Colors.white)) : null,
                      child: const Icon(Icons.notifications, color: Colors.lime),
                    );
                  },
                ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminNotificationsPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
        elevation: 0,
      ),
      backgroundColor: Colors.grey[900],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Welcome back, Admin!',
                  style: TextStyle(
                    color: Colors.lime,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Quick Stats (realtime)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _RealtimeStatCard(
                      label: 'Total Users',
                      icon: Icons.people,
                      color: Colors.blue,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersPage())),
                      stream: FirebaseFirestore.instance.collection('users').snapshots(),
                      countExtractor: (snap) => snap.docs.length,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RealtimeStatCard(
                      label: 'Active Bets',
                      icon: Icons.sports_soccer,
                      color: Colors.green,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminActiveBetsPage())),
                      stream: FirebaseFirestore.instance.collection('bets').where('status', whereIn: ['open', 'approved']).snapshots(),
                      countExtractor: (snap) => snap.docs.length,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _RealtimeStatCard(
                      label: 'Pending',
                      icon: Icons.pending,
                      color: Colors.red,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPendingBetsPage())),
                      stream: FirebaseFirestore.instance.collection('bets').where('status', isEqualTo: 'pending').snapshots(),
                      countExtractor: (snap) => snap.docs.length,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _adminActionCard(
                context,
                'Manage Matches',
                'Create and edit match schedules',
                Icons.sports_soccer,
                Colors.blue,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminMatchManagement()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _adminActionCard(
                context,
                'Approve Bets',
                'Review and approve user bets',
                Icons.check_circle,
                Colors.green,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminBetsOverviewPage()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _adminActionCard(
                context,
                'Analytics Dashboard',
                'View detailed statistics and reports',
                Icons.analytics,
                Colors.purple,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminStatsDashboard()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _adminActionCard(
                context,
                'Settings & Help',
                'Configure system settings',
                Icons.settings,
                Colors.grey,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminSettingsHelp()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _adminActionCard(
                context,
                'Manage Countries & Teams',
                'Add, edit, and manage countries and teams',
                Icons.flag,
                Colors.deepPurple,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminCountryTeamManagement()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _adminActionCard(
                context,
                'Subscription Dashboard',
                'Manage premium subscriptions and revenue',
                Icons.star,
                Colors.amber,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminSubscriptionDashboard()),
                  );
                },
              ),
              const SizedBox(height: 30),
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('admin_activities')
                      .orderBy('timestamp', descending: true)
                      .limit(10)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(child: Text('No recent activity.', style: TextStyle(color: Colors.white70)));
                    }
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final id = docs[index].id;
                        final type = data['type'] ?? 'info';
                        final user = data['userName'] ?? 'User';
                        final action = data['action'] ?? '';
                        final ts = data['timestamp'] as Timestamp?;
                        final time = ts?.toDate();
                        final icon = _getIconForType(type);
                        final color = _getColorForType(type);
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.15),
                              child: Icon(icon, color: color),
                            ),
                            title: Text('$user: $action', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                            subtitle: time != null ? Text(_formatTime(time), style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'view') {
                                  // TODO: Implement view details dialog
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('View details coming soon...')));
                                } else if (value == 'delete') {
                                  await FirebaseFirestore.instance.collection('admin_activities').doc(id).delete();
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'view', child: ListTile(leading: Icon(Icons.visibility), title: Text('View'))),
                                const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete'))),
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
        ),
      ),
    );
  }

  Widget _adminStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.black26, size: 18),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'deposit':
        return Icons.arrow_downward;
      case 'withdraw':
        return Icons.arrow_upward;
      case 'bet':
        return Icons.sports_soccer;
      case 'profile':
        return Icons.person;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'deposit':
        return Colors.green;
      case 'withdraw':
        return Colors.red;
      case 'bet':
        return Colors.blue;
      case 'profile':
        return Colors.orange;
      default:
        return Colors.deepPurple;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}  ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _RealtimeStatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Stream<QuerySnapshot> stream;
  final num Function(QuerySnapshot) countExtractor;
  final bool isMoney;

  const _RealtimeStatCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.stream,
    required this.countExtractor,
    this.isMoney = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 32),
                    const SizedBox(height: 8),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 4),
                    Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                  ],
                );
              }
              final num value = countExtractor(snapshot.data!);
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    isMoney ? '\$${value.toStringAsFixed(2)}' : value.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class AdminNotificationsPage extends StatelessWidget {
  const AdminNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(child: Text('No notifications implemented.')),
    );
  }
}

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Users'), backgroundColor: Colors.deepPurple),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('joinedAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final userId = docs[index].id;
              final name = data['name'] ?? 'No Name';
              final email = data['email'] ?? '';
              final role = data['role'] ?? 'user';
              final blocked = data['blocked'] == true;
              final joinedAt = data['joinedAt'] is Timestamp ? (data['joinedAt'] as Timestamp).toDate() : null;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: blocked ? Colors.red.shade100 : Colors.blue.shade100,
                    child: Icon(blocked ? Icons.block : Icons.person, color: blocked ? Colors.red : Colors.blue),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(email, style: const TextStyle(fontSize: 13)),
                      Text('Role: $role', style: const TextStyle(fontSize: 12, color: Colors.deepPurple)),
                      if (joinedAt != null)
                        Text('Joined: ${joinedAt.year}-${joinedAt.month.toString().padLeft(2, '0')}-${joinedAt.day.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(blocked ? 'Status: Blocked' : 'Status: Active', style: TextStyle(fontSize: 12, color: blocked ? Colors.red : Colors.green)),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'block') {
                        await FirebaseFirestore.instance.collection('users').doc(userId).update({'blocked': !blocked});
                      } else if (value == 'delete') {
                        await FirebaseFirestore.instance.collection('users').doc(userId).delete();
                      } else if (value == 'edit') {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit user coming soon...')));
                      } else if (value == 'view') {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('View user coming soon...')));
                      } else if (value == 'reset_pin') {
                        _showResetPinDialog(context, userId, name);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'view', child: ListTile(leading: Icon(Icons.visibility), title: Text('View'))),
                      const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
                      PopupMenuItem(
                        value: 'block',
                        child: ListTile(
                          leading: Icon(blocked ? Icons.lock_open : Icons.block, color: blocked ? Colors.green : Colors.red),
                          title: Text(blocked ? 'Unblock' : 'Block'),
                        ),
                      ),
                      const PopupMenuItem(value: 'reset_pin', child: ListTile(leading: Icon(Icons.lock_reset, color: Colors.orange), title: Text('Reset PIN'))),
                      const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete'))),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showResetPinDialog(BuildContext context, String userId, String userName) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset PIN for $userName'),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'New PIN',
            hintText: 'Enter 4-digit PIN',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pin = pinController.text.trim();
              if (pin.length != 4 || !RegExp(r'^[0-9]+$').hasMatch(pin)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN must be 4 digits')));
                return;
              }
              await FirebaseFirestore.instance.collection('users').doc(userId).update({'pin': pin});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN reset successfully!')));
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class AdminActiveBetsPage extends StatelessWidget {
  const AdminActiveBetsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Bets'), backgroundColor: Colors.deepPurple),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bets').where('status', whereIn: ['open', 'approved']).orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No active bets found.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final betId = docs[index].id;
              final userId = data['userId'] ?? '';
              final matchId = data['matchId'] ?? '';
              final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
              final odds = data['odds'] ?? '';
              final status = data['status'] ?? '';
              final timestamp = data['timestamp'] is Timestamp ? (data['timestamp'] as Timestamp).toDate() : null;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: const Icon(Icons.sports_soccer, color: Colors.green),
                  ),
                  title: Text('User: $userId', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Match: $matchId', style: const TextStyle(fontSize: 13)),
                      Text('Amount: 4${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
                      Text('Odds: $odds', style: const TextStyle(fontSize: 13)),
                      Text('Status: $status', style: const TextStyle(fontSize: 13, color: Colors.deepPurple)),
                      if (timestamp != null)
                        Text('Time: ${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'approve') {
                        await FirebaseFirestore.instance.collection('bets').doc(betId).update({'status': 'approved'});
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bet approved!')));
                      } else if (value == 'reject') {
                        await FirebaseFirestore.instance.collection('bets').doc(betId).update({'status': 'rejected'});
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bet rejected!')));
                      } else if (value == 'delete') {
                        await FirebaseFirestore.instance.collection('bets').doc(betId).delete();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bet deleted!')));
                      } else if (value == 'view') {
                        // TODO: Implement view bet details
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('View bet coming soon...')));
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'view', child: ListTile(leading: Icon(Icons.visibility), title: Text('View'))),
                      if (status == 'open')
                        const PopupMenuItem(value: 'approve', child: ListTile(leading: Icon(Icons.check, color: Colors.green), title: Text('Approve'))),
                      if (status == 'open' || status == 'approved')
                        const PopupMenuItem(value: 'reject', child: ListTile(leading: Icon(Icons.close, color: Colors.red), title: Text('Reject'))),
                      const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete'))),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminPendingBetsPage extends StatelessWidget {
  const AdminPendingBetsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Bets'), backgroundColor: Colors.deepPurple),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bets').where('status', isEqualTo: 'pending').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No pending bets found.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final betId = docs[index].id;
              final userId = data['userId'] ?? '';
              final matchId = data['matchId'] ?? '';
              final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
              final odds = data['odds'] ?? '';
              final timestamp = data['timestamp'] is Timestamp ? (data['timestamp'] as Timestamp).toDate() : null;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade100,
                    child: const Icon(Icons.pending, color: Colors.red),
                  ),
                  title: Text('User: $userId', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Match: $matchId', style: const TextStyle(fontSize: 13)),
                      Text('Amount: 4${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
                      Text('Odds: $odds', style: const TextStyle(fontSize: 13)),
                      if (timestamp != null)
                        Text('Time: ${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'approve') {
                        await FirebaseFirestore.instance.collection('bets').doc(betId).update({'status': 'approved'});
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bet approved!')));
                      } else if (value == 'reject') {
                        await FirebaseFirestore.instance.collection('bets').doc(betId).update({'status': 'rejected'});
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bet rejected!')));
                      } else if (value == 'delete') {
                        await FirebaseFirestore.instance.collection('bets').doc(betId).delete();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bet deleted!')));
                      } else if (value == 'view') {
                        // TODO: Implement view bet details
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('View bet coming soon...')));
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'view', child: ListTile(leading: Icon(Icons.visibility), title: Text('View'))),
                      const PopupMenuItem(value: 'approve', child: ListTile(leading: Icon(Icons.check, color: Colors.green), title: Text('Approve'))),
                      const PopupMenuItem(value: 'reject', child: ListTile(leading: Icon(Icons.close, color: Colors.red), title: Text('Reject'))),
                      const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete'))),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
