import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/profile_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/add_skill_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/requested_skills_screen.dart';
import 'screens/session_requests_screen.dart';
import 'screens/chat_list_screen.dart';
import 'services/notification_service.dart';
import 'services/chat_service.dart';
import 'services/navigation_service.dart';

Future<void> setupFCM() async {
  try {
    bool success = await NotificationService.initializeFCM();
    if (success) {
      debugPrint('FCM initialized successfully');
    } else {
      debugPrint('FCM initialization failed or permission denied');
    }
  } catch (e) {
    debugPrint('Error setting up FCM: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('GLOBAL FLUTTER ERROR: ${details.exception}');
    debugPrintStack(stackTrace: details.stack);
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const SkillSwapApp());
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Failed to initialize Firebase: $e'),
          ),
        ),
      ),
    );
  }
}

class SkillSwapApp extends StatefulWidget {
  const SkillSwapApp({super.key});

  @override
  State<SkillSwapApp> createState() => _SkillSwapAppState();
}

class _SkillSwapAppState extends State<SkillSwapApp> {
  int _initialTabIndex = 0;
  bool _loadingTabIndex = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user != null) {
          await setupFCM();
          final idx = await NavigationService().fetchLastTabIndex();
          if (mounted) {
            setState(() {
              _initialTabIndex = idx ?? 0;
              _loadingTabIndex = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _initialTabIndex = 0;
              _loadingTabIndex = false;
            });
          }
        }
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Received message: ${message.notification?.title}');
      }).onError((error) {
        debugPrint('Message error: $error');
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Message opened: ${message.data}');
      }).onError((error) {
        debugPrint('Message opened error: $error');
      });
    } catch (e) {
      debugPrint('App initialization error: $e');
      if (mounted) {
        setState(() {
          _loadingTabIndex = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingTabIndex) {
      return MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
        },
      );
    }

    return MaterialApp(
      title: 'SkillSwap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue[800],
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
          bodySmall: TextStyle(fontSize: 12),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) {
          debugPrint('Building /home route: MainScaffold');
          return MainScaffold(
            initialTabIndex: _initialTabIndex.clamp(0, 5),
          );
        },
        '/subscription': (context) => const SubscriptionScreen(),
        '/requested-skills': (context) => const RequestedSkillsScreen(),
        '/session-requests': (context) => const SessionRequestsScreen(),
      },
    );
  }
}

class MainScaffold extends StatefulWidget {
  final int initialTabIndex;

  const MainScaffold({super.key, required this.initialTabIndex});

  @override
  MainScaffoldState createState() => MainScaffoldState();
}

class MainScaffoldState extends State<MainScaffold> {
  late int currentIndex;
  int _unreadNotifications = 0;
  int _unreadChats = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const AlertsScreen(),
    const ChatListScreen(),
    const ProfileScreen(),
    const AddSkillScreen(),
  ];

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialTabIndex.clamp(0, _screens.length - 1);
    _fetchUnreadNotifications();
    _fetchUnreadChats();
  }

  Future<void> _fetchUnreadNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      if (mounted) {
        setState(() {
          _unreadNotifications = snapshot.docs.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  Future<void> _fetchUnreadChats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      ChatService.getUnreadChatCount().listen((count) {
        if (mounted) {
          setState(() {
            _unreadChats = count;
          });
        }
      });
    } catch (e) {
      debugPrint('Error fetching chats: $e');
    }
  }

  void _onTabTapped(int index) {
    if (index == currentIndex) return;

    setState(() {
      currentIndex = index;
      if (index == 2) _fetchUnreadNotifications();
      if (index == 3) _fetchUnreadChats();
    });
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Search';
      case 2:
        return 'Alerts';
      case 3:
        return 'Chat';
      case 4:
        return 'Profile';
      case 5:
        return 'Add Skills';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeIndex = currentIndex.clamp(0, _screens.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitleForIndex(safeIndex)),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: IndexedStack(
        index: safeIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: safeIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: 0,
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
                        _unreadNotifications > 99
                            ? '99+'
                            : '$_unreadNotifications',
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
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.chat),
                if (_unreadChats > 0)
                  Positioned(
                    right: 0,
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
                        _unreadChats > 99 ? '99+' : '$_unreadChats',
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
            label: 'Chat',
          ),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline), label: 'Add Skills'),
        ],
      ),
    );
  }
}
