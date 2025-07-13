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
import 'enhanced_analytics_screen.dart'; // Added import for EnhancedAnalyticsScreen
import 'downgrade_screen.dart'; // Added import for DowngradeScreen
import 'package:flutter/foundation.dart';
import '../services/analytics_service.dart'; // Added import for AnalyticsService
import '../main.dart'; // For selectedMonthYear
import 'package:shared_preferences/shared_preferences.dart';
import '../services/accessibility_service.dart'; // Import accessibility service

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  String? displayName;
  final Set<String> _notified80 = {};
  final Set<String> _notified100 = {};
  final List<_BudgetNotification> _notifications = [];
  int _unreadNotifications = 0;
  Key _premiumStatusKeyAd = UniqueKey();
  Key _premiumStatusKeyActions = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _fetchDisplayName();
    _initializeAnalytics();
  }

  void _initializeAccessibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AccessibilityService.announceToScreenReader(
        context,
        AccessibilityService.getNavigationGuidance('home'),
      );
    });
  }

  void _refreshPremiumStatus() {
    setState(() {
      _premiumStatusKeyAd = UniqueKey();
      _premiumStatusKeyActions = UniqueKey();
    });
  }

  Future<void> _initializeAnalytics() async {
    await AnalyticsService.setUserProperties();
    await AnalyticsService.logScreenView(screenName: 'home_screen');
    await AnalyticsService.logAppOpen();
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

  Future<void> _fetchDisplayName() async {
    if (currentUser == null) return;
    String? name = currentUser!.displayName;
    if (name == null || name.isEmpty) {
      // Try Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
      final data = doc.data();
      if (data != null && data['displayName'] != null && (data['displayName'] as String).isNotEmpty) {
        name = data['displayName'];
      }
    }
    setState(() {
      displayName = name;
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _changeMonth(int delta) {
    final current = selectedMonthYear.value;
    int month = current.month + delta;
    int year = current.year;
    if (month < 1) {
      month = 12;
      year--;
    } else if (month > 12) {
      month = 1;
      year++;
    }
    selectedMonthYear.value = DateTime(year, month);
  }

  void _addNotification(String title, String body) {
    setState(() {
      _notifications.insert(0, _BudgetNotification(title, body, DateTime.now()));
      _unreadNotifications++;
    });
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notifications'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _notifications.isEmpty
              ? Center(child: Text('No notifications'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return ListTile(
                      title: Text(notification.title),
                      subtitle: Text(notification.body),
                      trailing: Text(
                        DateFormat('MMM dd, HH:mm').format(notification.timestamp),
                        style: TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _notifications.clear();
                _unreadNotifications = 0;
              });
              Navigator.of(context).pop();
            },
            child: Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAnalyticsOptions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Choose Analytics Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.bar_chart, color: Colors.blue),
                title: Text('Basic Analytics'),
                subtitle: Text('Simple charts and reports'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
                },
              ),
              ListTile(
                leading: Icon(Icons.analytics, color: Colors.green),
                title: Text('Enhanced Analytics'),
                subtitle: Text('Advanced insights and AI recommendations'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EnhancedAnalyticsScreen()));
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: selectedMonthYear,
      builder: (context, selectedDate, _) {
        final selectedMonth = selectedDate.month;
        final selectedYear = selectedDate.year;
        return Scaffold(
          appBar: AppBar(
            title: Semantics(
              label: AccessibilityService.getSemanticLabel('app_title'),
              child: const Text('BudgetWise Dashboard'),
            ),
            backgroundColor: Colors.green[800],
            elevation: 0,
            actions: [
              // Notification bell
              Stack(
                children: [
                  Semantics(
                    label: AccessibilityService.getSemanticLabel('notifications_button'),
                    hint: AccessibilityService.getAccessibilityHint('view_notifications'),
                    child: IconButton(
                      icon: Icon(Icons.notifications, color: Colors.white),
                      tooltip: 'Notifications',
                      onPressed: _showNotificationsDialog,
                    ),
                  ),
                  if (_unreadNotifications > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${_unreadNotifications}',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              // User avatar with tooltip
              if (currentUser != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Semantics(
                    label: AccessibilityService.getSemanticLabel('user_profile'),
                    child: Tooltip(
                      message: displayName != null && displayName!.isNotEmpty
                          ? displayName!
                          : (currentUser?.email ?? 'User'),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Colors.green[800], size: 20),
                      ),
                    ),
                  ),
                ),
              Semantics(
                label: AccessibilityService.getSemanticLabel('settings_button'),
                hint: AccessibilityService.getAccessibilityHint('open_settings'),
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  tooltip: 'Settings',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ),
              Semantics(
                label: AccessibilityService.getSemanticLabel('logout_button'),
                hint: AccessibilityService.getAccessibilityHint('logout'),
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Logout',
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    // AuthCheck will handle navigation
                  },
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            children: [
              // Month selector
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.green[50],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Semantics(
                      label: AccessibilityService.getSemanticLabel('previous_month'),
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _changeMonth(-1),
                      ),
                    ),
                    Semantics(
                      label: AccessibilityService.getSemanticLabel('current_month'),
                      child: Text(
                        DateFormat('MMMM yyyy').format(selectedDate),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Semantics(
                      label: AccessibilityService.getSemanticLabel('next_month'),
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _changeMonth(1),
                      ),
                    ),
                  ],
                ),
              ),
              // Main content
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

                        final budgetDocs = budgetSnapshot.data?.docs ?? [];
                        final expenseDocs = expenseSnapshot.data?.docs ?? [];

                        double totalBudget = 0;
                        double totalExpenses = 0;

                        for (var doc in budgetDocs) {
                          totalBudget += (doc['amount'] as num).toDouble();
                        }

                        for (var doc in expenseDocs) {
                          totalExpenses += (doc['amount'] as num).toDouble();
                        }

                        final remaining = totalBudget - totalExpenses;
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
                              child: _SummaryCard(
                                totalBudget: totalBudget,
                                totalExpenses: totalExpenses,
                                remaining: remaining,
                                progress: totalBudget > 0 ? (totalExpenses / totalBudget).clamp(0.0, 1.0) : 0,
                              ),
                            ),
                            _QuickActions(
                              selectedMonth: selectedMonth,
                              selectedYear: selectedYear,
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 6), // Reduced from 24, 8
                                child: Text(
                                  'Spending by Category',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 16), // Reduced font size
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final category = budgetsByCategory.keys.elementAt(index);
                                    final budgetAmount = budgetsByCategory[category] ?? 0;
                                    final expenseAmount = expensesByCategory[category] ?? 0;

                                    // Budget notifications
                                    if (budgetAmount > 0 && expenseAmount >= budgetAmount * 0.8 && expenseAmount < budgetAmount && !_notified80.contains(category)) {
                                      NotificationHelper.showNotification(
                                        title: 'Budget Alert',
                                        body: "You've used 80% of your $category budget!",
                                      );
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        _addNotification('Budget Alert', "You've used 80% of your $category budget!");
                                      });
                                      _notified80.add(category);
                                    }

                                    if (budgetAmount > 0 && expenseAmount >= budgetAmount && !_notified100.contains(category)) {
                                      NotificationHelper.showNotification(
                                        title: 'Budget Exceeded',
                                        body: "You've exceeded your $category budget!",
                                      );
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        _addNotification('Budget Exceeded', "You've exceeded your $category budget!");
                                      });
                                      _notified100.add(category);
                                    }
                                    
                                    return _CategoryProgressCard(
                                      category: category,
                                      budgetAmount: budgetAmount,
                                      spentAmount: expenseAmount,
                                    );
                                  },
                                  childCount: budgetsByCategory.length,
                                ),
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
                key: _premiumStatusKeyAd,
                future: PremiumService.isPremium(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return SizedBox.shrink();
                  if (snapshot.data == true) return SizedBox.shrink();
                  // Not premium, show ad
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0), // Reduced from 8.0
                    child: _isAdLoaded && _bannerAd != null
                        ? Semantics(
                            label: AccessibilityService.getSemanticLabel('advertisement'),
                            child: SizedBox(
                              height: _bannerAd!.size.height.toDouble(),
                              width: _bannerAd!.size.width.toDouble(),
                              child: AdWidget(ad: _bannerAd!),
                            ),
                          )
                        : SizedBox.shrink(),
                  );
                },
              ),
              // Replace individual button paddings with a grouped card
              FutureBuilder<bool>(
                key: _premiumStatusKeyActions,
                future: PremiumService.isPremium(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return SizedBox.shrink();
                  final isPremium = snapshot.data ?? false;
                  
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 500;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: isWide
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // Show "Go Premium" button if not premium, or "Downgrade" if premium
                                    if (!isPremium)
                                      _ActionButton(
                                        icon: Icons.star,
                                        label: 'Go Premium',
                                        color: Colors.green[800]!,
                                        onPressed: () async {
                                          await AnalyticsService.logFeatureUsage(featureName: 'go_premium_button');
                                          final result = await Navigator.of(context).push<bool>(
                                            MaterialPageRoute(builder: (_) => const UpgradeScreen())
                                          );
                                          if (result == true) {
                                            // Refresh the UI after upgrade
                                            _refreshPremiumStatus();
                                          }
                                        },
                                      )
                                    else
                                      _ActionButton(
                                        icon: Icons.info_outline,
                                        label: 'Downgrade',
                                        color: Colors.orange[700]!,
                                        onPressed: () async {
                                          await AnalyticsService.logFeatureUsage(featureName: 'downgrade_button');
                                          final result = await Navigator.of(context).push<bool>(
                                            MaterialPageRoute(builder: (_) => const DowngradeScreen())
                                          );
                                          if (result == true) {
                                            // Refresh the UI after downgrade
                                            _refreshPremiumStatus();
                                          }
                                        },
                                      ),
                                    _ActionButton(
                                      icon: Icons.bar_chart,
                                      label: 'Analytics & Reports',
                                      color: Colors.green[700]!,
                                      onPressed: () async {
                                        await AnalyticsService.logFeatureUsage(featureName: 'analytics_button');
                                        _showAnalyticsOptions();
                                      },
                                    ),
                                    // Only show "Shop on Amazon" button if not premium
                                    if (!isPremium)
                                      _ActionButton(
                                        icon: Icons.shopping_cart_outlined,
                                        label: 'Shop on Amazon',
                                        color: Colors.orange[800]!,
                                        onPressed: () async {
                                          await AnalyticsService.logAdInteraction(adType: 'affiliate', action: 'clicked');
                                          final url = Uri.parse('https://www.amazon.com/dp/B08N5WRWNW?tag=youraffiliateid');
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url, mode: LaunchMode.externalApplication);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Could not launch affiliate link')),
                                            );
                                          }
                                        },
                                      ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    // Show "Go Premium" button if not premium, or "Downgrade" if premium
                                    if (!isPremium) ...[
                                      _ActionButton(
                                        icon: Icons.star,
                                        label: 'Go Premium',
                                        color: Colors.green[800]!,
                                        onPressed: () async {
                                          await AnalyticsService.logFeatureUsage(featureName: 'go_premium_button');
                                          final result = await Navigator.of(context).push<bool>(
                                            MaterialPageRoute(builder: (_) => const UpgradeScreen())
                                          );
                                          if (result == true) {
                                            // Refresh the UI after upgrade
                                            _refreshPremiumStatus();
                                          }
                                        },
                                      ),
                                      SizedBox(height: 8),
                                    ] else ...[
                                      _ActionButton(
                                        icon: Icons.info_outline,
                                        label: 'Downgrade',
                                        color: Colors.orange[700]!,
                                        onPressed: () async {
                                          await AnalyticsService.logFeatureUsage(featureName: 'downgrade_button');
                                          final result = await Navigator.of(context).push<bool>(
                                            MaterialPageRoute(builder: (_) => const DowngradeScreen())
                                          );
                                          if (result == true) {
                                            // Refresh the UI after downgrade
                                            _refreshPremiumStatus();
                                          }
                                        },
                                      ),
                                      SizedBox(height: 8),
                                    ],
                                    _ActionButton(
                                      icon: Icons.bar_chart,
                                      label: 'Analytics & Reports',
                                      color: Colors.green[700]!,
                                      onPressed: () async {
                                        await AnalyticsService.logFeatureUsage(featureName: 'analytics_button');
                                        _showAnalyticsOptions();
                                      },
                                    ),
                                    // Only show "Shop on Amazon" button if not premium
                                    if (!isPremium) ...[
                                      SizedBox(height: 8),
                                      _ActionButton(
                                        icon: Icons.shopping_cart_outlined,
                                        label: 'Shop on Amazon',
                                        color: Colors.orange[800]!,
                                        onPressed: () async {
                                          await AnalyticsService.logAdInteraction(adType: 'affiliate', action: 'clicked');
                                          final url = Uri.parse('https://www.amazon.com/dp/B08N5WRWNW?tag=youraffiliateid');
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url, mode: LaunchMode.externalApplication);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Could not launch affiliate link')),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                      );
                    },
                  );
                },
              ),
              // Analytics Test Button (Debug Mode Only)
              if (kDebugMode)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      await AnalyticsService.testAnalytics();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Analytics test completed! Check console for details.')),
                      );
                    },
                    child: const Text('Test Analytics (Debug)'),
                  ),
                ),
              // Footer
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0), // Very compact padding
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, color: Colors.green, size: 14),
                    const SizedBox(width: 3),
                    Text('v1.0.0', style: TextStyle(color: Colors.grey[700], fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Icon(Icons.copyright, color: Colors.grey[600], size: 12),
                    const SizedBox(width: 2),
                    Text('2024 BudgetWise', style: TextStyle(color: Colors.grey[700], fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Icon(Icons.favorite, color: Colors.redAccent, size: 12),
                    const SizedBox(width: 2),
                    Text('by Sandrine', style: TextStyle(color: Colors.grey[700], fontSize: 10, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.money_off, size: 60, color: Colors.grey), // Reduced from 80
          const SizedBox(height: 12), // Reduced from 16
          const Text(
            'No Budgets Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // Reduced from 22
          ),
          const SizedBox(height: 6), // Reduced from 8
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32), // Reduced from 40
            child: Text(
              'Create a budget to get started.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]), // Reduced from 16
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16), // Reduced from 24
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18), // Added size
            label: const Text('Create Budget'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const BudgetScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[800],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // Reduced from 24, 12
              textStyle: TextStyle(fontSize: 14), // Added fontSize
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
      margin: const EdgeInsets.all(8), // Reduced from 12
      elevation: 4, // Reduced from 6
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Reduced from 12
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Reduced from 16.0
        child: Row(
          children: [
            SizedBox(
              width: 56, // Reduced from 80
              height: 56, // Reduced from 80
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
                        strokeWidth: 5, // Reduced from 8
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                            value > 0.8 ? (value >= 1.0 ? Colors.red[700]! : Colors.orange) : Colors.green[600]!),
                      ),
                      Center(
                          child: Text(
                        NumberFormat.percentPattern().format(value),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), // Reduced from 16
                      )),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 8), // Reduced from 16
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Spent', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600], fontSize: 12)),
                  Text(
                    currencyFormat.format(totalExpenses),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4), // Reduced from 8
                  Text('Remaining', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600], fontSize: 12)),
                  Text(
                    currencyFormat.format(remaining),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isOverBudget ? Colors.red[700] : Colors.black87,
                        fontSize: 12,
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
  final int selectedMonth;
  final int selectedYear;
  const _QuickActions({Key? key, required this.selectedMonth, required this.selectedYear}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12), // Added horizontal padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _QuickActionCard(
              icon: Icons.add_card_outlined,
              label: 'Add Expense',
              onTap: () async {
                await AnalyticsService.logFeatureUsage(featureName: 'add_expense_button');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => AddExpenseScreen(
                      selectedMonth: selectedMonth,
                      selectedYear: selectedYear,
                    ),
                  ),
                );
              },
            ),
            _QuickActionCard(
              icon: Icons.category_outlined,
              label: 'My Budgets',
              onTap: () async {
                await AnalyticsService.logFeatureUsage(featureName: 'my_budgets_button');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => BudgetScreen(
                      selectedMonth: selectedMonth,
                      selectedYear: selectedYear,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Reduced from 16
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12), // Reduced from 16
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.42,
          height: 80, // Reduced from 100
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: Colors.green[800]), // Reduced from 36
              const SizedBox(height: 6), // Reduced from 8
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), // Added fontSize
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // Reduced from 16, 6
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Reduced from 12
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Reduced from 16.0
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(category, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // Reduced from 18
                Text(
                  '${currencyFormat.format(spentAmount)} / ${currencyFormat.format(budgetAmount)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey), // Reduced from 14
                ),
              ],
            ),
            const SizedBox(height: 8), // Reduced from 12
            ClipRRect(
              borderRadius: BorderRadius.circular(8), // Reduced from 10
              child: TweenAnimationBuilder<double>(
                 tween: Tween(begin: 0, end: progress),
                 duration: const Duration(milliseconds: 1000),
                 builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 8, // Reduced from 12
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                          value > 0.8 ? (value >= 1.0 ? Colors.red[700]! : Colors.orange) : Colors.green[600]!),
                    );
                 }
              ),
            ),
            if (isOverBudget)
              Padding(
                padding: const EdgeInsets.only(top: 6.0), // Reduced from 8.0
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 14), // Reduced from 16
                    const SizedBox(width: 3), // Reduced from 4
                    Text(
                      'Budget Exceeded',
                      style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 12), // Added fontSize
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 44,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class _BudgetNotification {
  final String title;
  final String body;
  final DateTime timestamp;
  _BudgetNotification(this.title, this.body, this.timestamp);
}
