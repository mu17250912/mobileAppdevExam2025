// Buyer Home Screen Placeholder
import 'package:flutter/material.dart';
import '../../widgets/isoko_app_bar.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/app_menu.dart';
import '../../services/auth_service.dart';
import 'products_screen.dart';
import '../profile_screen.dart';
import 'my_orders_screen.dart';
import '../notifications_screen.dart';
import '../../models/notification_model.dart';
import '../../services/firestore_service.dart';

class BuyerHomeScreen extends StatefulWidget {
  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.getCurrentUser();
    
    if (currentUser == null) {
      return Scaffold(
        appBar: const IsokoAppBar(title: 'Buyer Home'),
        body: const Center(child: Text('User not authenticated')),
      );
    }

    return Navigator(
      onGenerateRoute: (settings) {
        if (settings.name == '/buyer/my_orders') {
          return MaterialPageRoute(builder: (_) => MyOrdersScreen());
        }
        if (settings.name == '/notifications') {
          return MaterialPageRoute(builder: (_) => NotificationsScreen(userRole: 'Buyer'));
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
            title: 'Buyer Home',
            onMenuPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            unreadCount: unreadCount,
          ),
          drawer: AppMenu(
            userRole: 'Buyer',
            onHomePressed: () => setState(() => _currentIndex = 0),
            onProductsPressed: () => setState(() => _currentIndex = 1),
            onProfilePressed: () => setState(() => _currentIndex = 2),
          ),
          body: _buildCurrentScreen(),
          bottomNavigationBar: BottomNavigationWidget(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            userRole: 'Buyer',
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
        return ProductsScreen();
      case 2:
        return ProfileScreen(
          userRole: 'Buyer',
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
                        child: Icon(Icons.shopping_basket, size: 30, color: Colors.green[800]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome!',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Find fresh crops from local farmers',
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
          
          Card(
            child: InkWell(
              onTap: () => setState(() => _currentIndex = 1),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.shopping_basket, size: 40, color: Colors.green[700]),
                    const SizedBox(height: 12),
                    Text(
                      'Browse Products',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View all crops from local farmers',
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
                        'Buying Tips',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTip('Contact sellers directly for the best deals'),
                  _buildTip('Check product quality and quantity before buying'),
                  _buildTip('Compare prices from different sellers'),
                  _buildTip('Ask about delivery options and payment methods'),
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