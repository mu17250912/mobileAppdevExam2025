import 'package:flutter/material.dart';
import 'products_screen.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import 'order_selection_screen.dart';
import 'notifications_screen.dart';
import 'main.dart';
import 'session_manager.dart';
import 'services/firebase_service.dart'; // Add Firebase service import
import 'dart:async';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({Key? key}) : super(key: key);
  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = const [
    ProductsScreen(),
    CartScreen(),
    OrderHistoryScreen(),
    OrderSelectionScreen(),
    NotificationsScreen(),
  ];

  Timer? _notificationTimer;
  int _lastNotificationId = 0;
  ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _startNotificationPolling();
    _updateUnreadCount();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _startNotificationPolling() {
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!mounted) return;
      await _updateUnreadCount();
    });
  }

  Future<void> _updateUnreadCount() async {
    final userId = SessionManager().userId;
    if (userId == null) return;
    
    try {
      final count = await _firebaseService.getUnreadNotificationCount(userId);
      if (mounted) {
        unreadCountNotifier.value = count;
      }
    } catch (e) {
      print('Error updating unread count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  tooltip: 'Logout',
                  onPressed: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Logout'),
                        content: const Text('Are you sure you want to log out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                    if (shouldLogout == true) {
                      await _firebaseService.signOut();
                      SessionManager().clear();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 8,
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _QuickLink(
                          icon: Icons.shopping_bag,
                          label: 'Products',
                          onTap: () => setState(() => _selectedIndex = 0),
                        ),
                        _QuickLink(
                          icon: Icons.shopping_cart,
                          label: 'Cart',
                          onTap: () => setState(() => _selectedIndex = 1),
                        ),
                        _QuickLink(
                          icon: Icons.history,
                          label: 'Orders',
                          onTap: () => setState(() => _selectedIndex = 2),
                        ),
                        _QuickLink(
                          icon: Icons.payment,
                          label: 'Pay Orders',
                          onTap: () => setState(() => _selectedIndex = 3),
                        ),
                        _QuickLink(
                          icon: Icons.notifications,
                          label: 'Notifications',
                          onTap: () => setState(() => _selectedIndex = 4),
                          badge: unreadCountNotifier,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: _screens[_selectedIndex]),
          ],
        ),
      ],
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ValueNotifier<int>? badge;
  const _QuickLink({required this.icon, required this.label, required this.onTap, this.badge, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue[100],
                radius: 20,
                child: Icon(icon, color: Colors.blue[800], size: 20),
              ),
              if (badge != null && badge!.value > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Center(
                      child: Text(
                        badge!.value.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
} 