import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'add_expense.dart';
import 'budget_screen.dart';
import 'settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'premium_service.dart'; // Added import for PremiumService
import 'upgrade_screen.dart'; // Added import for UpgradeScreen
import 'analytics_screen.dart'; // Added import for AnalyticsScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-5738707488543355/1758724592', // Real ad unit ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _changeMonth(int delta) {
    setState(() {
      selectedMonth += delta;
      if (selectedMonth < 1) {
        selectedMonth = 12;
        selectedYear--;
      } else if (selectedMonth > 12) {
        selectedMonth = 1;
        selectedYear++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BudgetWise Dashboard'),
        backgroundColor: Colors.green[800],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // AuthCheck will handle navigation
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  '${DateFormat.yMMMM().format(DateTime(selectedYear, selectedMonth))}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('budgets')
                  .doc(currentUser!.uid)
                  .collection('user_budgets')
                  .where('month', isEqualTo: selectedMonth)
                  .where('year', isEqualTo: selectedYear)
                  .snapshots(),
              builder: (context, budgetSnapshot) {
                if (budgetSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!budgetSnapshot.hasData || budgetSnapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('expenses')
                      .doc(currentUser!.uid)
                      .collection('user_expenses')
                      .where('month', isEqualTo: selectedMonth)
                      .where('year', isEqualTo: selectedYear)
                      .snapshots(),
                  builder: (context, expenseSnapshot) {
                    if (expenseSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final budgetDocs = budgetSnapshot.data!.docs;
                    final expenseDocs = expenseSnapshot.data?.docs ?? [];

                    double totalBudget = budgetDocs.fold(0.0, (sum, doc) => sum + (doc['amount'] as num));
                    double totalExpenses = expenseDocs.fold(0.0, (sum, doc) => sum + (doc['amount'] as num));
                    double remaining = totalBudget - totalExpenses;
                    double progress = totalBudget > 0 ? (totalExpenses / totalBudget).clamp(0.0, 1.0) : 0;

                    final budgetsByCategory = {for (var doc in budgetDocs) doc['category']: (doc['amount'] as num).toDouble()};
                    final expensesByCategory = <String, double>{};
                    for (var doc in expenseDocs) {
                      final category = doc['category'] as String;
                      final amount = (doc['amount'] as num).toDouble();
                      expensesByCategory[category] = (expensesByCategory[category] ?? 0) + amount;
                    }

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Text(
                              'Welcome,',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              currentUser?.email ?? 'User',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _SummaryCard(
                            totalBudget: totalBudget,
                            totalExpenses: totalExpenses,
                            remaining: remaining,
                            progress: progress,
                          ),
                        ),
                        _QuickActions(),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                            child: Text(
                              'Spending by Category',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final category = budgetsByCategory.keys.elementAt(index);
                              final budgetAmount = budgetsByCategory[category]!;
                              final expenseAmount = expensesByCategory[category] ?? 0.0;
                              return _CategoryProgressCard(
                                category: category,
                                budgetAmount: budgetAmount,
                                spentAmount: expenseAmount,
                              );
                            },
                            childCount: budgetsByCategory.length,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          // Show Ad only if not premium
          FutureBuilder<bool>(
            future: PremiumService.isPremium(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return SizedBox.shrink();
              if (snapshot.data == true) return SizedBox.shrink();
              // Not premium, show ad
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _isAdLoaded && _bannerAd != null
                    ? SizedBox(
                        height: _bannerAd!.size.height.toDouble(),
                        width: _bannerAd!.size.width.toDouble(),
                        child: AdWidget(ad: _bannerAd!),
                      )
                    : SizedBox.shrink(),
              );
            },
          ),
          // Go Premium button (only for non-premium users)
          FutureBuilder<bool>(
            future: PremiumService.isPremium(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return SizedBox.shrink();
              if (snapshot.data == true) return SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.star, color: Colors.amber),
                  label: Text('Go Premium'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpgradeScreen()));
                  },
                ),
              );
            },
          ),
          // Analytics button (only for premium users)
          FutureBuilder<bool>(
            future: PremiumService.isPremium(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return SizedBox.shrink();
              if (snapshot.data != true) return SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.bar_chart, color: Colors.white),
                  label: Text('Analytics & Reports'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
                  },
                ),
              );
            },
          ),
          // Affiliate Button (replaces AdMob banner)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.shopping_cart_outlined),
              label: Text('Shop on Amazon (Affiliate)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[800],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final url = Uri.parse('https://www.amazon.com/dp/B08N5WRWNW?tag=youraffiliateid'); // Replace with your affiliate link
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not launch affiliate link')),
                  );
                }
              },
            ),
          ),
          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Divider(height: 24, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified, color: Colors.green, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'v1.0.0',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 18),
                      Icon(Icons.copyright, color: Colors.grey[600], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '2024 BudgetWise',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Made with',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.favorite, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'by Sandrine',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.money_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No Budgets Found',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Create a budget to get started.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create Budget'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const BudgetScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[800],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double totalBudget;
  final double totalExpenses;
  final double remaining;
  final double progress;

  const _SummaryCard({
    required this.totalBudget,
    required this.totalExpenses,
    required this.remaining,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'RWF ', decimalDigits: 0);
    final isOverBudget = remaining < 0;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: value,
                        strokeWidth: 10,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                            value > 0.8 ? (value >= 1.0 ? Colors.red[700]! : Colors.orange) : Colors.green[600]!),
                      ),
                      Center(
                          child: Text(
                        NumberFormat.percentPattern().format(value),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      )),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Spent', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
                  Text(
                    currencyFormat.format(totalExpenses),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text('Remaining', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
                   Text(
                    currencyFormat.format(remaining),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isOverBudget ? Colors.red[700] : Colors.black87,
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

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _QuickActionCard(
            icon: Icons.add_card_outlined,
            label: 'Add Expense',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const AddExpenseScreen())),
          ),
          _QuickActionCard(
            icon: Icons.category_outlined,
            label: 'My Budgets',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const BudgetScreen())),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.42,
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Colors.green[800]),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryProgressCard extends StatelessWidget {
  final String category;
  final double budgetAmount;
  final double spentAmount;

  const _CategoryProgressCard({
    required this.category,
    required this.budgetAmount,
    required this.spentAmount,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'RWF ', decimalDigits: 0);
    final progress = budgetAmount > 0 ? (spentAmount / budgetAmount).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = spentAmount > budgetAmount;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(category, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  '${currencyFormat.format(spentAmount)} / ${currencyFormat.format(budgetAmount)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: TweenAnimationBuilder<double>(
                 tween: Tween(begin: 0, end: progress),
                 duration: const Duration(milliseconds: 1000),
                 builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 12,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                          value > 0.8 ? (value >= 1.0 ? Colors.red[700]! : Colors.orange) : Colors.green[600]!),
                    );
                 }
              ),
            ),
            if (isOverBudget)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Budget Exceeded',
                      style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
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
