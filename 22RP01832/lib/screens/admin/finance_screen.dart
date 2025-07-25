import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'admin_dashboard.dart';
import 'reports_screen.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({Key? key}) : super(key: key);

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance & Commissions'),
        backgroundColor: Colors.black,
      ),
      drawer: _adminDrawer(context),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('commissions')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SpinKitWave(color: Color(0xFF9CE800), size: 32),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No commission transactions found.'),
            );
          }
          final docs = snapshot.data!.docs;
          int totalCommission = 0;
          int totalPayout = 0;
          for (var doc in docs) {
            totalCommission += (doc['commission'] ?? 0) as int;
            totalPayout += (doc['sellerPayout'] ?? 0) as int;
          }
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Card(
                color: Colors.white,
                elevation: 5,
                shadowColor: Colors.green.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Total Commission',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            totalCommission.toString(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9CE800),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text(
                            'Total Payout',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            totalPayout.toString(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Filter chips for Today, This Week, This Month (UI only, logic to be added)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilterChip(
                    label: Text('Today'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  SizedBox(width: 8),
                  FilterChip(
                    label: Text('This Week'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  SizedBox(width: 8),
                  FilterChip(
                    label: Text('This Month'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final date = data['createdAt'] is Timestamp
                    ? (data['createdAt'] as Timestamp).toDate()
                    : null;
                return FutureBuilder<Map<String, String>>(
                  future:
                      Future.wait([
                        getUserInfo(data['sellerId'] ?? ''),
                        getUserInfo(data['buyerId'] ?? ''),
                      ]).then(
                        (list) => {
                          'sellerName': list[0]['name'] ?? '',
                          'sellerEmail': list[0]['email'] ?? '',
                          'buyerName': list[1]['name'] ?? '',
                          'buyerEmail': list[1]['email'] ?? '',
                        },
                      ),
                  builder: (context, snapshot) {
                    final info =
                        snapshot.data ??
                        {
                          'sellerName': '',
                          'sellerEmail': '',
                          'buyerName': '',
                          'buyerEmail': '',
                        };
                    return ExpandableCard(
                      title: Text(
                        'Book: ${data['bookId'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      expandedContent: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seller: ${info['sellerName']} (${info['sellerEmail']})',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Buyer: ${info['buyerName']} (${info['buyerEmail']})',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Amount: RWF ${(data['amount'] ?? 0).toString()}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Commission: RWF ${(data['commission'] ?? 0).toString()}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9CE800),
                            ),
                          ),
                          Text(
                            'Payout: RWF ${(data['sellerPayout'] ?? 0).toString()}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                            ),
                          ),
                          if (date != null)
                            Text(
                              'Date: ${date != null ? DateFormat.yMMMd().add_jm().format(date) : ''}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _adminDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.black),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Admin Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'BookSwap',
                  style: TextStyle(
                    color: Color(0xFF9CE800),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.black),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AdminDashboard()),
                (route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_money, color: Colors.green),
            title: const Text('Finance'),
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const FinanceScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics, color: Color(0xFF9CE800)),
            title: const Text('Reports'),
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ExpandableCard extends StatefulWidget {
  final Widget title;
  final Widget expandedContent;
  const ExpandableCard({
    Key? key,
    required this.title,
    required this.expandedContent,
  }) : super(key: key);
  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: Colors.white,
      shadowColor: Colors.green.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          ListTile(
            title: widget.title,
            trailing: GestureDetector(
              onTap: () => setState(() => expanded = !expanded),
              child: CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: Icon(
                  expanded ? Icons.remove : Icons.add,
                  color: expanded ? Colors.red : Colors.green,
                ),
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: widget.expandedContent,
            ),
        ],
      ),
    );
  }
}

Future<Map<String, String>> getUserInfo(String uid) async {
  if (uid.isEmpty) return {'name': '', 'email': ''};
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();
  final data = doc.data();
  return {'name': data?['name'] ?? '', 'email': data?['email'] ?? ''};
}
 