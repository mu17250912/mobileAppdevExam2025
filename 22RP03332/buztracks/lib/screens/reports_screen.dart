import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../widgets/premium_restriction_widget.dart';
import '../services/premium_print_service.dart';
import '../services/subscription_service.dart';
import '../services/firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/print_service.dart';

class ReportsScreen extends StatefulWidget {
  final VoidCallback? onUpgrade;
  final int? initialTabIndex;
  
  const ReportsScreen({super.key, this.onUpgrade, this.initialTabIndex});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final PremiumPrintService _printService = PremiumPrintService();
  final FirestoreService _firestoreService = FirestoreService();
  final Color mainColor = const Color(0xFFFFD600);
  final PrintService _inventoryPrintService = PrintService();
  
  Map<String, dynamic>? _analytics;
  Map<String, dynamic>? _minimizationStrategy;
  bool _isLoading = true;
  bool _isPremium = false;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _sales = [];
  Map<String, dynamic> _financeData = {
    'revenue': 125000,
    'expenses': 45000,
    'profit': 80000,
    'margin': 64,
    'costBreakdown': {
      'Inventory': 25000,
      'Operations': 15000,
      'Marketing': 5000,
      'Potential Savings': 15000,
    },
  };

  @override
  void initState() {
    super.initState();
    int initialTab = widget.initialTabIndex ?? 0;
    _tabController = TabController(length: 5, vsync: this, initialIndex: initialTab);
    _checkPremiumStatus();
    _loadAnalytics();
    _firestoreService.getProductsStream().listen((products) {
      setState(() {
        _products = products;
      });
    });
    // Listen to sales data for Sales tab printing
    _firestoreService.getSalesStream().listen((sales) {
      setState(() {
        _sales = sales;
      });
    });
  }

  Future<void> _checkPremiumStatus() async {
    final subscription = await SubscriptionService().getCurrentSubscription();
    setState(() {
      _isPremium = (subscription?['plan'] == 'premium' || subscription?['plan'] == 'enterprise');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading analytics data
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _analytics = {
        'totalSales': 125000,
        'totalTransactions': 89,
        'averageTransaction': 1404,
        'dailySales': {
          '2024-01-01': 4500,
          '2024-01-02': 5200,
          '2024-01-03': 4800,
          '2024-01-04': 6100,
          '2024-01-05': 5800,
          '2024-01-06': 7200,
          '2024-01-07': 6800,
        },
      };
      
      _minimizationStrategy = {
        'strategies': {
          'inventory_optimization': {
            'title': 'Optimisation des stocks',
            'description': 'Réduire les stocks excédentaires et optimiser les commandes',
            'priority': 'high',
            'potentialSavings': '15,000 RWF',
            'implementationTime': '2-3 semaines',
          },
          'supplier_negotiation': {
            'title': 'Négociation avec les fournisseurs',
            'description': 'Renégocier les prix et conditions de paiement',
            'priority': 'medium',
            'potentialSavings': '8,000 RWF',
            'implementationTime': '1-2 semaines',
          },
          'energy_efficiency': {
            'title': 'Efficacité énergétique',
            'description': 'Optimiser la consommation d\'énergie',
            'priority': 'low',
            'potentialSavings': '3,000 RWF',
            'implementationTime': '1 semaine',
          },
        },
      };
      
      _isLoading = false;
    });
  }

  Future<void> _printBusinessReport() async {
    try {
      final lang = Localizations.localeOf(context).languageCode;
      await _printService.printBusinessReport(
        sales: _sales,
        products: _products,
        financeData: _financeData,
        language: lang,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.reportPrintedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorPrinting(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _printSalesReport() async {
    try {
      final lang = Localizations.localeOf(context).languageCode;
      await _inventoryPrintService.printSalesSummary(_sales, lang);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.salesReportPrinted),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorPrinting(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _printFinancialReport() async {
    try {
      final lang = Localizations.localeOf(context).languageCode;
      await _inventoryPrintService.printFinanceSummary(_financeData, lang);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.financialReportPrinted),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorPrinting(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleMainPrint() async {
    // Always print the full summary report, regardless of tab
    await _printBusinessReport();
  }

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';
    // If redirected from payment, force premium
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final forcePremium = args != null && args['forcePremium'] == true;

    if (!_isPremium && !forcePremium) {
      return PremiumRestrictionWidget(
        onUpgrade: widget.onUpgrade,
        customIcon: const Icon(Icons.bar_chart),
        customTitle: AppLocalizations.of(context)!.premiumReports,
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(AppLocalizations.of(context)!.reports),
        backgroundColor: mainColor,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _handleMainPrint,
            tooltip: AppLocalizations.of(context)!.printReport,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.overview),
            Tab(text: AppLocalizations.of(context)!.sales),
            Tab(text: 'Stock'),
            Tab(text: AppLocalizations.of(context)!.finance),
            Tab(text: AppLocalizations.of(context)!.strategies),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context, isFrench),
                _buildSalesTab(context, isFrench),
                _buildStockTab(context),
                _buildFinanceTab(context, isFrench),
                _buildStrategiesTab(context, isFrench),
              ],
            ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, bool isFrench) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, isFrench ? 'Métriques Clés' : 'Key Metrics', Icons.analytics),
          const SizedBox(height: 16),
          _buildMetricsGrid(context, isFrench),
          const SizedBox(height: 24),
          _buildSectionHeader(context, AppLocalizations.of(context)!.salesTrends, Icons.trending_up),
          const SizedBox(height: 16),
          _buildSalesChart(context, isFrench),
          const SizedBox(height: 24),
          _buildSectionHeader(context, AppLocalizations.of(context)!.businessInsights, Icons.psychology),
          const SizedBox(height: 16),
          _buildChartContainer(context, AppLocalizations.of(context)!.insightsPlaceholder, height: 150),
          const SizedBox(height: 24),
          _buildSectionHeader(context, isFrench ? 'Analyse IA' : 'AI Analytics', Icons.auto_awesome),
          const SizedBox(height: 16),
          _buildChartContainer(context, isFrench ? 'Analyse prédictive et recommandations IA' : 'Predictive analysis and AI recommendations', height: 180),
        ],
      ),
    );
  }

  Widget _buildSalesTab(BuildContext context, bool isFrench) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(context, isFrench ? 'Rapport de Ventes' : 'Sales Report', Icons.receipt),
              ElevatedButton.icon(
                onPressed: _printSalesReport,
                icon: const Icon(Icons.print),
                label: Text(isFrench ? 'Imprimer' : 'Print'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSalesChart(context, isFrench),
          const SizedBox(height: 24),
          _buildMetricsGrid(context, isFrench),
          const SizedBox(height: 24),
          _buildSectionHeader(context, isFrench ? 'Détails des Ventes' : 'Sales Details', Icons.list),
          const SizedBox(height: 16),
          _buildSalesDetails(context, isFrench),
        ],
      ),
    );
  }

  Widget _buildFinanceTab(BuildContext context, bool isFrench) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(context, isFrench ? 'Rapport Financier' : 'Financial Report', Icons.account_balance),
              ElevatedButton.icon(
                onPressed: _printFinancialReport,
                icon: const Icon(Icons.print),
                label: Text(isFrench ? 'Imprimer' : 'Print'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFinancialMetrics(context, isFrench),
          const SizedBox(height: 24),
          _buildSectionHeader(context, isFrench ? 'Analyse des Coûts' : 'Cost Analysis', Icons.trending_down),
          const SizedBox(height: 16),
          _buildCostAnalysis(context, isFrench),
        ],
      ),
    );
  }

  Widget _buildStrategiesTab(BuildContext context, bool isFrench) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, isFrench ? 'Métriques de Performance' : 'Performance Metrics', Icons.analytics),
          const SizedBox(height: 16),
          _buildMetricsGrid(context, isFrench),
          const SizedBox(height: 24),
          _buildSectionHeader(context, isFrench ? 'Stratégies de Minimisation' : 'Minimization Strategies', Icons.trending_down),
          const SizedBox(height: 16),
          _buildMinimizationStrategies(context, isFrench),
        ],
      ),
    );
  }

  Widget _buildSalesDetails(BuildContext context, bool isFrench) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildDetailRow(isFrench ? 'Ventes Totales' : 'Total Sales', '125,000 RWF', Colors.green),
          _buildDetailRow(isFrench ? 'Nombre de Transactions' : 'Number of Transactions', '89', Colors.blue),
          _buildDetailRow(isFrench ? 'Moyenne par Transaction' : 'Average per Transaction', '1,404 RWF', Colors.orange),
          _buildDetailRow(isFrench ? 'Croissance Mensuelle' : 'Monthly Growth', '+12.5%', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildFinancialMetrics(BuildContext context, bool isFrench) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(context, isFrench ? 'Revenus' : 'Revenue', '125,000 RWF', Icons.attach_money, Colors.green),
        _buildMetricCard(context, isFrench ? 'Dépenses' : 'Expenses', '45,000 RWF', Icons.money_off, Colors.red),
        _buildMetricCard(context, isFrench ? 'Profit' : 'Profit', '80,000 RWF', Icons.trending_up, Colors.blue),
        _buildMetricCard(context, isFrench ? 'Marge' : 'Margin', '64%', Icons.analytics, Colors.orange),
      ],
    );
  }

  Widget _buildCostAnalysis(BuildContext context, bool isFrench) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildDetailRow(isFrench ? 'Coûts d\'Inventaire' : 'Inventory Costs', '25,000 RWF', Colors.red),
          _buildDetailRow(isFrench ? 'Coûts Opérationnels' : 'Operational Costs', '15,000 RWF', Colors.orange),
          _buildDetailRow(isFrench ? 'Coûts Marketing' : 'Marketing Costs', '5,000 RWF', Colors.purple),
          _buildDetailRow(isFrench ? 'Économies Potentielles' : 'Potential Savings', '15,000 RWF', Colors.green),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsGrid(BuildContext context, bool isFrench) {
    if (_analytics == null) return const SizedBox.shrink();

    final totalSales = _analytics!['totalSales'] ?? 0;
    final totalTransactions = _analytics!['totalTransactions'] ?? 0;
    final averageTransaction = _analytics!['averageTransactionValue'] ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          context,
          AppLocalizations.of(context)!.totalSales,
          '${NumberFormat('#,##0').format(totalSales)} RWF',
          Icons.attach_money,
          const Color(0xFFFFD600),
        ),
        _buildMetricCard(
          context,
          AppLocalizations.of(context)!.transactions,
          totalTransactions.toString(),
          Icons.receipt,
          Colors.green,
        ),
        _buildMetricCard(
          context,
          AppLocalizations.of(context)!.avgTransaction,
          '${NumberFormat('#,##0').format(averageTransaction)} RWF',
          Icons.analytics,
          Colors.blue,
        ),
        _buildMetricCard(
          context,
          AppLocalizations.of(context)!.growth,
          '+12.5%',
          Icons.trending_up,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSalesChart(BuildContext context, bool isFrench) {
    if (_analytics == null) return const SizedBox.shrink();

    final dailySales = _analytics!['dailySales'] as Map<String, dynamic>? ?? {};
    final salesData = dailySales.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (salesData.isEmpty) {
      return _buildChartContainer(
        context,
        AppLocalizations.of(context)!.noSalesDataAvailable,
        height: 200,
      );
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD600).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${NumberFormat.compact().format(value)}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < salesData.length) {
                    final date = DateTime.parse(salesData[value.toInt()].key);
                    return Text(
                      DateFormat('MM/dd').format(date),
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: salesData.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
              }).toList(),
              isCurved: true,
              color: const Color(0xFFFFD600),
              barWidth: 3,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimizationStrategies(BuildContext context, bool isFrench) {
    if (_minimizationStrategy == null) return const SizedBox.shrink();

    final strategies = _minimizationStrategy!['strategies'] as Map<String, dynamic>? ?? {};

    return Column(
      children: strategies.entries.map((entry) {
        final strategy = entry.value as Map<String, dynamic>;
        final priority = strategy['priority'] as String? ?? 'medium';
        
        Color priorityColor;
        switch (priority) {
          case 'high':
            priorityColor = Colors.red;
            break;
          case 'medium':
            priorityColor = Colors.orange;
            break;
          default:
            priorityColor = Colors.green;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: priorityColor.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      priority.toUpperCase(),
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      strategy['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                strategy['description'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${AppLocalizations.of(context)!.potentialSavings}: ${strategy['potentialSavings']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${AppLocalizations.of(context)!.implementationTime}: ${strategy['implementationTime']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    
    return Row(
      children: [
        Icon(icon, color: mainColor, size: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: mainColor,
          ),
        ),
      ],
    );
  }

  Widget _buildChartContainer(BuildContext context, String placeholder, {double height = 200}) {
    
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            mainColor.withOpacity(0.1),
            mainColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mainColor.withOpacity(0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: mainColor.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              placeholder,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: mainColor.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, bool isFrench) {
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          context,
          AppLocalizations.of(context)!.totalSales,
          '125,000 RWF',
          Icons.attach_money,
          mainColor,
        ),
        _buildMetricCard(
          context,
          AppLocalizations.of(context)!.activeCustomers,
          '45',
          Icons.people,
          Colors.green,
        ),
        _buildMetricCard(
          context,
          AppLocalizations.of(context)!.productsSold,
          '89',
          Icons.inventory,
          Colors.blue,
        ),
        _buildMetricCard(
          context,
          AppLocalizations.of(context)!.growth,
          '+12.5%',
          Icons.trending_up,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStockTab(BuildContext context) {
    final inStock = _products.where((p) => (p['stock'] ?? 0) > 0).toList();
    final outOfStock = _products.where((p) => (p['stock'] ?? 0) == 0).toList();
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(context, isFrench ? 'Stock' : 'Stock', Icons.inventory),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final lang = Localizations.localeOf(context).languageCode;
                    await _inventoryPrintService.printInventoryReport(_products, lang);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.reportPrintedSuccessfully),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.errorPrinting(e.toString())),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.print),
                label: Text(isFrench ? 'Imprimer' : 'Print'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'In Stock', Icons.check_circle),
          const SizedBox(height: 8),
          inStock.isEmpty
              ? Text('No products in stock.', style: TextStyle(color: Colors.grey))
              : Column(
                  children: inStock.map((product) => _buildProductCard(product, inStock: true)).toList(),
                ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Out of Stock', Icons.error_outline),
          const SizedBox(height: 8),
          outOfStock.isEmpty
              ? Text('No products are out of stock.', style: TextStyle(color: Colors.grey))
              : Column(
                  children: outOfStock.map((product) => _buildProductCard(product, inStock: false)).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, {required bool inStock}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              inStock ? Icons.inventory_2 : Icons.remove_shopping_cart,
              color: inStock ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Category: ${product['category'] ?? '-'}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    inStock
                        ? 'Stock: ${product['stock']} | Price: ${product['price']} RWF'
                        : 'Out of Stock',
                    style: TextStyle(
                      color: inStock ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.w500,
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
} 