import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'placeholder_screen.dart';
import 'widgets/dashboard_card.dart';
import 'marketplace_screen.dart';
import 'fertilizer_guide_screen.dart';
import 'my_orders_screen.dart';
import 'view_orders_screen.dart';
import 'welcome_screen.dart';
import 'services/analytics_service.dart';
import 'services/notification_service.dart';
import 'services/offline_service.dart';
import 'services/performance_service.dart';
import 'services/error_reporting_service.dart';
import 'widgets/loading_widget.dart';
import 'widgets/error_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'services/cart_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';
import 'dart:async';
import 'dart:math' as math;

// Enhanced Farmer Profile Page
class FarmerProfilePage extends StatefulWidget {
  final String username;
  const FarmerProfilePage({super.key, required this.username});

  @override
  State<FarmerProfilePage> createState() => _FarmerProfilePageState();
}

class _FarmerProfilePageState extends State<FarmerProfilePage> {
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user == null) throw Exception('User not logged in');
      final firestore = FirebaseFirestore.instance;

      // Load user profile from Firestore
      final userDoc = await firestore.collection('users').doc(user).get();
      final userData = userDoc.data() ?? {};

      // Load orders for analytics
      final ordersSnap = await firestore
          .collection('orders')
          .where('username', isEqualTo: user)
          .get();
      final orders = ordersSnap.docs.map((doc) => doc.data()).toList();

      // Calculate analytics
      double totalSpent = 0;
      for (var order in orders) {
        totalSpent += (order['amount'] ?? 0).toDouble();
      }

      final profileData = {
        'username': widget.username,
        'role': 'Farmer',
        'joinDate': userData['joinDate'] ?? 'Unknown',
        'totalOrders': orders.length,
        'totalSpent': totalSpent,
        'farms': userData['farms'] ?? 1,
        'crops': userData['crops'] ?? ['Maize', 'Beans'],
      };
      
      if (mounted) {
        setState(() {
          _userData = profileData;
        });
      }
    } catch (e) {
      // Handle error silently or show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile data: $e')),
        );
      }
    }
  }

  void _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final size = MediaQuery.of(context).size;
    return Stack(
        children: [
        // Animated gradient background
        AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          width: double.infinity,
          height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF4CAF50),
                Colors.green[900]!,
              ],
            ),
          ),
        ),
        // Animated floating background elements
        ...List.generate(12, (index) {
          final random = math.Random(index);
          final x = random.nextDouble() * size.width;
          final y = random.nextDouble() * size.height;
          final s = random.nextDouble() * 6 + 3;
          final opacity = random.nextDouble() * 0.2 + 0.1;
          return Positioned(
            left: x,
            top: y,
            child: Transform.rotate(
              angle: (index % 2 == 0 ? 1 : -1) * 2 * math.pi * (DateTime.now().millisecond / 1000),
              child: Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(opacity),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
        // Main content
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glassmorphic profile card
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxWidth: 420,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                      backgroundBlendMode: BlendMode.overlay,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.agriculture,
                      size: 50,
                      color: Colors.green[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Farmer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
            ),
          ),
          const SizedBox(height: 24),
          // Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Orders',
                  '${_userData?['totalOrders'] ?? 0}',
                  Icons.shopping_cart,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Spent',
                  'RWF ${NumberFormat('#,###').format(_userData?['totalSpent'] ?? 0)}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Farms',
                  '${_userData?['farms'] ?? 1}',
                  Icons.landscape,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Member Since',
                  _userData?['joinDate'] ?? 'Unknown',
                  Icons.calendar_today,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Crops Section
          if (_userData?['crops'] != null && (_userData!['crops'] as List).isNotEmpty) ...[
            const Text(
              'My Crops',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                        color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_userData!['crops'] as List).map<Widget>((crop) {
                return Chip(
                  label: Text(crop),
                  backgroundColor: Colors.green[100],
                  labelStyle: TextStyle(color: Colors.green[700]),
                );
              }).toList(),
            ),
          ],
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
          _buildQuickActionButton(
            'Edit Profile',
            Icons.edit,
            Colors.blue,
            () {
              // Profile editing will be implemented in future updates
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile editing coming soon!')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(
            'Settings',
            Icons.settings,
            Colors.grey,
            () {
              // Settings will be implemented in future updates
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(
            'Help & Support',
            Icons.help_outline,
            Colors.orange,
            () {
              // Help & Support will be implemented in future updates
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help & Support coming soon!')),
              );
            },
          ),
          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// Enhanced Main Dashboard Widget
class FarmerDashboard extends StatefulWidget {
  final String username;
  const FarmerDashboard({super.key, required this.username});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _tabController = TabController(length: 3, vsync: this);
    _pages = <Widget>[
      const FarmerHomeGrid(),
      const FertilizerGuideScreen(),
      const MarketplaceScreen(),
      FarmerProfilePage(username: widget.username),
    ];
    
    _trackDashboardView();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  Future<void> _trackDashboardView() async {
    try {
      await AnalyticsService.trackScreenView('farmer_dashboard');
      await AnalyticsService.setUserProperty('user_role', 'farmer');
      await PerformanceService.trackScreenLoad('farmer_dashboard');
    } catch (e) {
      // Ignore tracking errors
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = index;
    });
    
    // Track navigation
    AnalyticsService.trackUserEngagement(
      action: 'navigation',
      screen: 'farmer_dashboard',
      additionalParams: {'tab_index': index},
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Scaffold(
          appBar: _buildAppBar(),
          body: _pages.elementAt(_selectedIndex),
          bottomNavigationBar: _buildBottomNavigationBar(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.agriculture,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, ${widget.username}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Farmer Dashboard',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
        automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
          icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
            HapticFeedback.lightImpact();
            _showNotifications();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
            HapticFeedback.lightImpact();
              setState(() {});
            },
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            HapticFeedback.lightImpact();
            _handleMenuSelection(value);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline),
                  SizedBox(width: 8),
                  Text('Profile'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'help',
              child: Row(
                children: [
                  Icon(Icons.help_outline),
                  SizedBox(width: 8),
                  Text('Help & Support'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grass_outlined),
            activeIcon: Icon(Icons.grass),
            label: 'Guide',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined),
            activeIcon: Icon(Icons.store),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(child: Text('Notifications coming soon!')),
          ],
        ),
        backgroundColor: Colors.blue[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _handleMenuSelection(String value) async {
    switch (value) {
      case 'profile':
        setState(() => _selectedIndex = 3);
        break;
      case 'settings':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings coming soon!')),
        );
        break;
      case 'help':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Help & Support coming soon!')),
        );
        break;
      case 'logout':
        await _confirmLogout();
        break;
    }
  }

  Future<void> _confirmLogout() async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirm Logout'),
          ],
        ),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
    
              if (confirmed == true) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await AnalyticsService.trackLogout(
          username: authService.currentUser ?? 'Unknown',
          role: authService.userRole ?? 'farmer',
        );
        await authService.logout();
        
        if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                  (route) => false,
                );
              }
      } catch (e) {
        await ErrorReportingService.reportError(
          errorType: 'logout_error',
          errorMessage: 'Failed to logout user',
          error: e,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: Colors.red,
      ),
    );
        }
      }
    }
  }
}

// Enhanced Home Grid with Weather and Analytics
class FarmerHomeGrid extends StatefulWidget {
  const FarmerHomeGrid({super.key});

  @override
  State<FarmerHomeGrid> createState() => _FarmerHomeGridState();
}

class _FarmerHomeGridState extends State<FarmerHomeGrid>
    with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboardData();
  }

  Future<Map<String, dynamic>> _loadDashboardData() async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) throw Exception('User not logged in');
    final firestore = FirebaseFirestore.instance;

    try {
      // Orders - use buyerId field instead of username
      final ordersSnap = await firestore
          .collection('orders')
          .where('buyerId', isEqualTo: user)
          .orderBy('orderDate', descending: true)
          // .limit(5) // Removed limit to show all orders
          .get();
      final orders = ordersSnap.docs.map((doc) => doc.data()).toList();

      // Analytics
      int totalOrders = orders.length;
      double totalSpent = 0;
      double savings = 0;
      int pendingOrders = 0;
      for (var order in orders) {
        totalSpent += (order['price'] ?? order['totalAmount'] ?? 0).toDouble();
        if ((order['status'] ?? '').toLowerCase() == 'pending') pendingOrders++;
      }
      // (Optional) Calculate savings if you have such logic

      // Recommendations
      List<Map<String, dynamic>> recommendations = [];
      try {
        final recSnap = await firestore
            .collection('recommendations')
            .where('buyerId', isEqualTo: user)
            .limit(5)
            .get();
        recommendations = recSnap.docs.map((doc) => doc.data()).toList();
      } catch (e) {
        print('Error loading recommendations: $e');
        // Continue without recommendations
      }

      return {
        'orders': orders,
        'analytics': {
          'totalOrders': totalOrders,
          'totalSpent': totalSpent,
          'savings': savings,
          'pendingOrders': pendingOrders,
        },
        'recommendations': recommendations,
      };
    } catch (e) {
      print('Error loading dashboard data: $e');
      // Return empty data on error
      return {
        'orders': [],
        'analytics': {
          'totalOrders': 0,
          'totalSpent': 0,
          'savings': 0,
          'pendingOrders': 0,
        },
        'recommendations': [],
      };
    }
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load dashboard: ${snapshot.error}'));
        }
        final data = snapshot.data!;
        final analytics = data['analytics'] as Map<String, dynamic>;
        final orders = data['orders'] as List;
        final recommendations = data['recommendations'] as List;
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _dashboardFuture = _loadDashboardData();
            });
            await _dashboardFuture;
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Analytics Overview
                const Text(
                  'My Farming Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildAnalyticsCards(analytics),
                const SizedBox(height: 24),
                // Recent Orders
                _buildRecentOrders(orders),
                const SizedBox(height: 24),
                // Crop Recommendations
                _buildCropRecommendations(recommendations),
                const SizedBox(height: 24),
                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildQuickActionsGrid(),
              ],
            ),
          ),
        );
      },
    );
  }

  // Weather card removed - will be implemented when weather API is available
  Widget _buildWeatherCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue[400]!, Colors.blue[600]!],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.wb_sunny,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weather',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Coming Soon',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '--',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const Text(
                      'Humidity',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Weather integration will be available soon',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCards(Map<String, dynamic> analytics) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Total Orders',
                '${analytics['totalOrders']}',
                Icons.shopping_cart,
                Colors.blue,
                '${analytics['pendingOrders']} pending',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticsCard(
                'Total Spent',
                'RWF ${NumberFormat('#,###').format(analytics['totalSpent'])}',
                Icons.attach_money,
                Colors.green,
                'RWF ${NumberFormat('#,###').format(analytics['savings'])} saved',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders(List orders) {
    if (orders.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No recent orders.'),
        ),
      );
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Recent Orders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _navigateTo(context, const ViewOrdersScreen()),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...orders.map((order) => _buildOrderItem(order)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: order['status'] == 'Delivered' ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['product'] ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'RWF ${NumberFormat('#,###').format(order['amount'] ?? 0)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                order['status'] ?? '-',
                style: TextStyle(
                  color: order['status'] == 'Delivered' ? Colors.green : Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                order['date'] ?? '-',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCropRecommendations(List recommendations) {
    if (recommendations.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No crop recommendations.'),
        ),
      );
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crop Recommendations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...recommendations.map((rec) => _buildRecommendationItem(rec)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(Map<String, dynamic> rec) {
    Color priorityColor = rec['priority'] == 'High' ? Colors.red : Colors.orange;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              rec['priority'] ?? '-',
              style: TextStyle(
                color: priorityColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec['crop'] ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  rec['recommendation'] ?? '-',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        DashboardCard(
          icon: Icons.store_mall_directory,
          label: 'Marketplace',
          onTap: () => _navigateTo(context, const MarketplaceScreen()),
        ),
        DashboardCard(
          icon: Icons.grass,
          label: 'Fertilizer Guide',
          onTap: () => _navigateTo(context, const FertilizerGuideScreen()),
        ),
        DashboardCard(
          icon: Icons.receipt_long,
          label: 'My Orders',
          onTap: () => _navigateTo(context, const ViewOrdersScreen()),
        ),
        DashboardCard(
          icon: Icons.article,
          label: 'Articles',
          onTap: () => _navigateTo(context, const PlaceholderScreen(title: 'Articles')),
        ),
        DashboardCard(
          icon: Icons.support_agent,
          label: 'Support Chat',
          onTap: () => _navigateTo(context, const PlaceholderScreen(title: 'Support Chat')),
        ),
        DashboardCard(
          icon: Icons.location_on,
          label: 'Store Locator',
          onTap: () => _navigateTo(context, const PlaceholderScreen(title: 'Store Locator')),
        ),
      ],
    );
  }
} 