// Seller Dashboard Placeholder
import 'package:flutter/material.dart';
import '../../widgets/isoko_app_bar.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/app_menu.dart';
import '../../services/auth_service.dart';
import 'add_product_screen.dart';
import 'my_products.dart';
import '../profile_screen.dart';
import 'manage_orders.dart';
import '../notifications_screen.dart';
import '../../services/firestore_service.dart';
import '../../models/notification_model.dart';

class SellerDashboard extends StatefulWidget {
  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.getCurrentUser();
    
    if (currentUser == null) {
      return Scaffold(
        appBar: const IsokoAppBar(title: 'Seller Dashboard'),
        body: const Center(child: Text('User not authenticated')),
      );
    }

    return Navigator(
      onGenerateRoute: (settings) {
        if (settings.name == '/seller/manage_orders') {
          return MaterialPageRoute(builder: (_) => ManageOrdersScreen());
        }
        if (settings.name == '/notifications') {
          return MaterialPageRoute(builder: (_) => NotificationsScreen(userRole: 'Seller'));
        }
        return MaterialPageRoute(builder: (_) => _buildMainScaffold(context));
      },
    );
  }

  Widget _buildMainScaffold(BuildContext context) {
    final currentUser = _authService.getCurrentUser();
    return StreamBuilder<List<NotificationModel>>(
      stream: currentUser == null
          ? const Stream.empty()
          : _firestoreService.getNotificationsByUser(currentUser.uid),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.where((n) => !n.isRead).length ?? 0;
        return Scaffold(
          key: _scaffoldKey,
          appBar: IsokoAppBar(
            title: 'Seller Dashboard',
            onMenuPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            unreadCount: unreadCount,
          ),
          drawer: AppMenu(
            userRole: 'Seller',
            onHomePressed: () => setState(() => _currentIndex = 0),
            onProductsPressed: () => setState(() => _currentIndex = 1),
            onProfilePressed: () => setState(() => _currentIndex = 2),
          ),
          body: _buildCurrentScreen(),
          bottomNavigationBar: BottomNavigationWidget(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            userRole: 'Seller',
          ),
        );
      },
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return MyProductsScreen();
      case 2:
        return ProfileScreen(
          userRole: 'Seller',
        );
      default:
        return _buildHomeScreen();
    }
  }

  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.green[100],
                        child: Icon(Icons.agriculture, size: 30, color: Colors.green[800]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back! 👨‍🌾',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ready to sell your crops?',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Quick actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddProductScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.add_box, size: 40, color: Colors.green[700]),
                          const SizedBox(height: 12),
                          Text(
                            'Add Product',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add new crop',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () => setState(() => _currentIndex = 1),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.inventory, size: 40, color: Colors.green[700]),
                          const SizedBox(height: 12),
                          Text(
                            'My Products',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage crops',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Tips section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Selling Tips',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTip('Set competitive prices to attract buyers'),
                  _buildTip('Keep your product information updated'),
                  _buildTip('Respond quickly to buyer inquiries'),
                  _buildTip('Provide accurate quantity and quality details'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 