import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  final String username;
  final bool isPremium;
  final VoidCallback? onUpgrade;
  final VoidCallback? onLogout;
  const DashboardScreen({super.key, required this.username, this.isPremium = false, this.onUpgrade, this.onLogout});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final Map<String, List<String>> _weekDaysByLang = {
    'en': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    'fr': ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'],
  };

  // Enhanced demo data
  final Map<String, dynamic> _dashboardData = {
    'salesToday': 45000.0,
    'lowStockCount': 3,
    'customerCredit': 12000.0,
    'totalProducts': 45,
    'totalCustomers': 28,
    'monthlyRevenue': 125000.0,
    'salesData': [3.2, 4.1, 2.8, 5.3, 3.9, 4.7, 3.5],
    'topProducts': [
      {'name': 'Rice', 'sales': 15000},
      {'name': 'Beans', 'sales': 12000},
      {'name': 'Oil', 'sales': 8000},
    ],
    'recentTransactions': [
      {'customer': 'John Doe', 'amount': 2500, 'time': '2 min ago'},
      {'customer': 'Jane Smith', 'amount': 1800, 'time': '15 min ago'},
      {'customer': 'Mike Johnson', 'amount': 3200, 'time': '1 hour ago'},
    ]
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = const Color(0xFFFFD600); // Lightning yellow
    final Color accent = mainColor.withOpacity(0.1);
    final lang = Localizations.localeOf(context).languageCode;
    final List<String> weekDays = _weekDaysByLang[lang] ?? _weekDaysByLang['en']!;
    final isFrench = lang == 'fr';

    // Localized demo data
    final List<Map<String, dynamic>> topProducts = isFrench
        ? [
            {'name': 'Riz', 'sales': 15000},
            {'name': 'Haricots', 'sales': 12000},
            {'name': 'Huile', 'sales': 8000},
          ]
        : [
            {'name': 'Rice', 'sales': 15000},
            {'name': 'Beans', 'sales': 12000},
            {'name': 'Oil', 'sales': 8000},
          ];
    final List<Map<String, dynamic>> recentTransactions = isFrench
        ? [
            {'customer': 'Jean Dupont', 'amount': 2500, 'time': 'il y a 2 min'},
            {'customer': 'Marie Curie', 'amount': 1800, 'time': 'il y a 15 min'},
            {'customer': 'Michel Martin', 'amount': 3200, 'time': 'il y a 1 heure'},
          ]
        : [
            {'customer': 'John Doe', 'amount': 2500, 'time': '2 min ago'},
            {'customer': 'Jane Smith', 'amount': 1800, 'time': '15 min ago'},
            {'customer': 'Mike Johnson', 'amount': 3200, 'time': '1 hour ago'},
          ];
    final String inSales = AppLocalizations.of(context)!.inSales;
    final String encouragement = AppLocalizations.of(context)!.encouragement;
    final String greeting = AppLocalizations.of(context)!.greeting(widget.username);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.dashboard),
        backgroundColor: mainColor,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: mainColor,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.black, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        greeting,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (isFrench)
              Card(
                color: Colors.orange.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          encouragement,
                          style: const TextStyle(fontSize: 14, color: Colors.orange, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  icon: Icons.attach_money,
                  label: AppLocalizations.of(context)!.salesToday,
                  value: '45,000 RWF',
                  color: Colors.green.shade100,
                  iconColor: Colors.green.shade700,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.warning,
                  label: AppLocalizations.of(context)!.lowStockItems,
                  value: '3',
                  color: Colors.orange.shade100,
                  iconColor: Colors.orange.shade700,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.people,
                  label: AppLocalizations.of(context)!.customerCredit,
                  value: '12,000 RWF',
                  color: Colors.blue.shade100,
                  iconColor: Colors.blue.shade700,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSalesChart(mainColor, weekDays, isFrench),
            const SizedBox(height: 24),
            _buildQuickActions(mainColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color iconColor,
  }) {
    return Expanded(
      child: Card(
        color: color,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          icon: Icon(icon, size: 18),
          label: Text(label, style: const TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 1,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    final lang = Localizations.localeOf(context).languageCode;
    
    if (lang == 'fr') {
      if (hour < 12) return 'Bonjour! Prêt pour une journée productive?';
      if (hour < 17) return 'Bon après-midi! Comment se passe votre journée?';
      return 'Bonsoir! Avez-vous atteint vos objectifs aujourd\'hui?';
    } else {
      if (hour < 12) return 'Good morning! Ready for a productive day?';
      if (hour < 17) return 'Good afternoon! How is your day going?';
      return 'Good evening! Did you achieve your goals today?';
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.logout),
        content: Text(AppLocalizations.of(context)!.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.onLogout != null) widget.onLogout!();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(AppLocalizations.of(context)!.logout),
          ),
        ],
      ),
    );
  }

  void _showReportsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.premiumFeature),
        content: Text(AppLocalizations.of(context)!.reportsSubscriptionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/payment');
            },
            child: Text(AppLocalizations.of(context)!.upgrade),
          ),
        ],
      ),
    );
  }

     void _showNotifications() {
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
         content: Text(AppLocalizations.of(context)!.notificationsComingSoon),
         backgroundColor: const Color(0xFFFFD600),
         behavior: SnackBarBehavior.floating,
       ),
     );
   }

  void _showDetailedChart() {
    Navigator.pushNamed(context, '/reports');
  }

  Widget _buildSalesChart(Color mainColor, List<String> weekDays, bool isFrench) {
    final List<double> salesData = [3.2, 4.1, 2.8, 5.3, 3.9, 4.7, 3.5];
    final maxValue = salesData.reduce((a, b) => a > b ? a : b);
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
                Icon(Icons.bar_chart, color: mainColor),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.salesThisWeek,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: Row(
                children: salesData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final value = entry.value;
                  final height = (value / maxValue) * 80;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 18,
                          height: height,
                          decoration: BoxDecoration(
                            color: mainColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          weekDays[index],
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(Color mainColor, List<Map<String, dynamic>> recentTransactions) {
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
                Icon(Icons.history, color: mainColor),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.recentTransactions,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...recentTransactions.map((transaction) => ListTile(
              leading: CircleAvatar(
                backgroundColor: mainColor.withOpacity(0.1),
                child: Icon(Icons.person, color: mainColor, size: 18),
              ),
              title: Text(transaction['customer']),
              subtitle: Text(transaction['time']),
              trailing: Text(
                '${transaction['amount']} RWF',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProducts(Color mainColor, List<Map<String, dynamic>> topProducts, String inSales) {
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
                Icon(Icons.trending_up, color: mainColor),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.topProducts,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...topProducts.map((product) => ListTile(
              leading: CircleAvatar(
                backgroundColor: mainColor.withOpacity(0.1),
                child: Icon(Icons.inventory, color: mainColor, size: 18),
              ),
              title: Text(product['name']),
              subtitle: Text('${product['sales']} RWF $inSales'),
              trailing: Icon(Icons.arrow_forward_ios, size: 14),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(Color mainColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.point_of_sale,
          label: AppLocalizations.of(context)!.recordSale,
          onPressed: () => Navigator.pushNamed(context, '/sales'),
          color: mainColor,
        ),
        _buildActionButton(
          icon: Icons.inventory,
          label: AppLocalizations.of(context)!.inventory,
          onPressed: () => Navigator.pushNamed(context, '/inventory'),
          color: mainColor,
        ),
        _buildActionButton(
          icon: Icons.people,
          label: AppLocalizations.of(context)!.customers,
          onPressed: () => Navigator.pushNamed(context, '/customers'),
          color: mainColor,
        ),
        _buildActionButton(
          icon: Icons.bar_chart,
          label: AppLocalizations.of(context)!.reports,
          onPressed: () => _showReportsDialog(),
          color: mainColor,
        ),
        _buildActionButton(
          icon: Icons.smart_toy,
          label: AppLocalizations.of(context)!.aiAssistant,
          onPressed: () => Navigator.pushNamed(context, '/ai-assistant'),
          color: mainColor,
        ),
      ],
    );
  }
} 