import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'product_details_screen.dart';
import 'products_screen.dart';
import 'cart_screen.dart';
import 'order_approval_screen.dart';
import 'payment_screen.dart';
import 'order_history_screen.dart';
import 'notifications_screen.dart';
import 'admin_dashboard_screen.dart';
import 'user_dashboard_screen.dart';
import 'session_manager.dart';
import 'services/firebase_service.dart'; // Add Firebase service import
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase using the service
  final firebaseService = FirebaseService();
  await firebaseService.initialize();
  
  // Initialize sample data
  await firebaseService.initializeSampleData();
  
  runApp(const FarmerPayApp());
}

class FarmerPayApp extends StatelessWidget {
  const FarmerPayApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farmer Pay',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F5DC), // beige background
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const WelcomeScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/dashboard': (context) => const MainNavigation(),
      },
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background with sky blue and beige
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB3E5FC), // light sky blue
                  Color(0xFFF5F5DC), // beige
                ],
              ),
            ),
          ),
          // Decorative circles
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.brown.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Main content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Enhanced logo area
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB3E5FC), Color(0xFFF5F5DC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(color: Colors.blueAccent, width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.agriculture,
                          size: 70,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Farmer Pay',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(1, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Welcome to Farmer Pay! Empowering farmers to buy fertilizer and manage orders with ease. Join our community and experience a smarter way to grow.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        color: Color(0xFF4E342E), // deep brown for contrast
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 4,
                              shadowColor: Colors.blueAccent.withOpacity(0.3),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(fontSize: 19, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RegisterScreen()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF1976D2), width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              backgroundColor: Colors.white.withOpacity(0.85),
                            ),
                            child: const Text(
                              'Register',
                              style: TextStyle(fontSize: 19, color: Color(0xFF1976D2), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool showPassword = false;
  String? errorText;

  Future<void> handleLogin() async {
    setState(() {
      errorText = null;
    });
    final phone = phoneController.text.trim();
    final password = passwordController.text;
    if (phone.isEmpty || password.isEmpty) {
      setState(() {
        errorText = 'Please enter both phone number and password.';
      });
      return;
    }
    setState(() {
      isLoading = true;
    });
    try {
      // Firebase Auth login using email as phone@farmpay.com
      final email = '$phone@farmpay.com';
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Fetch user info from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).get();
      final userData = userDoc.data() ?? {};
      SessionManager().setUser(
        id: credential.user!.uid, // Use Firebase UID as String
        name: userData['name'] ?? '',
        role: userData['role'] ?? 'user',
        premiumStatus: userData['premium_status'] ?? 'none',
      );
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login successful! Welcome ${userData['name'] ?? ''}!'),
          backgroundColor: Colors.green,
        ),
      );
      if (userData['role'] == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserDashboardScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
        errorText = e.message ?? 'Login failed.';
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorText = 'Login failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB3E5FC),
                  Color(0xFFF5F5DC),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 8,
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Login to Farmer Pay',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                        ),
                        const SizedBox(height: 32),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                            prefixIcon: const Icon(Icons.phone),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: passwordController,
                          obscureText: !showPassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                            prefixIcon: const Icon(Icons.lock),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                            suffixIcon: IconButton(
                              icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  showPassword = !showPassword;
                                });
                              },
                            ),
                          ),
                        ),
                        if (errorText != null) ...[
                          const SizedBox(height: 12),
                          Text(errorText!, style: const TextStyle(color: Colors.red)),
                        ],
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 4,
                              shadowColor: Colors.blueAccent.withOpacity(0.3),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text('Login', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            );
                          },
                          child: const Text('Don\'t have an account? Register', style: TextStyle(color: Color(0xFF1976D2))),
                        ),
                        // SECURE: Register as Admin (only if no admin exists)
                        FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'admin').limit(1).get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) return SizedBox.shrink();
                            if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.admin_panel_settings),
                                  label: Text('Register as Admin'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepOrange,
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        final nameController = TextEditingController();
                                        final phoneController = TextEditingController();
                                        final passwordController = TextEditingController();
                                        bool isLoading = false;
                                        String? errorText;
                                        return StatefulBuilder(
                                          builder: (context, setState) {
                                            return AlertDialog(
                                              title: Text('Register as Admin'),
                                              content: SingleChildScrollView(
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    TextField(
                                                      controller: nameController,
                                                      decoration: InputDecoration(labelText: 'Full Name'),
                                                    ),
                                                    SizedBox(height: 12),
                                                    TextField(
                                                      controller: phoneController,
                                                      keyboardType: TextInputType.phone,
                                                      decoration: InputDecoration(labelText: 'Phone Number'),
                                                    ),
                                                    SizedBox(height: 12),
                                                    TextField(
                                                      controller: passwordController,
                                                      obscureText: true,
                                                      decoration: InputDecoration(labelText: 'Password'),
                                                    ),
                                                    if (errorText != null) ...[
                                                      SizedBox(height: 12),
                                                      Text(errorText!, style: TextStyle(color: Colors.red)),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: isLoading
                                                      ? null
                                                      : () async {
                                                          setState(() { isLoading = true; errorText = null; });
                                                          final name = nameController.text.trim();
                                                          final phone = phoneController.text.trim();
                                                          final password = passwordController.text;
                                                          if (name.isEmpty || phone.isEmpty || password.isEmpty) {
                                                            setState(() { isLoading = false; errorText = 'All fields are required.'; });
                                                            return;
                                                          }
                                                          if (password.length < 6) {
                                                            setState(() { isLoading = false; errorText = 'Password must be at least 6 characters.'; });
                                                            return;
                                                          }
                                                          try {
                                                            final email = '$phone@farmpay.com';
                                                            final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                                              email: email,
                                                              password: password,
                                                            );
                                                            await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
                                                              'name': name,
                                                              'phone': phone,
                                                              'role': 'admin',
                                                              'premium_status': 'approved',
                                                              'created_at': DateTime.now().toIso8601String(),
                                                            });
                                                            setState(() { isLoading = false; });
                                                            Navigator.pop(context);
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(content: Text('Admin registered! You can now log in.'), backgroundColor: Colors.green),
                                                            );
                                                          } on FirebaseAuthException catch (e) {
                                                            setState(() { isLoading = false; errorText = e.message ?? 'Admin registration failed.'; });
                                                          } catch (e) {
                                                            setState(() { isLoading = false; errorText = 'Admin registration failed: $e'; });
                                                          }
                                                        },
                                                  child: isLoading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Register'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              );
                            }
                            return SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final phoneController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isLoading = false;
  bool showPassword = false;
  String? errorText;
  final String role = 'user'; // always user now

  Future<void> handleRegister() async {
    setState(() {
      errorText = null;
    });
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    if (name.isEmpty || phone.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        errorText = 'Please fill all fields.';
      });
      return;
    }
    if (password != confirmPassword) {
      setState(() {
        errorText = 'Passwords do not match.';
      });
      return;
    }
    if (password.length < 6) {
      setState(() {
        errorText = 'Password must be at least 6 characters.';
      });
      return;
    }
    setState(() {
      isLoading = true;
    });
    try {
      // Firebase Auth registration using email as phone@farmpay.com
      final email = '$phone@farmpay.com';
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Store user info in Firestore
      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'phone': phone,
        'role': role,
        'premium_status': 'none',
        'created_at': DateTime.now().toIso8601String(),
      });
      SessionManager().setUser(
        id: credential.user!.uid, // Use Firebase UID as String
        name: name,
        role: role,
        premiumStatus: 'none',
      );
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration successful! Welcome $name!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserDashboardScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
        errorText = e.message ?? 'Registration failed.';
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorText = 'Registration failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB3E5FC),
                  Color(0xFFF5F5DC),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 8,
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Register for Farmer Pay',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                        ),
                        const SizedBox(height: 32),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                            prefixIcon: const Icon(Icons.person),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                            prefixIcon: const Icon(Icons.phone),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: passwordController,
                          obscureText: !showPassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                            prefixIcon: const Icon(Icons.lock),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                            suffixIcon: IconButton(
                              icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  showPassword = !showPassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: !showPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                            prefixIcon: const Icon(Icons.lock_outline),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (errorText != null) ...[
                          const SizedBox(height: 12),
                          Text(errorText!, style: const TextStyle(color: Colors.red)),
                        ],
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 4,
                              shadowColor: Colors.blueAccent.withOpacity(0.3),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text('Register', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          child: const Text('Already have an account? Login', style: TextStyle(color: Color(0xFF1976D2))),
                        ),
                      ],
                    ),
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

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = <Widget>[
    const FarmerDashboardScreen(),
    const ProductsScreen(),
    const CartScreen(),
    const NotificationsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF1976D2),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }
}

class FarmerDashboardScreen extends StatelessWidget {
  const FarmerDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFB3E5FC),
                Color(0xFFF5F5DC),
              ],
            ),
          ),
        ),
        // Decorative circles
        Positioned(
          top: -60,
          left: -60,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -40,
          right: -40,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.brown.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Main content
        SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 36, color: Colors.blue[700]),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Welcome, Farmer!',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Let’s grow together.',
                            style: TextStyle(fontSize: 16, color: Color(0xFF4E342E)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    children: [
                      _DashboardCard(
                        icon: Icons.shopping_bag,
                        label: 'Products',
                        color: Colors.blue[100]!,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProductsScreen()),
                          );
                        },
                      ),
                      _DashboardCard(
                        icon: Icons.shopping_cart,
                        label: 'Cart',
                        color: Colors.green[100]!,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CartScreen()),
                          );
                        },
                      ),
                      _DashboardCard(
                        icon: Icons.notifications,
                        label: 'Notifications',
                        color: Colors.orange[100]!,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                          );
                        },
                      ),
                      _DashboardCard(
                        icon: Icons.account_circle,
                        label: 'Profile',
                        color: Colors.purple[100]!,
                        onTap: () {
                          // Profile or settings (to be implemented)
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Quick Tips',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                  ),
                  const SizedBox(height: 12),
                  _TipCard(
                    icon: Icons.eco,
                    text: 'Check out the latest fertilizers for your crops!',
                  ),
                  _TipCard(
                    icon: Icons.payment,
                    text: 'Pay securely and track your orders easily.',
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartScreen()),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Go to Cart'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('Order History'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // For demo purposes, use order ID 1
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PaymentScreen(orderId: 'demo')),
                      );
                    },
                    icon: const Icon(Icons.payment),
                    label: const Text('Payment'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                      );
                    },
                    icon: const Icon(Icons.notifications),
                    label: const Text('Notifications'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OrderApprovalScreen()),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Admin: Approve Orders'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue[800]),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TipCard({required this.icon, required this.text, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Colors.blue[700]),
        title: Text(text, style: const TextStyle(fontSize: 15)),
      ),
    );
  }
}


