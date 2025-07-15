import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notifications_service.dart';

class AdminBetsOverviewPage extends StatelessWidget {
  const AdminBetsOverviewPage({super.key});

  void _updateBetStatus(BuildContext context, String betId, String status, Map<String, dynamic> betData) async {
    try {
      await FirebaseFirestore.instance.collection('bets').doc(betId).update({'status': status});
      
      // Get user information for notification
      final userId = betData['userId'] ?? 'unknown';
      final wager = betData['wager'] ?? 0.0;
      
      // Get user name from users collection
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userName = userDoc.data()?['name'] ?? 'Unknown User';
      
      // Create admin notification
      await NotificationsService.notifyBetStatusChanged(
        userName: userName,
        userId: userId,
        status: status,
        wager: wager,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bet marked as $status'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating bet: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Bets Overview (Admin)'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('bets').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No bets found.'));
                }
                final bets = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: bets.length,
                  itemBuilder: (context, index) {
                    final doc = bets[index];
                    final bet = doc.data() as Map<String, dynamic>;
                    final selections = bet['selections'] as List<dynamic>? ?? [];
                    final wager = bet['wager'] ?? 0.0;
                    final odds = bet['cumulativeOdds'] ?? 0.0;
                    final status = bet['status'] ?? 'pending';
                    final userId = bet['userId'] ?? 'unknown';
                    final timestamp = (bet['timestamp'] as Timestamp?)?.toDate();
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getStatusIcon(status),
                                  color: _getStatusColor(status),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'User: $userId',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...selections.map((s) => Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text('${s['matchTitle']} (${s['oddKey']}) - Odd: ${s['oddValue']}'),
                            )).toList(),
                            const SizedBox(height: 4),
                            Text('Wager: \$${wager.toStringAsFixed(2)}  |  Odds: ${odds.toStringAsFixed(2)}'),
                            Text('Time: ${timestamp != null ? timestamp.toString().substring(0, 16) : 'Unknown'}'),
                            const SizedBox(height: 8),
                            if (status == 'pending')
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _updateBetStatus(context, doc.id, 'approved', bet),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Approve'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _updateBetStatus(context, doc.id, 'rejected', bet),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Reject'),
                                    ),
                                  ),
                                ],
                              ),
                            if (status == 'approved')
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _updateBetStatus(context, doc.id, 'won', bet),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Mark as Won'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _updateBetStatus(context, doc.id, 'lost', bet),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Mark as Lost'),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'won':
        return Icons.emoji_events;
      case 'lost':
        return Icons.close;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'won':
        return Colors.blue;
      case 'lost':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
} 