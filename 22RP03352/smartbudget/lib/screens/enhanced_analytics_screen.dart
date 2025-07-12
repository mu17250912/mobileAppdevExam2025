import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/enhanced_analytics_service.dart';
import '../services/accessibility_service.dart';
import '../services/gamification_service.dart';

class EnhancedAnalyticsScreen extends StatefulWidget {
  const EnhancedAnalyticsScreen({super.key});

  @override
  State<EnhancedAnalyticsScreen> createState() => _EnhancedAnalyticsScreenState();
}

class _EnhancedAnalyticsScreenState extends State<EnhancedAnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'month';
  String _selectedCategory = 'all';
  bool _isLoading = false;
  Map<String, dynamic> _analyticsData = {};
  List<Map<String, dynamic>> _expenseHistory = [];
  Map<String, double> _categorySpending = {};
  List<Map<String, dynamic>> _budgetInsights = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalyticsData();
    _initializeAccessibility();
  }

  void _initializeAccessibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AccessibilityService.announceToScreenReader(
        context,
        AccessibilityService.getNavigationGuidance('analytics'),
      );
    });
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    
    try {
      final analyticsService = EnhancedAnalyticsService();
      
      // Load comprehensive analytics data
      _analyticsData = await analyticsService.getComprehensiveAnalytics(_selectedPeriod);
      _expenseHistory = await analyticsService.getExpenseHistory(_selectedPeriod);
      _categorySpending = await analyticsService.getCategorySpending(_selectedPeriod);
      _budgetInsights = await analyticsService.getBudgetInsights(_selectedPeriod);
      
      // Update gamification progress
      await GamificationService.updateAnalyticsProgress(_analyticsData);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: AccessibilityService.getSemanticLabel('analytics_screen'),
          child: Text('Enhanced Analytics'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
            tooltip: 'Refresh analytics',
          ),
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _exportAnalyticsData,
            tooltip: 'Export data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Spending'),
            Tab(text: 'Trends'),
            Tab(text: 'Insights'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildSpendingTab(),
                _buildTrendsTab(),
                _buildInsightsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          SizedBox(height: 24),
          _buildQuickInsights(),
          SizedBox(height: 24),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalSpent = _analyticsData['totalSpent'] ?? 0.0;
    final budget = _analyticsData['budget'] ?? 0.0;
    final savings = _analyticsData['savings'] ?? 0.0;
    final avgDaily = _analyticsData['avgDailySpending'] ?? 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSummaryCard('Total Spent', '\$${totalSpent.toStringAsFixed(2)}', Colors.red)),
            SizedBox(width: 12),
            Expanded(child: _buildSummaryCard('Budget', '\$${budget.toStringAsFixed(2)}', Colors.blue)),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSummaryCard('Savings', '\$${savings.toStringAsFixed(2)}', Colors.green)),
            SizedBox(width: 12),
            Expanded(child: _buildSummaryCard('Daily Avg', '\$${avgDaily.toStringAsFixed(2)}', Colors.orange)),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInsights() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            ...(_analyticsData['insights'] as List<dynamic>? ?? []).map((insight) => 
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.amber, size: 16),
                    SizedBox(width: 8),
                    Expanded(child: Text(insight.toString())),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            ..._expenseHistory.take(5).map((expense) => 
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: Icon(Icons.receipt, color: Colors.grey[600]),
                ),
                title: Text(expense['description'] ?? 'Unknown'),
                subtitle: Text(expense['category'] ?? 'Uncategorized'),
                trailing: Text('\$${(expense['amount'] ?? 0.0).toStringAsFixed(2)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCategoryPieChart(),
          SizedBox(height: 24),
          _buildCategoryList(),
        ],
      ),
    );
  }

  Widget _buildCategoryPieChart() {
    if (_categorySpending.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No spending data available')),
        ),
      );
    }

    final sections = _categorySpending.entries.map((entry) {
      final color = _getCategoryColor(entry.key);
      return PieChartSectionData(
        value: entry.value,
        title: '${entry.key}\n\$${entry.value.toStringAsFixed(2)}',
        color: color,
        radius: 100,
        titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Spending by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    final sortedCategories = _categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 4,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text('Category Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...sortedCategories.map((entry) => 
            ListTile(
              leading: CircleAvatar(backgroundColor: _getCategoryColor(entry.key)),
              title: Text(entry.key),
              subtitle: LinearProgressIndicator(
                value: entry.value / _categorySpending.values.reduce((a, b) => a + b),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(entry.key)),
              ),
              trailing: Text('\$${entry.value.toStringAsFixed(2)}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSpendingTrendChart(),
          SizedBox(height: 24),
          _buildBudgetVsActualChart(),
        ],
      ),
    );
  }

  Widget _buildSpendingTrendChart() {
    final trendData = _analyticsData['trendData'] as List<dynamic>? ?? [];
    
    if (trendData.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No trend data available')),
        ),
      );
    }

    final spots = trendData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), (entry.value['amount'] ?? 0.0).toDouble());
    }).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Spending Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetVsActualChart() {
    final budget = _analyticsData['budget'] ?? 0.0;
    final actual = _analyticsData['totalSpent'] ?? 0.0;
    final percentage = budget > 0 ? (actual / budget) : 0.0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Budget vs Actual', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('Budget', style: TextStyle(fontSize: 14)),
                      Text('\$${budget.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('Actual', style: TextStyle(fontSize: 14)),
                      Text('\$${actual.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage > 1.0 ? Colors.red : Colors.green,
              ),
            ),
            SizedBox(height: 8),
            Text('${(percentage * 100).toStringAsFixed(1)}% of budget used'),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSmartRecommendations(),
          SizedBox(height: 24),
          _buildSavingsOpportunities(),
          SizedBox(height: 24),
          _buildFinancialGoals(),
        ],
      ),
    );
  }

  Widget _buildSmartRecommendations() {
    final recommendations = _analyticsData['recommendations'] as List<dynamic>? ?? [];
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            ...recommendations.map((rec) => 
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.recommend, color: Colors.blue, size: 20),
                    SizedBox(width: 12),
                    Expanded(child: Text(rec.toString())),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsOpportunities() {
    final opportunities = _analyticsData['savingsOpportunities'] as List<dynamic>? ?? [];
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Savings Opportunities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            ...opportunities.map((opp) => 
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.savings, color: Colors.green, size: 20),
                    SizedBox(width: 12),
                    Expanded(child: Text(opp.toString())),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialGoals() {
    final goals = _analyticsData['financialGoals'] as List<dynamic>? ?? [];
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Financial Goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            ...goals.map((goal) => 
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.flag, color: Colors.orange, size: 20),
                    SizedBox(width: 12),
                    Expanded(child: Text(goal.toString())),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Food': Colors.red,
      'Transport': Colors.blue,
      'Entertainment': Colors.purple,
      'Shopping': Colors.pink,
      'Bills': Colors.orange,
      'Healthcare': Colors.green,
      'Education': Colors.indigo,
      'Other': Colors.grey,
    };
    return colors[category] ?? Colors.grey;
  }

  Future<void> _exportAnalyticsData() async {
    try {
      final analyticsService = EnhancedAnalyticsService();
      final success = await analyticsService.exportAnalyticsData(_selectedPeriod);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analytics data exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
} 