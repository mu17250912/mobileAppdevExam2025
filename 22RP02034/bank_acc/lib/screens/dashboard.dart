import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'custom_top_bar.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  final String? userEmail;
  const DashboardScreen({Key? key, this.userEmail}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;
    return Scaffold(
      appBar: CustomTopBar(pageName: 'Dashboard', userEmail: widget.userEmail),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/bgg.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.15), // Much lighter overlay for clearer image
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 32 : 8,
              vertical: isWide ? 24 : 8,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(isWide),
                  const SizedBox(height: 32),
                  _buildBarChart(isWide),
                  const SizedBox(height: 32),
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: isWide ? 22 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRecentTransactions(isWide),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(bool isWide) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('payments').snapshots(),
      builder: (context, paymentSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('savings').snapshots(),
          builder: (context, savingSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Cards').snapshots(),
              builder: (context, cardSnap) {
            double totalPayments = 0;
            double totalSavings = 0;
            double totalCardBalances = 0;
            int totalCards = 0;
            if (paymentSnap.hasData) {
              for (var doc in paymentSnap.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final amount =
                    double.tryParse(data['amount']?.toString() ?? '') ?? 0;
                totalPayments += amount;
              }
            }
            if (savingSnap.hasData) {
              for (var doc in savingSnap.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final amount =
                    double.tryParse(data['amount']?.toString() ?? '') ?? 0;
                totalSavings += amount;
              }
            }
            if (cardSnap.hasData) {
              totalCards = cardSnap.data!.docs.length;
              for (var doc in cardSnap.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final amount = double.tryParse(data['initialBalance']?.toString() ?? '') ?? 0;
                totalCardBalances += amount;
              }
            }
            double totalBalance = totalPayments + totalSavings;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _summaryCard(
                  'Total Payments',
                  totalPayments,
                  Colors.blue,
                  isWide,
                ),
                _summaryCard(
                  'Total Savings',
                  totalSavings,
                  Colors.green,
                  isWide,
                ),
                _summaryCard(
                  'Total Balance',
                  totalBalance,
                  Colors.deepPurple,
                  isWide,
                ),
                _summaryCard(
                  'Total Cards',
                  totalCards.toDouble(),
                  Colors.orange,
                  isWide,
                ),
                _summaryCard(
                  'Card Balances',
                  totalCardBalances,
                  Colors.teal,
                  isWide,
                ),
              ],
            );
              },
            );
          },
        );
      },
    );
  }

  Widget _summaryCard(String label, double value, Color color, bool isWide) {
    IconData icon;
    if (label.contains('Payment')) {
      icon = Icons.payment;
    } else if (label.contains('Saving')) {
      icon = Icons.savings;
    } else {
      icon = Icons.account_balance_wallet;
    }
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: isWide ? 180 : double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: isWide ? 24 : 16,
          horizontal: isWide ? 18 : 10,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: isWide ? 32 : 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: isWide ? 16 : 14,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                fontSize: isWide ? 28 : 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(bool isWide) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('payments').snapshots(),
      builder: (context, paymentSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('savings').snapshots(),
          builder: (context, savingSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Cards').snapshots(),
              builder: (context, cardSnap) {
            final now = DateTime.now();
            final months = List.generate(
              6,
              (i) => DateTime(now.year, now.month - 5 + i, 1),
            );
            Map<String, double> monthlyTotals = {
              for (var m in months) DateFormat('MMM yyyy').format(m): 0,
            };
            if (paymentSnap.hasData) {
              for (var doc in paymentSnap.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final amount =
                    double.tryParse(data['amount']?.toString() ?? '') ?? 0;
                final ts = data['timestamp'];
                if (ts is Timestamp) {
                  final dt = ts.toDate();
                  final key = DateFormat(
                    'MMM yyyy',
                  ).format(DateTime(dt.year, dt.month, 1));
                  if (monthlyTotals.containsKey(key))
                    monthlyTotals[key] = monthlyTotals[key]! + amount;
                }
              }
            }
            if (savingSnap.hasData) {
              for (var doc in savingSnap.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final amount =
                    double.tryParse(data['amount']?.toString() ?? '') ?? 0;
                final ts = data['timestamp'];
                if (ts is Timestamp) {
                  final dt = ts.toDate();
                  final key = DateFormat(
                    'MMM yyyy',
                  ).format(DateTime(dt.year, dt.month, 1));
                  if (monthlyTotals.containsKey(key))
                    monthlyTotals[key] = monthlyTotals[key]! + amount;
                }
              }
            }
            if (cardSnap.hasData) {
              for (var doc in cardSnap.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final amount = double.tryParse(data['initialBalance']?.toString() ?? '') ?? 0;
                final ts = data['timestamp'];
                if (ts is Timestamp) {
                  final dt = ts.toDate();
                  final key = DateFormat(
                    'MMM yyyy',
                  ).format(DateTime(dt.year, dt.month, 1));
                  if (monthlyTotals.containsKey(key))
                    monthlyTotals[key] = monthlyTotals[key]! + amount;
                }
              }
            }
            final maxVal = monthlyTotals.values.isNotEmpty
                ? monthlyTotals.values.reduce(max)
                : 1;
            return Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: EdgeInsets.all(isWide ? 24.0 : 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Total (Payments + Savings)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isWide ? 18 : 15,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: isWide ? 160 : 120,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final entry in monthlyTotals.entries)
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  AnimatedContainer(
                                    duration: Duration(milliseconds: 600),
                                    height: maxVal > 0
                                        ? (isWide ? 100 : 60) *
                                              (entry.value / maxVal)
                                        : 0,
                                    width: isWide ? 24 : 16,
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: isWide ? 12 : 10,
                                    ),
                                  ),
                                  Text(
                                    entry.value.toStringAsFixed(0),
                                    style: TextStyle(
                                      fontSize: isWide ? 12 : 10,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRecentTransactions(bool isWide) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .orderBy('timestamp', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, paymentSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('savings')
              .orderBy('timestamp', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, savingSnap) {
            List<Map<String, dynamic>> txs = [];
            if (paymentSnap.hasData) {
              txs.addAll(
                paymentSnap.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'type': 'Payment',
                    'amount': data['amount']?.toString() ?? '',
                    'desc': data['cardholderName']?.toString() ?? '',
                    'timestamp': data['timestamp'],
                  };
                }),
              );
            }
            if (savingSnap.hasData) {
              txs.addAll(
                savingSnap.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'type': 'Saving',
                    'amount': data['amount']?.toString() ?? '',
                    'desc': data['bankName']?.toString() ?? '',
                    'timestamp': data['timestamp'],
                  };
                }),
              );
            }
            // Sort by timestamp descending
            txs.sort((a, b) {
              final ta = a['timestamp'] is Timestamp
                  ? (a['timestamp'] as Timestamp).toDate()
                  : DateTime(1970);
              final tb = b['timestamp'] is Timestamp
                  ? (b['timestamp'] as Timestamp).toDate()
                  : DateTime(1970);
              return tb.compareTo(ta);
            });
            final recent = txs.take(6).toList();
            if (recent.isEmpty) {
              return Text('No recent transactions.');
            }
            return Column(
              children: recent.map((tx) {
                final isPayment = tx['type'] == 'Payment';
                final color = isPayment ? Colors.blue : Colors.green;
                final icon = isPayment ? Icons.payment : Icons.savings;
                final dateStr = tx['timestamp'] is Timestamp
                    ? DateFormat(
                        'MMM d, yyyy h:mm a',
                      ).format((tx['timestamp'] as Timestamp).toDate())
                    : '';
                return Card(
                  margin: EdgeInsets.symmetric(vertical: isWide ? 8 : 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(icon, color: color, size: isWide ? 28 : 22),
                    title: Text(
                      '${tx['desc']}',
                      style: TextStyle(fontSize: isWide ? 16 : 13),
                    ),
                    subtitle: Text(
                      dateStr,
                      style: TextStyle(fontSize: isWide ? 13 : 11),
                    ),
                    trailing: Text(
                      tx['amount'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: isWide ? 16 : 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
