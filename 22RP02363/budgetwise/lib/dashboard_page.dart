import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'budget_page.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool showLastPurchase = true;
  // BannerAd? _bannerAd;
  // bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    // Temporarily disabled Mobile Ads to prevent crashes
    // if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    //   _bannerAd = BannerAd(
    //     adUnitId: 'ca-app-pub-3940256099942544/6300978111',
    //     request: const AdRequest(),
    //     size: AdSize.banner,
    //     listener: BannerAdListener(
    //       onAdLoaded: (_) {
    //         setState(() {
    //           _isBannerAdReady = true;
    //         });
    //       },
    //       onAdFailedToLoad: (ad, error) {
    //         ad.dispose();
    //       },
    //     ),
    //   )..load();
    // }
  }

  @override
  void dispose() {
    // _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF43A047),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.savings, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            const Text('BudgetWise', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Last purchase summary
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseAuth.instance.currentUser == null
                      ? const Stream.empty()
                      : FirebaseFirestore.instance
                          .collection('expenses')
                          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                          .orderBy('date', descending: true)
                          .limit(1)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!showLastPurchase || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final doc = snapshot.data!.docs.first;
                    final data = doc.data() as Map<String, dynamic>;
                    final lastAmount = data['amount'] ?? 0;
                    final lastItem = data['note'] ?? data['category'] ?? '';
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseAuth.instance.currentUser == null
                          ? const Stream.empty()
                          : FirebaseFirestore.instance
                              .collection('budgets')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .snapshots(),
                      builder: (context, budgetSnap) {
                        if (!budgetSnap.hasData) return const SizedBox.shrink();
                        final budgetData = budgetSnap.data!.data() as Map<String, dynamic>?;
                        final income = (budgetData?['income'] ?? 0).toDouble();
                        // Calculate remaining
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('expenses')
                              .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                              .snapshots(),
                          builder: (context, expSnap) {
                            if (!expSnap.hasData) return const SizedBox.shrink();
                            double totalSpent = 0;
                            for (var d in expSnap.data!.docs) {
                              final dd = d.data() as Map<String, dynamic>;
                              final amt = dd['amount'];
                              if (amt is int) {
                                totalSpent += amt.toDouble();
                              } else if (amt is double) {
                                totalSpent += amt;
                              } else if (amt is String) {
                                totalSpent += double.tryParse(amt) ?? 0.0;
                              }
                            }
                            final remaining = income - totalSpent;
                            return Dismissible(
                              key: ValueKey(doc.id + remaining.toString()),
                              direction: DismissDirection.horizontal,
                              onDismissed: (_) => setState(() => showLastPurchase = false),
                              child: Card(
                                color: Colors.green[50],
                                margin: const EdgeInsets.only(bottom: 18),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline, color: Colors.green, size: 28),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'You just spent RWF ${lastAmount.toStringAsFixed(0)} on $lastItem.',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Remaining balance: RWF ${remaining.toStringAsFixed(0)}',
                                              style: const TextStyle(fontSize: 15, color: Colors.black87),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.green),
                                        onPressed: () => setState(() => showLastPurchase = false),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Dashboard',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your financial overview',
                  style: TextStyle(fontSize: 18, color: Colors.black54, letterSpacing: 0.2),
                ),
                const SizedBox(height: 40),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseAuth.instance.currentUser == null
                      ? const Stream.empty()
                      : FirebaseFirestore.instance
                          .collection('expenses')
                          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                          .snapshots(),
                  builder: (context, expenseSnapshot) {
                    final user = FirebaseAuth.instance.currentUser;
                    print('Current userId: \\${user?.uid}');
                    if (expenseSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (expenseSnapshot.hasError) {
                      print('Expense snapshot error: \\${expenseSnapshot.error}');
                      return const Center(child: Text('An error occurred. Please try again.'));
                    }
                    if (!expenseSnapshot.hasData || expenseSnapshot.data!.docs.isEmpty) {
                      print('No expenses found for user: \\${user?.uid}');
                      return const Center(child: Text('No expenses found. Add your first expense!'));
                    }
                    final expenseDocs = expenseSnapshot.data!.docs;
                    print('Fetched \\${expenseDocs.length} expense docs for user: \\${user?.uid}');
                    double expenses = 0;
                    for (var doc in expenseDocs) {
                      final docData = doc.data() as Map<String, dynamic>;
                      final amount = docData['amount'];
                      if (amount is int) {
                        expenses += amount.toDouble();
                      } else if (amount is double) {
                        expenses += amount;
                      } else if (amount is String) {
                        expenses += double.tryParse(amount) ?? 0.0;
                      }
                    }
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseAuth.instance.currentUser == null
                          ? Future.value(null)
                          : FirebaseFirestore.instance
                              .collection('budgets')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .get(),
                      builder: (context, budgetSnapshot) {
                        if (budgetSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (budgetSnapshot.hasError) {
                          print('Budget snapshot error: \\${budgetSnapshot.error}');
                          return const Center(child: Text('An error occurred. Please try again.'));
                        }
                        if (!budgetSnapshot.hasData || budgetSnapshot.data?.data() == null) {
                          print('No budget data found for user: \\${user?.uid}');
                          return const Center(child: Text('No budget data found. Set up your budget!'));
                        }
                        final budgetData = budgetSnapshot.data?.data() as Map<String, dynamic>?;
                        print('Fetched budget data for user: \\${user?.uid} => \\${budgetData}');
                        final income = (budgetData?['income'] ?? 0).toDouble();
                        final savings = (budgetData?['goal'] ?? 0).toDouble();
                        final available = income - expenses;
                        return Center(
                          child: Wrap(
                            spacing: 32,
                            runSpacing: 32,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildOverviewCard('RWF', expenses.toStringAsFixed(0), 'Total Spent'),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const BudgetPage()),
                                  );
                                },
                                child: _buildOverviewCard('RWF', available.abs().toStringAsFixed(0), 'Remaining'),
                              ),
                              Stack(
                                children: [
                                  _buildOverviewCard('RWF', savings.toStringAsFixed(0), 'Savings Goal'),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () async {
                                        await _showEditSavingsGoalDialog(context, savings);
                                        (context as Element).markNeedsBuild();
                                      },
                                      child: const Icon(Icons.edit, size: 20, color: Colors.green),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 48),
                // Professional summary card
                FutureBuilder<String>(
                  future: (() async {
                    final prefs = await SharedPreferences.getInstance();
                    return prefs.getString('selectedCategory') ?? 'Food';
                  })(),
                  builder: (context, catSnap) {
                    if (!catSnap.hasData) return const SizedBox.shrink();
                    final selectedCategory = catSnap.data!;
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseAuth.instance.currentUser == null
                          ? Future.value(null)
                          : FirebaseFirestore.instance
                              .collection('budgets')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .get(),
                      builder: (context, budgetSnapshot) {
                        if (!budgetSnapshot.hasData) return const SizedBox.shrink();
                        final budgetData = budgetSnapshot.data?.data() as Map<String, dynamic>?;
                        final catBudget = (budgetData?[selectedCategory] ?? 0).toDouble();
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseAuth.instance.currentUser == null
                              ? const Stream.empty()
                              : FirebaseFirestore.instance
                                  .collection('expenses')
                                  .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                                  .where('category', isEqualTo: selectedCategory)
                                  .snapshots(),
                          builder: (context, expSnap) {
                            double catSpent = 0;
                            if (expSnap.hasData) {
                              for (var doc in expSnap.data!.docs) {
                                final docData = doc.data() as Map<String, dynamic>;
                                final amount = docData['amount'];
                                if (amount is int) {
                                  catSpent += amount.toDouble();
                                } else if (amount is double) {
                                  catSpent += amount;
                                } else if (amount is String) {
                                  catSpent += double.tryParse(amount) ?? 0.0;
                                }
                              }
                            }
                            final catRemaining = catBudget - catSpent;
                            final withinBudget = catSpent <= catBudget;
                            return Center(
                              child: Card(
                                elevation: 6,
                                margin: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 32),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.category, color: Colors.green[700], size: 28),
                                          const SizedBox(width: 12),
                                          Text(
                                            '$selectedCategory Summary',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      Text('Budget: RWF ${catBudget.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18)),
                                      Text('Spent: RWF ${catSpent.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18)),
                                      Text('Remaining: RWF ${catRemaining.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18)),
                                      const SizedBox(height: 10),
                                      Text(
                                        withinBudget ? 'Within budget' : 'Over budget',
                                        style: TextStyle(
                                          color: withinBudget ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),
                // --- Start of Spending History Section ---
                _AllExpenseHistoryList(),
                // --- End of Spending History Section ---
              ],
            ),
          ),
        ),
      ),
      // bottomNavigationBar: (!kIsWeb && (Platform.isAndroid || Platform.isIOS) && _isBannerAdReady)
      //     ? Padding(
      //         padding: const EdgeInsets.only(top: 24.0),
      //         child: Align(
      //           alignment: Alignment.bottomCenter,
      //           child: SizedBox(
      //             width: _bannerAd!.size.width.toDouble(),
      //             height: _bannerAd!.size.height.toDouble(),
      //             child: AdWidget(ad: _bannerAd!),
      //           ),
      //         ),
      //       )
      //     : null,
    );
  }

  Widget _buildOverviewCard(String currency, String amount, String label) {
    return Container(
      width: 140,
      height: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            currency,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditSavingsGoalDialog(BuildContext context, double currentGoal) async {
    final TextEditingController controller = TextEditingController(text: currentGoal.toStringAsFixed(0));
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Savings Goal'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'New Savings Goal (RWF)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newGoal = double.tryParse(controller.text) ?? 0;
                await FirebaseFirestore.instance
                    .collection('budgets')
                    .doc(user.uid)
                    .set({'goal': newGoal}, SetOptions(merge: true));
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _AllExpenseHistoryList extends StatefulWidget {
  @override
  State<_AllExpenseHistoryList> createState() => _AllExpenseHistoryListState();
}

class _AllExpenseHistoryListState extends State<_AllExpenseHistoryList> {
  final int _pageSize = 10;
  List<DocumentSnapshot> _docs = [];
  bool _hasMore = true;
  bool _isLoading = false;
  DocumentSnapshot? _lastDoc;

  @override
  void initState() {
    super.initState();
    _fetchMore();
  }

  Future<void> _fetchMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    Query query = FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .limit(_pageSize);
    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }
    final snapshot = await query.get();
    if (snapshot.docs.isNotEmpty) {
      _lastDoc = snapshot.docs.last;
      _docs.addAll(snapshot.docs);
      if (snapshot.docs.length < _pageSize) _hasMore = false;
    } else {
      _hasMore = false;
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_docs.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_docs.isEmpty) {
      return const Center(child: Text('No expenses found.'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _docs.length,
          itemBuilder: (context, i) {
            final doc = _docs[i];
            final date = (doc['date'] as Timestamp).toDate();
            final category = doc['category'] ?? '';
            final docData = doc.data() as Map<String, dynamic>;
            final amount = docData['amount'] ?? 0;
            final note = docData['note'] ?? '';
            final timeStr = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                leading: CircleAvatar(
                  backgroundColor: Colors.green[100],
                  child: Icon(Icons.shopping_bag, color: Colors.green[700]),
                ),
                title: Text(
                  note.isNotEmpty ? note : category,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Text(timeStr, style: const TextStyle(fontSize: 15)),
                trailing: Text(
                  'RWF ${amount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                ),
              ),
            );
          },
        ),
        if (_hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _fetchMore,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Load More', style: TextStyle(fontSize: 16)),
            ),
          ),
      ],
    );
  }
} 