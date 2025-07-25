import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Set<String> _selected = {};
  bool _selectAll = false;

  Future<void> _deleteConversion(BuildContext context, String docId) async {
    await FirebaseFirestore.instance.collection('conversions').doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversion deleted.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final docId in _selected) {
      final ref = FirebaseFirestore.instance.collection('conversions').doc(docId);
      batch.delete(ref);
    }
    await batch.commit();
    setState(() {
      _selected.clear();
      _selectAll = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selected conversions deleted.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _clearAllConversions(BuildContext context, String userId) async {
    final batch = FirebaseFirestore.instance.batch();
    final query = await FirebaseFirestore.instance
        .collection('conversions')
        .where('userId', isEqualTo: userId)
        .get();
    for (var doc in query.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    setState(() {
      _selected.clear();
      _selectAll = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All history cleared.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.user?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversion History'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_selected.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Selected',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Selected'),
                    content: const Text('Are you sure you want to delete all selected conversions?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _deleteSelected(context);
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear All',
            onPressed: userId == null
                ? null
                : () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear All History'),
                        content: const Text('Are you sure you want to delete all conversion history?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _clearAllConversions(context, userId);
                    }
                  },
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          StreamBuilder(
            stream: authService.getConversionHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SizedBox.shrink();
              }
              final docs = snapshot.data!.docs;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Your Conversion History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 300, // or use MediaQuery for dynamic height
                    child: ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        final from = data['fromCurrency'] ?? '';
                        final to = data['toCurrency'] ?? '';
                        final amount = data['amount'] ?? 0.0;
                        final converted = data['convertedAmount'] ?? 0.0;
                        final rate = data['rate'] ?? 0.0;
                        final timestamp = (data['timestamp'] as dynamic)?.toDate();
                        final docId = docs[i].id;
                        final isSelected = _selected.contains(docId);
                        final username = data['username'] ?? '';
                        return Dismissible(
                          key: Key(docId),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            color: Colors.red,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Conversion'),
                                content: const Text('Are you sure you want to delete this conversion?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (_) => _deleteConversion(context, docId),
                          child: ListTile(
                            leading: Checkbox(
                              value: isSelected,
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selected.add(docId);
                                    if (_selected.length == docs.length) {
                                      _selectAll = true;
                                    }
                                  } else {
                                    _selected.remove(docId);
                                    _selectAll = false;
                                  }
                                });
                              },
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$amount $from',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF667eea),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward, color: Color(0xFF667eea)),
                                Text(
                                  '$converted $to',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF764ba2),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'By: $username',
                                  style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Rate: 1 $from =  {rate.toStringAsFixed(2)} $to',
                                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                                if (timestamp != null)
                                  Text(
                                    'Date: ${DateFormat.yMMMd().add_jm().format(timestamp)}',
                                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'All Conversions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Clear All'),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear All Conversions'),
                        content: const Text('Are you sure you want to delete ALL conversions? This cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      final batch = FirebaseFirestore.instance.batch();
                      final query = await FirebaseFirestore.instance.collection('conversions').get();
                      for (var doc in query.docs) {
                        batch.delete(doc.reference);
                      }
                      await batch.commit();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All conversions deleted.'), backgroundColor: Colors.red),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          // All conversions
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('conversions')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No conversions found.', style: TextStyle(color: Colors.grey)),
                  );
                }
                final docs = snapshot.data!.docs;
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final from = data['fromCurrency'] ?? '';
                    final to = data['toCurrency'] ?? '';
                    final amount = data['amount'] ?? 0.0;
                    final converted = data['convertedAmount'] ?? 0.0;
                    final username = data['username'] ?? '';
                    final docId = docs[i].id;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$amount $from', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                              const SizedBox(height: 2),
                              Text('→ $converted $to', style: TextStyle(color: Color(0xFF764ba2), fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('By: $username', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                         IconButton(
                           icon: const Icon(Icons.delete, color: Colors.red),
                           tooltip: 'Delete Conversion',
                           onPressed: () async {
                             final confirm = await showDialog<bool>(
                               context: context,
                               builder: (ctx) => AlertDialog(
                                 title: const Text('Delete Conversion'),
                                 content: const Text('Are you sure you want to delete this conversion?'),
                                 actions: [
                                   TextButton(
                                     onPressed: () => Navigator.of(ctx).pop(false),
                                     child: const Text('Cancel'),
                                   ),
                                   TextButton(
                                     onPressed: () => Navigator.of(ctx).pop(true),
                                     child: const Text('Delete'),
                                   ),
                                 ],
                               ),
                             );
                             if (confirm == true) {
                               await FirebaseFirestore.instance.collection('conversions').doc(docId).delete();
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text('Conversion deleted.'), backgroundColor: Colors.red),
                               );
                             }
                           },
                         ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 