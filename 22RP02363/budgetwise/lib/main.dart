import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'add_expense_page.dart';
import 'budget_page.dart';
import 'notifications_page.dart';
import 'premium_page.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'splash_page.dart';
import 'login_page.dart';
import 'shopping_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';
// import 'package:firebase_analytics/observer.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';

void main() async {
  print('=== APP STARTED MAIN ===');
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    if (e.toString().contains('A Firebase App named "[DEFAULT]" already exists')) {
      print('Duplicate Firebase app error ignored.');
    } else {
      rethrow;
    }
  }
  // Only initialize MobileAds on Android/iOS, not web
  // Temporarily disabled to prevent crash in debug mode
  // if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
  //   await MobileAds.instance.initialize();
  // }
  runZonedGuarded(() {
    runApp(const MyApp());
  }, (error, stackTrace) {
    print('Caught error: ' + error.toString());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    // analytics.logEvent(name: 'app_opened');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BudgetWise',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      // navigatorObservers: [FirebaseAnalyticsObserver(analytics: analytics)],
      home: const SplashPage(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({Key? key}) : super(key: key);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    BudgetPage(),
    NotificationsPage(),
    PremiumPage(),
    ShoppingPage(),
  ];

  final List<String> _tabNames = [
    'Dashboard',
    'Budget',
    'Notifications',
    'Premium',
    'Shopping',
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Top green header
          Container(
            width: double.infinity,
            color: const Color(0xFF4CAF50),
            padding: const EdgeInsets.only(top: 32, bottom: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.savings, color: Colors.orange, size: 36, semanticLabel: 'Savings Icon'),
                    const SizedBox(width: 12),
                    Text(
                      'BudgetWise',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    if (user != null)
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('notifications')
                            .where('userId', isEqualTo: user.uid)
                            .where('read', isEqualTo: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          int count = 0;
                          if (snapshot.hasData) {
                            count = snapshot.data!.docs.length;
                          }
                          return Stack(
                            alignment: Alignment.topRight,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications, color: Colors.white, size: 32),
                                onPressed: () => setState(() => _selectedIndex = 2),
                              ),
                              if (count > 0)
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 20,
                                    ),
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Smart Money Management Made Simple',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 18),
                // Navigation bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_tabNames.length, (index) {
                      final isSelected = _selectedIndex == index;
                      // Responsive: adjust font size and padding for small screens
                      final screenWidth = MediaQuery.of(context).size.width;
                      final isSmallScreen = screenWidth < 400;
                      final buttonFontSize = isSmallScreen ? 18.0 : 28.0 * MediaQuery.textScaleFactorOf(context);
                      final buttonPadding = isSmallScreen ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8) : const EdgeInsets.symmetric(horizontal: 22, vertical: 8);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: isSelected ? Colors.green[700] : Colors.white,
                            foregroundColor: isSelected ? Colors.white : Colors.green[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(color: Colors.green.shade700),
                            ),
                            padding: buttonPadding,
                            elevation: isSelected ? 4 : 0,
                            shadowColor: isSelected ? Colors.green : null,
                          ),
                          onPressed: () => setState(() => _selectedIndex = index),
                          child: Text(
                            _tabNames[index],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: buttonFontSize,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
