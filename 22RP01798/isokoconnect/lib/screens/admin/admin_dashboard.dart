import 'package:flutter/material.dart';
import '../../widgets/isoko_app_bar.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/app_menu.dart';
import '../../services/auth_service.dart';
import 'manage_products.dart';
import 'manage_users.dart';
import '../profile_screen.dart';
import '../notifications_screen.dart';
import '../../services/firestore_service.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart';
import '../../models/product_model.dart';

class AdminDashboard extends StatefulWidget {
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.getCurrentUser();
    
    if (currentUser == null) {
      return Scaffold(
        appBar: const IsokoAppBar(title: 'Admin Dashboard'),
        body: const Center(child: Text('User not authenticated')),
      );
    }

    return Navigator(
      onGenerateRoute: (settings) {
        if (settings.name == '/notifications') {
          return MaterialPageRoute(builder: (_) => NotificationsScreen(userRole: 'Admin'));
        }
        return MaterialPageRoute(builder: (_) => _buildMainScaffold(context));
      },
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return ManageProductsScreen();
      case 2:
        return ProfileScreen(
          userRole: 'Admin',
        );
      default:
        return _buildHomeScreen();
    }
  }

  Widget _buildHomeScreen() {
    return StreamBuilder<List<UserModel>>(
      stream: _firestoreService.getAllUsers(),
      builder: (context, userSnapshot) {
        return StreamBuilder<List<ProductModel>>(
          stream: _firestoreService.getAllProducts(),
          builder: (context, productSnapshot) {
            final users = userSnapshot.data ?? [];
            final products = productSnapshot.data ?? [];
            final totalUsers = users.length;
            final totalProducts = products.length;
            final activeSellers = users.where((u) => u.role == 'Seller').length;
            final activeBuyers = users.where((u) => u.role == 'Buyer').length;
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
                                backgroundColor: Colors.blue[100],
                                child: Icon(Icons.admin_panel_settings, size: 30, color: Colors.blue[800]),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Admin Panel',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: Colors.blue[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Manage the IsokoConnect platform',
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
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: InkWell(
                            onTap: () => setState(() => _currentIndex = 1),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(Icons.inventory, size: 40, color: Colors.blue[700]),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Manage Products',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'View all products',
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ManageUsersScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(Icons.people, size: 40, color: Colors.blue[700]),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Manage Users',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'View all users',
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
                  
                  // Stats section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.analytics_outlined, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Platform Statistics',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildStatItem('Total Users', '$totalUsers', Icons.people),
                          _buildStatItem('Total Products', '$totalProducts', Icons.inventory),
                          _buildStatItem('Active Sellers', '$activeSellers', Icons.agriculture),
                          _buildStatItem('Active Buyers', '$activeBuyers', Icons.shopping_basket),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Commission Tracking
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.account_balance_wallet, color: Colors.green[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Commission Tracking',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _firestoreService.getCommissionPayments(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              
                              final commissionPayments = snapshot.data ?? [];
                              final totalCommission = commissionPayments.fold<double>(
                                0, (sum, payment) => sum + (payment['commission'] ?? 0).toDouble()
                              );
                              
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          'Total Commission',
                                          '${totalCommission.toStringAsFixed(0)} RWF',
                                          Icons.monetization_on,
                                          Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildStatCard(
                                          'Total Payments',
                                          commissionPayments.length.toString(),
                                          Icons.payment,
                                          Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (commissionPayments.isNotEmpty) ...[
                                    Text(
                                      'Recent Commission Payments',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 200,
                                      child: ListView.builder(
                                        itemCount: commissionPayments.take(5).length,
                                        itemBuilder: (context, index) {
                                          final payment = commissionPayments[index];
                                          return ListTile(
                                            leading: Icon(Icons.payment, color: Colors.green),
                                            title: Text('Order #${payment['orderId']}'),
                                            subtitle: Text('Commission: ${payment['commission'].toStringAsFixed(0)} RWF'),
                                            trailing: Text(
                                              DateTime.parse(payment['paymentDate']).toString().substring(0, 10),
                                              style: TextStyle(color: Colors.grey[600]),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
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
            title: 'Admin Dashboard',
            onMenuPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            unreadCount: unreadCount,
          ),
          drawer: AppMenu(
            userRole: 'Admin',
            onHomePressed: () => setState(() => _currentIndex = 0),
            onProductsPressed: () => setState(() => _currentIndex = 1),
            onProfilePressed: () => setState(() => _currentIndex = 2),
          ),
          body: _buildCurrentScreen(),
          bottomNavigationBar: BottomNavigationWidget(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            userRole: 'Admin',
          ),
        );
      },
    );
  }
} 