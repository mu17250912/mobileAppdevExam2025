import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/sales_service.dart';
import '../widgets/common_widgets.dart';
import '../models/sale_model.dart';

class CashierDashboard extends StatefulWidget {
  const CashierDashboard({super.key});

  @override
  State<CashierDashboard> createState() => _CashierDashboardState();
}

class _CashierDashboardState extends State<CashierDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final salesService = Provider.of<SalesService>(context, listen: false);
      if (authService.currentUser != null) {
        salesService.loadSalesByCashier(authService.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashier Panel'),
        actions: [
          Consumer<AuthService>(
            builder: (context, authService, child) {
              return CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  authService.currentUser?.name.isNotEmpty == true
                      ? authService.currentUser!.name[0].toUpperCase()
                      : 'C',
                  style: const TextStyle(
                    color: Color(0xFF667eea),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer2<AuthService, SalesService>(
        builder: (context, authService, salesService, child) {
          final currentUser = authService.currentUser;
          if (currentUser == null) {
            return const LoadingWidget(message: 'Loading user data...');
          }

          return RefreshIndicator(
            onRefresh: () async {
              await salesService.loadSalesByCashier(currentUser.id);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '\$${salesService.getTodaySalesByCashier(currentUser.id).toStringAsFixed(0)}',
                          "Your Sales Today",
                          Icons.attach_money,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          '${salesService.getTodayTransactionCountByCashier(currentUser.id)}',
                          'Transactions',
                          Icons.receipt,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Quick Actions
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Start New Sale Button
                  CustomButton(
                    text: '🛒 Start New Sale',
                    onPressed: () => Navigator.pushNamed(context, '/sales-interface'),
                    height: 60,
                    icon: Icons.add_shopping_cart,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildQuickActionItem(
                    icon: Icons.history,
                    title: 'My Sales History',
                    onTap: () {
                      // TODO: Navigate to sales history
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sales History coming soon!')),
                      );
                    },
                  ),
                  
                  _buildQuickActionItem(
                    icon: Icons.settings,
                    title: 'Profile Settings',
                    onTap: () {
                      // TODO: Navigate to profile settings
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile Settings coming soon!')),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Recent Sales
                  const Text(
                    'Recent Sales',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  if (salesService.sales.isEmpty)
                    const EmptyStateWidget(
                      message: 'No sales yet',
                      icon: Icons.receipt_long,
                    )
                  else
                    ...salesService.sales.take(5).map((sale) => _buildSaleItem(sale)),
                  
                  const SizedBox(height: 100), // Space for bottom navigation
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const CommonBottomNavigation(currentIndex: 0),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF667eea).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF667eea),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSaleItem(SaleModel sale) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF667eea),
          child: Text(
            sale.items.length.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '\$${sale.total.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '${sale.items.length} items • ${sale.paymentMethod}',
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: Text(
          _formatDate(sale.createdAt),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays}d ago';
    }
  }
} 