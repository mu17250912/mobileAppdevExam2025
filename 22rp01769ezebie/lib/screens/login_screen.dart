import 'package:flutter/material.dart';
import 'admin_panel_screen.dart';
import 'weather_screen.dart';
import 'register_screen.dart';
import 'disease_screen.dart';
import 'market_screen.dart';
import 'tips_screen.dart';
import 'notification_center_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LoginScreen extends StatefulWidget {
  final bool showSuccessDialog;
  const LoginScreen({Key? key, this.showSuccessDialog = false}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.showSuccessDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Registration Successful!'),
            content: const Text('Your account has been created. You can now log in.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }
  }

  Future<void> _login() async {
    setState(() { _isLoading = true; _error = null; });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    try {
      var userBox = await Hive.openBox('users');
      final user = userBox.get(email);
      if (user != null && user['password'] == password) {
        setState(() { _isLoading = false; });
        final isAdmin = email.toLowerCase() == 'admin@infofarmer.com';
        // Always go to UserHomeScreen, pass isAdmin flag
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserHomeScreen(isAdmin: isAdmin, username: email),
          ),
        );
      } else {
        setState(() { _isLoading = false; _error = 'Invalid email or password'; });
      }
    } catch (e) {
      setState(() { _isLoading = false; _error = 'Login failed: $e'; });
    }
  }

  // Remove all GoogleAuthProvider, FirebaseAuthException, and FirebaseException code
  // Remove any Google sign-in button, logic, and exception handling

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      body: Center(
        child: SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: isWide ? 64 : 24, vertical: 32),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // App icon
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.deepPurple[100],
                          child: Icon(Icons.agriculture, size: 48, color: Colors.deepPurple[700], semanticLabel: 'App icon'),
                        ),
                        const SizedBox(height: 16),
                        Text('InfoFarmer', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple[700], letterSpacing: 1)),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email, color: Colors.deepPurple),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.deepPurple[50],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock, color: Colors.deepPurple),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.deepPurple[50],
                          ),
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(_error!, style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold)),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _login,
                            icon: Icon(Icons.login),
                            label: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Login', style: TextStyle(fontSize: 18)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Don\'t have an account?', style: TextStyle(color: Colors.grey[700])),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen()));
                              },
                              icon: Icon(Icons.app_registration, color: Colors.deepPurple),
                              label: Text('Register', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class UserHomeScreen extends StatefulWidget {
  final bool isAdmin;
  final String username;
  const UserHomeScreen({Key? key, required this.isAdmin, required this.username}) : super(key: key);

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedIndex = 0;

  List<Widget> get _screens => <Widget>[
    WeatherScreen(isAdmin: widget.isAdmin),
    DiseaseScreen(username: widget.username),
    MarketScreen(isAdmin: widget.isAdmin),
    TipsScreen(isAdmin: widget.isAdmin, username: widget.username),
  ];

  static const List<String> _titles = <String>[
    'Weather',
    'Diseases',
    'Market',
    'Tips',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Panel',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminPanelScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.help_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('How to Use'),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• Use the bottom navigation bar to switch between Weather, Diseases, Tips, and Market.'),
                        SizedBox(height: 8),
                        Text('• Tap the bell icon to view notifications (after login).'),
                        SizedBox(height: 8),
                        Text('• If there are new notifications or admin updates, a red badge with a number will appear on the bell icon.'),
                        SizedBox(height: 8),
                        Text('• Tap the logout icon to sign out.'),
                        SizedBox(height: 8),
                        Text('• In the Tips section, select a crop and category to view relevant tips.'),
                        SizedBox(height: 8),
                        Text('• Subscribe to premium for more features and content.'),
                        SizedBox(height: 8),
                        Text('• Use the camera icon in Diseases to detect diseases using AI.'),
                        SizedBox(height: 12),
                        Text('• For assistance, you can call: 0790686302 / 0727891938', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          // Notification icon with badge using hive_flutter
          Builder(
            builder: (context) {
              if (!Hive.isBoxOpen('notifications')) {
                return IconButton(
                  icon: const Icon(Icons.notifications),
                  tooltip: 'Notifications',
                  onPressed: null,
                );
              }
              final notifBox = Hive.box('notifications');
              return ValueListenableBuilder(
                valueListenable: notifBox.listenable(),
                builder: (context, Box notifBox, _) {
                  final unreadCount = notifBox.values.where((n) => n is Map && n['read'] != true).length;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications),
                        tooltip: 'Notifications',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => NotificationCenterScreen()),
                          );
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, semanticLabel: 'Logout'),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud, semanticLabel: 'Weather'),
            label: 'Weather',
            tooltip: 'Weather',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sick, semanticLabel: 'Diseases'),
            label: 'Diseases',
            tooltip: 'Diseases',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store, semanticLabel: 'Market'),
            label: 'Market',
            tooltip: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tips_and_updates, semanticLabel: 'Tips'),
            label: 'Tips',
            tooltip: 'Tips',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 16,
        unselectedFontSize: 14,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
} 