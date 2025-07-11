import 'package:flutter/material.dart';
import 'auth/auth_service.dart';
import 'auth/auth_screen.dart';
import 'motivation/notification_service.dart';
import 'motivation/quote_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ads/ad_service.dart';
import 'goals/goal_screen.dart';
import 'analytics/analytics_screen.dart';
import 'profile/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoalTrackerApp extends StatelessWidget {
  const GoalTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GoalTracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const RootScreen(),
      builder: (context, child) {
        NotificationService.initialize(context!);
        // Show a motivational notification on app launch
        final quote = (List.of(QuoteWidget.quotes)..shuffle()).first;
        NotificationService.showMotivationNotification(quote);
        return child!;
      },
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  @override
  void initState() {
    super.initState();
    _handleAppLaunchAd();
    NotificationService.initialize(context);
    // Show a motivational notification on app launch
    final quote = (List.of(QuoteWidget.quotes)..shuffle()).first;
    NotificationService.showMotivationNotification(quote);
  }

  Future<void> _handleAppLaunchAd() async {
    final prefs = await SharedPreferences.getInstance();
    int launches = prefs.getInt('launches') ?? 0;
    launches++;
    await prefs.setInt('launches', launches);
    if (launches % 10 == 0) {
      AdService.loadInterstitialAd(() {
        AdService.showInterstitialAd();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print(
          '[RootScreen] Auth state: hasData=${snapshot.hasData}, user=${snapshot.data}',
        );
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const MainNavScreen();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  bool _cloudConnected = false;

  @override
  void initState() {
    super.initState();
    _checkFirestoreConnection();
  }

  Future<void> _checkFirestoreConnection() async {
    try {
      // Simulate cloud connection check
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _cloudConnected = true;
      });
    } catch (e) {
      setState(() {
        _cloudConnected = false;
      });
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_cloudConnected)
              const Text(
                'Connected to cloud',
                style: TextStyle(color: Colors.green),
              ),
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;
  final _screens = [_GoalWithQuoteScreen(), AnalyticsScreen(), ProfileScreen()];
  String _usernameInitial = '?';

  @override
  void initState() {
    super.initState();
    _fetchUsernameInitial();
  }

  Future<void> _fetchUsernameInitial() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final username = doc.data()?['username'] ?? '';
      setState(() {
        _usernameInitial = username.isNotEmpty
            ? username[0].toUpperCase()
            : '?';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GoalTracker'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              icon: CircleAvatar(
                child: Text(
                  _usernameInitial,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: const [
                      Icon(Icons.person),
                      SizedBox(width: 8),
                      Text('Profile'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: const [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'profile') {
                  setState(() => _selectedIndex = 2);
                } else if (value == 'logout') {
                  await FirebaseAuth.instance.signOut();
                }
              },
            ),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.flag), label: 'Goals'),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _GoalWithQuoteScreen extends StatelessWidget {
  const _GoalWithQuoteScreen();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        QuoteWidget(),
        Expanded(child: GoalScreen()),
      ],
    );
  }
}
