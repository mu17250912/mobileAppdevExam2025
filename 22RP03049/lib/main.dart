import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/routes_screen.dart';
import 'screens/buses_screen.dart';
import 'screens/seat_selection_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/role_gate.dart';
import 'screens/admin/manage_routes_screen.dart';
import 'screens/admin/manage_buses_screen.dart';
import 'screens/admin/all_bookings_screen.dart';
import 'screens/admin/analytics_screen.dart';
import 'screens/admin/user_management_screen.dart';
import 'screens/admin/notifications_screen.dart';
import 'screens/user_dashboard_screen.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/profile_screen.dart';
import 'auth_screens.dart' hide ProfileScreen;
// Add SettingsScreen placeholder
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            onTap: () => _showChangePasswordDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Change Email'),
            onTap: () => _showChangeEmailDialog(context),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Enable Notifications'),
            value: _notificationsEnabled,
            onChanged: (val) {
              setState(() => _notificationsEnabled = val);
              // TODO: Save preference to backend or local storage
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.brightness_6),
            title: const Text('Dark Mode'),
            value: isDark,
            onChanged: (val) {
              themeProvider.toggleTheme(val);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: Text(_language),
            onTap: () => _showLanguageDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            onTap: () => _showDeleteAccountDialog(context),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New Password'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null && controller.text.isNotEmpty) {
                await user.updatePassword(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed.')));
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showChangeEmailDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Email'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Email'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null && controller.text.isNotEmpty) {
                await user.updateEmail(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email changed.')));
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Language'),
        children: [
          SimpleDialogOption(
            child: const Text('English'),
            onPressed: () {
              setState(() => _language = 'English');
              Navigator.pop(context);
            },
          ),
          SimpleDialogOption(
            child: const Text('Kinyarwanda'),
            onPressed: () {
              setState(() => _language = 'Kinyarwanda');
              Navigator.pop(context);
            },
          ),
          SimpleDialogOption(
            child: const Text('French'),
            onPressed: () {
              setState(() => _language = 'French');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await user.delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted.')));
                // Optionally navigate to AuthScreen or exit app
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
// import other Firebase services as needed

Future<void> insertSampleData() async {
  final firestore = FirebaseFirestore.instance;

  // Add sample routes
  final routeRef = await firestore.collection('routes').add({
    'from': 'Kigali',
    'to': 'Musanze',
    'distanceKm': 94,
    'estimatedDuration': '2h 30m',
    'active': true,
  });
  final routeId = routeRef.id;

  // Add sample bus
  final busRef = await firestore.collection('buses').add({
    'plateNumber': 'RAB123A',
    'company': 'Volcano Express',
    'routeId': routeId,
    'departureTime': '2024-06-10T08:00:00Z',
    'totalSeats': 30,
    'availableSeats': 29,
    'seats': [
      {'seatNumber': 1, 'booked': false},
      {'seatNumber': 2, 'booked': true, 'userId': 'uid_abc'},
    ],
  });
  final busId = busRef.id;

  // Add sample booking
  await firestore.collection('bookings').add({
    'userId': 'uid_abc',
    'busId': busId,
    'routeId': routeId,
    'seatNumber': 2,
    'bookingTime': FieldValue.serverTimestamp(),
    'status': 'confirmed',
    'paymentStatus': 'pending',
    'ticketCode': 'NYA-20240610-0001',
  });
}

Future<void> addSeatsToBusesWithoutSeats() async {
  final buses = await FirebaseFirestore.instance.collection('buses').get();
  for (final doc in buses.docs) {
    final data = doc.data();
    if (!data.containsKey('seats')) {
      final int totalSeats = data['totalSeats'] ?? 0;
      if (totalSeats > 0) {
        final seats = List.generate(
          totalSeats,
          (index) => {
            'seatNumber': index + 1,
            'booked': false,
          },
        );
        await doc.reference.update({'seats': seats});
        print('Added seats to bus: ${doc.id}');
      }
    }
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  static final List<String> _titles = [
    'Home',
    'Settings',
    'Account',
  ];

  static final List<Widget> _pages = [
    UserDashboardScreen(), // Home
    SettingsScreen(),      // Settings
    ProfileScreen(),       // Account
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.of(context).pop(); // Close drawer if open
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF003366),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.directions_bus, color: Color(0xFFFFD600), size: 48),
                  SizedBox(height: 8),
                  Text('NyabugogoRide', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Smart Bus Booking', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFF003366)),
              title: const Text('Home'),
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Color(0xFF003366)),
              title: const Text('Settings'),
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF003366)),
              title: const Text('Profile'),
              onTap: () => _onItemTapped(2),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.feedback, color: Color(0xFF003366)),
              title: const Text('Feedback'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                );
              },
            ),
            // Notifications with badge
            if (user != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('userId', isEqualTo: user.uid)
                    .where('unread', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  int unreadCount = 0;
                  if (snapshot.hasData) {
                    unreadCount = snapshot.data!.docs.length;
                  }
                  return ListTile(
                    leading: Stack(
                      children: [
                        const Icon(Icons.notifications, color: Color(0xFF003366)),
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
                                unreadCount.toString(),
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
                    title: const Text('Notifications'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                  );
                },
              ),
            if (user == null)
              ListTile(
                leading: const Icon(Icons.notifications, color: Color(0xFF003366)),
                title: const Text('Notifications'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.info, color: Color(0xFF003366)),
              title: const Text('About'),
              onTap: () {
                Navigator.of(context).pop();
                showAboutDialog(
                  context: context,
                  applicationName: 'NyabugogoRide',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.directions_bus, color: Color(0xFFFFD600)),
                  children: [
                    const Text('A smart bus ticket booking app for inter-district public transport in Rwanda.'),
                  ],
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Color(0xFF003366)),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF003366)),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.of(context).pop();
                await FirebaseAuth.instance.signOut();
                // Optionally show a message or navigate to AuthScreen
              },
            ),
            ListTile(
              leading: const Icon(Icons.build, color: Color(0xFF003366)),
              title: const Text('Fix Buses Without Seats'),
              onTap: () async {
                await addSeatsToBusesWithoutSeats();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Seats added to all buses without seats!')),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: _pages[_selectedIndex],
      // bottomNavigationBar: Container(
      //   decoration: BoxDecoration(
      //     color: Color(0xFFBFD4F2), // Light blue
      //     border: Border.all(color: Colors.red, width: 2),
      //   ),
      //   child: BottomNavigationBar(
      //     type: BottomNavigationBarType.fixed,
      //     backgroundColor: Colors.transparent, // Use container's color
      //     elevation: 0,
      //     currentIndex: _selectedIndex,
      //     onTap: _onItemTapped,
      //     selectedItemColor: Colors.blue, // Blue for selected
      //     unselectedItemColor: Colors.black, // Black for unselected
      //     selectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
      //     unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
      //     items: const [
      //       BottomNavigationBarItem(
      //         icon: Icon(Icons.home),
      //         label: 'Home',
      //       ),
      //       BottomNavigationBarItem(
      //         icon: Icon(Icons.search),
      //         label: 'Search',
      //       ),
      //       BottomNavigationBarItem(
      //         icon: Icon(Icons.settings),
      //         label: 'Settings',
      //       ),
      //       BottomNavigationBarItem(
      //         icon: Icon(Icons.account_circle),
      //         label: 'Account',
      //       ),
      //     ],
      //   ),
      // ),
    );
  }
}

// Stub screens for navigation
class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Bookings')),
        body: const Center(child: Text('Please log in to view your bookings.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .orderBy('bookingTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          }
          final bookings = snapshot.data!.docs;
          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFFFD600),
                child: ListTile(
                  leading: const Icon(Icons.confirmation_num, color: Color(0xFF003366), size: 36),
                  title: Text('Ticket: ${booking['ticketCode']}', style: const TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bus: ${booking['busId']}', style: const TextStyle(color: Color(0xFF003366))),
                      Text('Seat: ${booking['seatNumber']}', style: const TextStyle(color: Color(0xFF003366))),
                      Text('Status: ${booking['status']}', style: const TextStyle(color: Color(0xFF003366))),
                      Text('Payment: ${booking['paymentStatus']}', style: const TextStyle(color: Color(0xFF003366))),
                      Text('Booked: ${booking['bookingTime'] != null ? booking['bookingTime'].toDate().toString() : ''}', style: const TextStyle(color: Color(0xFF003366))),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.qr_code, color: Color(0xFF003366)),
                    tooltip: 'Show E-Ticket',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('E-Ticket'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.confirmation_num, size: 48, color: Color(0xFF003366)),
                              const SizedBox(height: 8),
                              Text('Ticket: ${booking['ticketCode']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Bus: ${booking['busId']}'),
                              Text('Seat: ${booking['seatNumber']}'),
                              Text('Status: ${booking['status']}'),
                              Text('Payment: ${booking['paymentStatus']}'),
                              Text('Booked: ${booking['bookingTime'] != null ? booking['bookingTime'].toDate().toString() : ''}'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NyabugogoRide',
      theme: ThemeData(
        primaryColor: const Color(0xFF003366),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFFFFD600), // Accent
          primary: const Color(0xFF003366),
          background: const Color(0xFFF5F6FA),
          error: const Color(0xFFE53935),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF003366),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFFD600),
          foregroundColor: Color(0xFF003366),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF003366),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF222222)),
          bodyMedium: TextStyle(color: Color(0xFF222222)),
          titleLarge: TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.bold),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF003366)),
          ),
          labelStyle: TextStyle(color: Color(0xFF003366)),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
          secondary: const Color(0xFFFFD600),
          primary: const Color(0xFF003366),
        ),
      ),
      themeMode: themeProvider.themeMode,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const RoleGate();
          }
          return const AuthScreen();
        },
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/admin/manage_routes':
            return MaterialPageRoute(builder: (_) => const ManageRoutesScreen());
          case '/admin/manage_buses':
            return MaterialPageRoute(builder: (_) => const ManageBusesScreen());
          case '/admin/all_bookings':
            return MaterialPageRoute(builder: (_) => const AllBookingsScreen());
          case '/admin/analytics':
            return MaterialPageRoute(builder: (_) => const AnalyticsScreen());
          case '/admin/user_management':
            return MaterialPageRoute(builder: (_) => const UserManagementScreen());
          case '/admin/notifications':
            return MaterialPageRoute(builder: (_) => const NotificationsScreen());
        }
        return null;
      },
    );
  }
}

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  Future<Map<String, int>> _fetchDashboardStats() async {
    final bookingsSnap = await FirebaseFirestore.instance.collection('bookings').get();
    final usersSnap = await FirebaseFirestore.instance.collection('users').get();
    int totalBookings = bookingsSnap.size;
    int totalPaid = bookingsSnap.docs.where((doc) => doc['paymentStatus'] == 'paid').length;
    int totalUsers = usersSnap.size;
    return {
      'totalBookings': totalBookings,
      'totalPaid': totalPaid,
      'totalUsers': totalUsers,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FutureBuilder<Map<String, int>>(
          future: _fetchDashboardStats(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              );
            }
            final stats = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _DashboardCard(
                    icon: Icons.people,
                    label: 'Users',
                    value: stats['totalUsers'].toString(),
                    color: const Color(0xFF003366),
                  ),
                  _DashboardCard(
                    icon: Icons.confirmation_num,
                    label: 'Bookings',
                    value: stats['totalBookings'].toString(),
                    color: const Color(0xFFFFD600),
                  ),
                  _DashboardCard(
                    icon: Icons.payment,
                    label: 'Paid',
                    value: stats['totalPaid'].toString(),
                    color: Colors.green,
                  ),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('routes').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No routes available.'));
              }
              final routes = snapshot.data!.docs;
              return ListView.builder(
                itemCount: routes.length,
                itemBuilder: (context, index) {
                  final route = routes[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: const Color(0xFFF5F6FA),
                    child: ListTile(
                      leading: const Icon(Icons.directions_bus, color: Color(0xFF003366), size: 36),
                      title: Text('${route['from']} → ${route['to']}', style: const TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.bold)),
                      subtitle: Text('Distance: ${route['distanceKm']} km, Duration: ${route['estimatedDuration']}', style: const TextStyle(color: Color(0xFF003366))),
                      trailing: ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward, color: Color(0xFF003366)),
                        label: const Text('View Buses', style: TextStyle(color: Color(0xFF003366))),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD600),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BusesScreen(routeId: route.id, routeName: '${route['from']} → ${route['to']}'),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _DashboardCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}

// Sample professional dashboard card widget
class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const DashboardCard({required this.icon, required this.label, required this.value, required this.color, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
            Text(label, style: TextStyle(fontSize: 14, color: Color(0xFF003366))),
          ],
        ),
      ),
    );
  }
}

// Add SearchScreen placeholder
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Search for routes, buses, or bookings here.', style: TextStyle(fontSize: 18)));
  }
}
