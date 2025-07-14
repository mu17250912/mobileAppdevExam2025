import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/subscription_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'l10n/app_localizations.dart';

// Add RestartWidget for full app rebuild
class RestartWidget extends StatefulWidget {
  final Widget child;
  const RestartWidget({Key? key, required this.child}) : super(key: key);

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?.restartApp();
  }

  @override
  _RestartWidgetState createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: key,
      child: widget.child,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization failed: $e');
  }
  
  try {
    // Initialize Hive without path_provider dependency
    await Hive.initFlutter();
    await Hive.openBox('settings');
  } catch (e) {
    print('Hive initialization failed: $e');
    // Continue without Hive if it fails
  }
  
  try {
    await NotificationService().initialize();
  } catch (e) {
    print('Notification service initialization failed: $e');
  }
  
  runApp(RestartWidget(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  String? _username;
  bool _isPremium = false;
  final AuthService _authService = AuthService();
  bool _initialized = false;
  Key _materialAppKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    await _loadLocale();
    await _loadPremium();
    setState(() {
      _initialized = true;
    });
    _authService.authStateChanges.listen((User? user) {
      if (user != null) {
        _loadUserData(user.uid);
        // Navigate to dashboard after login
        if (navigatorKey.currentState != null) {
          // Prevent duplicate pushes if already on dashboard
          bool isOnDashboard = false;
          navigatorKey.currentState!.popUntil((route) {
            if (route.settings.name == '/dashboard') isOnDashboard = true;
            return true;
          });
          if (!isOnDashboard) {
            navigatorKey.currentState!.pushNamedAndRemoveUntil(
              '/dashboard',
              (route) => false,
            );
          }
        }
      } else {
        setState(() {
          _username = null;
          _isPremium = false;
        });
      }
    });
  }

  Future<void> _loadLocale() async {
    try {
      if (Hive.isBoxOpen('settings')) {
        final box = Hive.box('settings');
        final langCode = box.get('language_code');
        setState(() {
          _locale = langCode != null ? Locale(langCode) : null;
        });
      } else {
        setState(() {
          _locale = null;
        });
      }
    } catch (e) {
      setState(() {
        _locale = null;
      });
    }
  }

  Future<void> _loadPremium() async {
    try {
      if (Hive.isBoxOpen('settings')) {
        final box = Hive.box('settings');
        final premium = box.get('premium', defaultValue: false);
        setState(() {
          _isPremium = premium;
        });
      } else {
        setState(() {
          _isPremium = false;
        });
      }
    } catch (e) {
      setState(() {
        _isPremium = false;
      });
    }
  }

  void _loadUserData(String uid) async {
    try {
      final userData = await _authService.getUserData(uid);
      if (userData != null) {
        setState(() {
          _username = userData['username'] ?? 'User';
          _isPremium = userData['isPremium'] ?? false;
        });
      }
    } catch (e) {
      // Optionally handle error
    }
  }

  void _setLocale(Locale locale) async {
    try {
      if (Hive.isBoxOpen('settings')) {
        final box = Hive.box('settings');
        await box.put('language_code', locale.languageCode);
      }
      setState(() {
        _locale = locale;
      });
      // Restart the app to apply the new locale everywhere
      RestartWidget.restartApp(navigatorKey.currentContext!);
      // Add a short delay to ensure the context is rebuilt
      Future.delayed(const Duration(milliseconds: 200), () {
        Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => AuthScreen(
              onAuthenticated: _onAuthenticated,
              authService: _authService,
              initialTabIndex: 1,
            ),
          ),
          (route) => false,
        );
      });
    } catch (e) {
      setState(() {
        _locale = locale;
      });
    }
  }

  void _onAuthenticated(String username) {
    setState(() {
      _username = username;
    });
  }

  void _handleLogout() async {
    await _authService.logoutUser();
    setState(() {
      _username = null;
      _isPremium = false;
    });
    // Navigate to AuthScreen with register tab after logout
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => AuthScreen(
            onAuthenticated: _onAuthenticated,
            authService: _authService,
            initialTabIndex: 1, // 1 = Register tab
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: _materialAppKey,
      title: 'BizTrackr',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFD600)),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('fr', ''),
        Locale('rw', ''),
      ],
      locale: _locale,
      routes: {
        '/dashboard': (context) => MainScaffold(
          child: DashboardScreen(
            username: _username ?? 'User',
            isPremium: _isPremium,
            onUpgrade: () => setState(() => _isPremium = true),
            onLogout: _handleLogout
          ),
          isPremium: _isPremium,
          onUpgrade: () => setState(() => _isPremium = true)
        ),
        '/inventory': (context) => MainScaffold(
          child: InventoryScreen(),
          isPremium: _isPremium,
          onUpgrade: () => setState(() => _isPremium = true)
        ),
        '/sales': (context) => MainScaffold(
          child: SalesScreen(),
          isPremium: _isPremium,
          onUpgrade: () => setState(() => _isPremium = true)
        ),
        '/customers': (context) => MainScaffold(
          child: CustomersScreen(),
          isPremium: _isPremium,
          onUpgrade: () => setState(() => _isPremium = true)
        ),
        '/reports': (context) => MainScaffold(
          child: ReportsScreen(
            onUpgrade: () => setState(() => _isPremium = true)
          ),
          isPremium: _isPremium,
          onUpgrade: () => setState(() => _isPremium = true)
        ),
        '/settings': (context) => MainScaffold(
          child: SettingsScreen(
            isPremium: _isPremium,
            onUpgrade: () => setState(() => _isPremium = true),
            onLogout: _handleLogout,
            onLanguageChanged: _setLocale,
            currentLocale: _locale,
          ),
          isPremium: _isPremium,
          onUpgrade: () => setState(() => _isPremium = true)
        ),
        '/about': (context) => MainScaffold(
          child: AboutScreen(),
          isPremium: _isPremium,
          onUpgrade: () => setState(() => _isPremium = true)
        ),
        '/payment': (context) => PaymentScreen(
          onPaymentSuccess: () => setState(() => _isPremium = true),
        ),
        '/ai-assistant': (context) => AiAssistantScreen(),
        '/subscription': (context) => SubscriptionScreen(),
      },
      home: !_initialized
          ? const SplashScreen()
          : WelcomeScreen(onLanguageSelected: _setLocale),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  final void Function(Locale) onLanguageSelected;
  const WelcomeScreen({super.key, required this.onLanguageSelected});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  Locale? _selectedLocale;

  @override
  Widget build(BuildContext context) {
    final Color mainColor = const Color(0xFFFFD600); // Lightning yellow
    return Scaffold(
      backgroundColor: mainColor.withOpacity(0.1),
      body: Center(
        child: Card(
          elevation: 8,
          margin: const EdgeInsets.symmetric(horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.store, size: 64, color: mainColor),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.appTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: mainColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.welcomeMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.language),
                      onPressed: () => setState(() => _selectedLocale = const Locale('en')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedLocale?.languageCode == 'en' ? mainColor : Colors.grey[200],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      label: Text(AppLocalizations.of(context)!.english),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.language),
                      onPressed: () => setState(() => _selectedLocale = const Locale('fr')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedLocale?.languageCode == 'fr' ? Colors.orange : Colors.grey[200],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      label: Text(AppLocalizations.of(context)!.french),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedLocale == null
                        ? null
                        : () => widget.onLanguageSelected(_selectedLocale!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  final void Function(String username) onAuthenticated;
  final AuthService authService;
  final int initialTabIndex;
  const AuthScreen({super.key, required this.onAuthenticated, required this.authService, this.initialTabIndex = 0});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerUsernameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerUsernameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_registerEmailController.text.isEmpty ||
        _registerPasswordController.text.isEmpty ||
        _registerUsernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseFillAllFields)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.authService.registerUser(
        _registerEmailController.text.trim(),
        _registerPasswordController.text,
        _registerUsernameController.text.trim(),
      );
      widget.onAuthenticated(_registerUsernameController.text.trim());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.registrationFailed(e.toString()))),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _login() async {
    if (_loginEmailController.text.isEmpty || _loginPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseFillAllFields)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.authService.loginUser(
        _loginEmailController.text.trim(),
        _loginPasswordController.text,
      );
      // User data will be loaded via auth state listener
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.loginFailed(e.toString()))),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = Colors.orange.shade400;
    final Color mainColor = const Color(0xFFFFD600); // Lightning yellow
    final Color bgColor = mainColor.withOpacity(0.1);
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.welcome),
        backgroundColor: mainColor,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButtonHideUnderline(
              child: Builder(
                builder: (context) {
                  final currentLang = Localizations.localeOf(context).languageCode;
                  final dropdownValue = currentLang == 'fr' ? const Locale('fr') : const Locale('en');
                  return DropdownButton<Locale>(
                    value: dropdownValue,
                    icon: const Icon(Icons.language, color: Colors.black),
                    items: const [
                      DropdownMenuItem(
                        value: Locale('en'),
                        child: Text('English'),
                      ),
                      DropdownMenuItem(
                        value: Locale('fr'),
                        child: Text('Français'),
                      ),
                    ],
                    onChanged: (locale) {
                      if (locale != null) {
                        final state = context.findRootAncestorStateOfType<_MyAppState>();
                        state?._setLocale(locale);
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accent,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.login),
            Tab(text: AppLocalizations.of(context)!.register),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Login Tab
          SingleChildScrollView(
            physics: ClampingScrollPhysics(),
            child: Card(
              elevation: 8,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 400,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_open, size: 64, color: mainColor),
                      const SizedBox(height: 16),
                      Text(AppLocalizations.of(context)!.login, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: mainColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _loginEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.email,
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _loginPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.password,
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : Text(AppLocalizations.of(context)!.login),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Register Tab
          SingleChildScrollView(
            physics: ClampingScrollPhysics(),
            child: Card(
              elevation: 8,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 400,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add, size: 64, color: mainColor),
                      const SizedBox(height: 16),
                      Text(AppLocalizations.of(context)!.register, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: mainColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _registerUsernameController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.username,
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _registerEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.email,
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _registerPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.password,
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _isLoading ? null : _register,
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : Text(AppLocalizations.of(context)!.register),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MainScaffold extends StatelessWidget {
  final Widget child;
  final bool isPremium;
  final VoidCallback? onUpgrade;
  const MainScaffold({super.key, required this.child, this.isPremium = false, this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    final Color mainColor = const Color(0xFFFFD600); // Lightning yellow
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: mainColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.store, size: 48, color: Colors.black),
                  const SizedBox(height: 8),
                  Text('BizTrackr', style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: Text(AppLocalizations.of(context)!.dashboard),
              onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: Text(AppLocalizations.of(context)!.inventory),
              onTap: () => Navigator.pushReplacementNamed(context, '/inventory'),
            ),
            ListTile(
              leading: const Icon(Icons.point_of_sale),
              title: Text(AppLocalizations.of(context)!.recordSale),
              onTap: () => Navigator.pushReplacementNamed(context, '/sales'),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: Text(AppLocalizations.of(context)!.customers),
              onTap: () => Navigator.pushReplacementNamed(context, '/customers'),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: Text(AppLocalizations.of(context)!.reports),
              onTap: () => Navigator.pushReplacementNamed(context, '/reports'),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(AppLocalizations.of(context)!.settings),
              onTap: () => Navigator.pushReplacementNamed(context, '/settings'),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: Text(AppLocalizations.of(context)!.aboutBizTrackr),
              onTap: () => Navigator.pushReplacementNamed(context, '/about'),
            ),
          ],
        ),
      ),
      body: child,
    );
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();