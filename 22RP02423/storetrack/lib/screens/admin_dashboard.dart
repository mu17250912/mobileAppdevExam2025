import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/sales_service.dart';
import '../services/premium_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/upgrade_banner.dart';
import '../models/sale_model.dart';
import 'coming_soon_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productService = Provider.of<ProductService>(context, listen: false);
      final salesService = Provider.of<SalesService>(context, listen: false);
      productService.loadProducts();
      salesService.loadSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StoreTrack Dashboard'),
        actions: [
          Consumer<AuthService>(
            builder: (context, authService, child) {
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    authService.currentUser?.name.isNotEmpty == true
                        ? authService.currentUser!.name[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Color(0xFF667eea),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer2<ProductService, SalesService>(
        builder: (context, productService, salesService, child) {
          return RefreshIndicator(
            onRefresh: () async {
              await productService.loadProducts();
              await salesService.loadSales();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upgrade Banner
                  const UpgradeBanner(),
                  
                  // Low Stock Alert
                  if (productService.lowStockProducts.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        border: Border.all(color: const Color(0xFFFFEAA7)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFF856404),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${productService.lowStockProducts.length} products are running low on stock',
                              style: const TextStyle(
                                color: Color(0xFF856404),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                  
                  // Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '\$${salesService.getTodaySales().toStringAsFixed(0)}',
                          "Today's Sales",
                          Icons.attach_money,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          '${productService.products.length}',
                          'Total Products',
                          Icons.inventory,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '${salesService.getTodayTransactionCount()}',
                          'Transactions',
                          Icons.receipt,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          '${productService.lowStockProducts.length}',
                          'Low Stock Items',
                          Icons.warning,
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
                  
                  _buildQuickActionItem(
                    icon: Icons.inventory_2,
                    title: 'Manage Products',
                    onTap: () => Navigator.pushNamed(context, '/product-management'),
                  ),
                  
                  _buildQuickActionItem(
                    icon: Icons.shopping_cart,
                    title: 'Start New Sale',
                    onTap: () => Navigator.pushNamed(context, '/sales-interface'),
                  ),
                  
                  _buildQuickActionItem(
                    icon: Icons.history,
                    title: 'Sales History',
                    onTap: () => Navigator.pushNamed(context, '/sales-history'),
                  ),
                  
                  _buildQuickActionItem(
                    icon: Icons.people,
                    title: 'User Management',
                    onTap: () => _handlePremiumFeature(context, 'team_management', 'User Management'),
                  ),
                  
                  _buildQuickActionItem(
                    icon: Icons.analytics,
                    title: 'Reports',
                    onTap: () => _handlePremiumFeature(context, 'advanced_reports', 'Advanced Reports'),
                  ),
                  
                  _buildQuickActionItem(
                    icon: Icons.star,
                    title: 'Premium Features',
                    onTap: () => Navigator.pushNamed(context, '/premium-features'),
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
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No sales yet',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
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
            sale.cashierName.isNotEmpty ? sale.cashierName[0].toUpperCase() : 'C',
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
          '${sale.items.length} items • ${sale.cashierName}',
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

  void _handlePremiumFeature(BuildContext context, String featureId, String featureTitle) {
    final premiumService = Provider.of<PremiumService>(context, listen: false);
    
    if (premiumService.isFeatureAvailable(featureId)) {
      // Feature is available, navigate to it
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$featureTitle is now available!')),
      );
    } else if (premiumService.isFeatureComingSoon(featureId)) {
      // Feature is coming soon, show coming soon screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ComingSoonScreen(
            featureId: featureId,
            featureTitle: featureTitle,
            featureDescription: 'This feature is coming soon and will be available to premium users.',
            featureIcon: Icons.star,
          ),
        ),
      );
    } else {
      // Feature requires premium, show upgrade dialog
      showDialog(
        context: context,
        builder: (context) => const UpgradeDialog(),
      );
    }
  }
} 