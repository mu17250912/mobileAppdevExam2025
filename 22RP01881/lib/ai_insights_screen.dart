import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'premium_features_summary.dart';

class AIInsightsScreen extends StatefulWidget {
  final void Function(int)? onRequirePremium;
  const AIInsightsScreen({super.key, this.onRequirePremium});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _insights = {};
  String _selectedPeriod = 'This Month';
  bool _isPremium = false;
  final PremiumFeaturesManager _premiumManager = PremiumFeaturesManager();
  bool _aiInsightsUnlocked = false;

  @override
  void initState() {
    super.initState();
    _loadInsights();
    _checkAIInsightsUnlocked();
  }

  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get income and expense data
        final incomeQuery = await FirebaseFirestore.instance
            .collection('income')
            .where('userId', isEqualTo: user.uid)
            .get();
        
        final expenseQuery = await FirebaseFirestore.instance
            .collection('expenses')
            .where('userId', isEqualTo: user.uid)
            .get();

        // Process data for insights
        double totalIncome = 0;
        double totalExpense = 0;
        Map<String, double> categoryExpenses = {};
        Map<String, int> categoryFrequency = {};
        List<Map<String, dynamic>> recentTransactions = [];

        for (var doc in incomeQuery.docs) {
          final amount = double.tryParse(doc['amount'].toString()) ?? 0;
          totalIncome += amount;
          
          recentTransactions.add({
            'type': 'income',
            'amount': amount,
            'date': doc['date'] as Timestamp?,
            'description': doc['description'] ?? '',
          });
        }

        for (var doc in expenseQuery.docs) {
          final amount = double.tryParse(doc['amount'].toString()) ?? 0;
          totalExpense += amount;
          
          final category = doc['category'] ?? 'Other';
          categoryExpenses[category] = (categoryExpenses[category] ?? 0) + amount;
          categoryFrequency[category] = (categoryFrequency[category] ?? 0) + 1;
          
          recentTransactions.add({
            'type': 'expense',
            'amount': amount,
            'date': doc['date'] as Timestamp?,
            'description': doc['description'] ?? '',
            'category': category,
          });
        }

        // Sort recent transactions by date
        recentTransactions.sort((a, b) {
          final dateA = a['date'] as Timestamp?;
          final dateB = b['date'] as Timestamp?;
          if (dateA == null || dateB == null) return 0;
          return dateB.toDate().compareTo(dateA.toDate());
        });

        // Generate AI insights
        final insights = _generateInsights(
          totalIncome,
          totalExpense,
          categoryExpenses,
          categoryFrequency,
          recentTransactions,
        );

        setState(() {
          _insights = insights;
        });
      }
    } catch (e) {
      print('Error loading insights: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkAIInsightsUnlocked() async {
    final unlocked = await _premiumManager.isFeatureUnlocked('aiInsights');
    setState(() {
      _aiInsightsUnlocked = unlocked;
    });
  }

  Future<bool> _tryAccessFeature() async {
    if (!_aiInsightsUnlocked) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Unlock AI Insights'),
            content: const Text('AI Insights is a premium feature. Please pay to unlock this feature.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _premiumManager.unlockFeature('aiInsights');
                  await _checkAIInsightsUnlocked();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('AI Insights unlocked!', style: Theme.of(context).textTheme.bodyMedium),
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                      ),
                    );
                  }
                },
                child: const Text('Pay & Unlock'),
              ),
            ],
          ),
        );
      }
      return false;
    }
    return true;
  }

  Map<String, dynamic> _generateInsights(
    double totalIncome,
    double totalExpense,
    Map<String, double> categoryExpenses,
    Map<String, int> categoryFrequency,
    List<Map<String, dynamic>> recentTransactions,
  ) {
    final netSavings = totalIncome - totalExpense;
    final savingsRate = totalIncome > 0 ? (netSavings / totalIncome * 100) : 0;
    
    // Find top spending categories
    final sortedCategories = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topCategory = sortedCategories.isNotEmpty ? sortedCategories.first.key : 'None';
    final topCategoryAmount = sortedCategories.isNotEmpty ? sortedCategories.first.value : 0.0;
    
    // Analyze spending patterns
    final avgTransactionAmount = recentTransactions.isNotEmpty 
        ? recentTransactions.map((t) => t['amount'] as double).reduce((a, b) => a + b) / recentTransactions.length
        : 0.0;
    
    final highValueTransactions = recentTransactions
        .where((t) => t['amount'] > avgTransactionAmount * 1.5)
        .length;
    
    // Generate insights
    List<Map<String, dynamic>> insights = [];
    
    // Savings insights
    if (savingsRate >= 20) {
      insights.add({
        'type': 'positive',
        'title': 'Excellent Savings Rate!',
        'description': 'You\'re saving ${savingsRate.toStringAsFixed(1)}% of your income, which is above the recommended 20%. Keep up the great work!',
        'icon': Icons.thumb_up,
        'color': Colors.green,
      });
    } else if (savingsRate > 0) {
      insights.add({
        'type': 'warning',
        'title': 'Room for Improvement',
        'description': 'Your savings rate is ${savingsRate.toStringAsFixed(1)}%. Consider increasing it to 20% for better financial security.',
        'icon': Icons.trending_up,
        'color': Colors.orange,
      });
    } else {
      insights.add({
        'type': 'critical',
        'title': 'Spending More Than Income',
        'description': 'You\'re spending more than you earn. Consider reviewing your expenses and creating a budget.',
        'icon': Icons.warning,
        'color': Colors.red,
      });
    }
    
    // Category insights
    if (topCategoryAmount > totalIncome * 0.3) {
      insights.add({
        'type': 'warning',
        'title': 'High Category Spending',
        'description': '$topCategory accounts for ${(topCategoryAmount / totalIncome * 100).toStringAsFixed(1)}% of your income. Consider setting a budget limit.',
        'icon': Icons.category,
        'color': Colors.orange,
      });
    }
    
    // Transaction frequency insights
    if (recentTransactions.length > 50) {
      insights.add({
        'type': 'info',
        'title': 'High Transaction Volume',
        'description': 'You have ${recentTransactions.length} recent transactions. Consider consolidating small purchases.',
        'icon': Icons.receipt_long,
        'color': Colors.blue,
      });
    }
    
    // High-value transaction insights
    if (highValueTransactions > 0) {
      insights.add({
        'type': 'info',
        'title': 'Large Transactions Detected',
        'description': 'You have $highValueTransactions transactions above average. Review if these are necessary expenses.',
        'icon': Icons.attach_money,
        'color': Colors.purple,
      });
    }
    
    // Spending pattern insights
    if (categoryFrequency.length > 8) {
      insights.add({
        'type': 'positive',
        'title': 'Good Category Diversity',
        'description': 'You\'re using ${categoryFrequency.length} different categories, showing good spending organization.',
        'icon': Icons.diversity_3,
        'color': Colors.green,
      });
    }
    
    // Recommendations
    List<Map<String, dynamic>> recommendations = [];
    
    if (savingsRate < 20) {
      recommendations.add({
        'title': 'Increase Savings',
        'description': 'Try to save at least 20% of your income. Start with small amounts and gradually increase.',
        'action': 'Set up automatic transfers to a savings account.',
      });
    }
    
    if (topCategoryAmount > totalIncome * 0.3) {
      recommendations.add({
        'title': 'Budget for $topCategory',
        'description': 'Set a monthly budget limit for $topCategory to control spending.',
        'action': 'Create a specific budget category with spending alerts.',
      });
    }
    
    if (recentTransactions.length > 50) {
      recommendations.add({
        'title': 'Reduce Small Purchases',
        'description': 'Small frequent purchases can add up quickly.',
        'action': 'Wait 24 hours before making non-essential purchases.',
      });
    }
    
    if (netSavings < 0) {
      recommendations.add({
        'title': 'Emergency Fund',
        'description': 'Build an emergency fund to cover 3-6 months of expenses.',
        'action': 'Start with a small monthly contribution.',
      });
    }
    
    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'netSavings': netSavings,
      'savingsRate': savingsRate,
      'topCategory': topCategory,
      'topCategoryAmount': topCategoryAmount,
      'categoryExpenses': categoryExpenses,
      'insights': insights,
      'recommendations': recommendations,
      'recentTransactions': recentTransactions.take(10).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text(
          'AI Spending Insights',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: _loadInsights,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _insights.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.psychology,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'AI-Powered Analysis',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Personalized insights based on your spending patterns',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Key Metrics
                      Text(
                        'Key Metrics',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              'Savings Rate',
                              '${_insights['savingsRate']?.toStringAsFixed(1) ?? '0'}%',
                              Icons.savings,
                              _insights['savingsRate'] >= 20 ? Colors.green : Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              'Net Savings',
                              '${_insights['netSavings']?.toStringAsFixed(0) ?? '0'} FRW',
                              Icons.trending_up,
                              _insights['netSavings'] >= 0 ? Colors.blue : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              'Top Category',
                              _insights['topCategory'] ?? 'None',
                              Icons.category,
                              Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              'Category Spending',
                              '${_insights['topCategoryAmount']?.toStringAsFixed(0) ?? '0'} FRW',
                              Icons.attach_money,
                              Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // AI Insights
                      Text(
                        'AI Insights',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...(_insights['insights'] as List<dynamic>).map((insight) => 
                        _buildInsightCard(insight),
                      ),
                      const SizedBox(height: 24),

                      // Recommendations
                      Text(
                        'Personalized Recommendations',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...(_insights['recommendations'] as List<dynamic>).map((rec) => 
                        _buildRecommendationCard(rec),
                      ),
                      const SizedBox(height: 24),

                      // Recent Activity
                      Text(
                        'Recent Activity',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...(_insights['recentTransactions'] as List<dynamic>).take(5).map((transaction) => 
                        _buildTransactionCard(transaction),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Data Available',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some income and expenses to get AI-powered insights',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: insight['color'].withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: insight['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              insight['icon'],
              color: insight['color'],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['title'],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight['description'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                recommendation['title'],
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation['description'],
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.touch_app,
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation['action'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.secondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final isIncome = transaction['type'] == 'income';
    final amount = transaction['amount'] as double;
    final date = transaction['date'] as Timestamp?;
    final description = transaction['description'] as String? ?? '';
    final category = transaction['category'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isIncome ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIncome ? Icons.add : Icons.remove,
              color: isIncome ? Colors.green : Colors.red,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description.isNotEmpty ? description : (isIncome ? 'Income' : category),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                if (date != null)
                  Text(
                    '${date.toDate().day}/${date.toDate().month}/${date.toDate().year}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${amount.toStringAsFixed(0)} FRW',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
} 