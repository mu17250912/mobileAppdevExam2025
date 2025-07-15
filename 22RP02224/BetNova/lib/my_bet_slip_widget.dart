import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'betslip_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'main.dart';
import 'subscription_service.dart';
import 'premium_subscription_screen.dart';
import 'models.dart';
import 'notifications_service.dart';

class MyBetSlipWidget extends StatefulWidget {
  const MyBetSlipWidget({super.key});

  @override
  State<MyBetSlipWidget> createState() => _MyBetSlipWidgetState();
}

class _MyBetSlipWidgetState extends State<MyBetSlipWidget> {
  final TextEditingController _wagerController = TextEditingController();
  bool _isPlacingBet = false;
  int _selectedTab = 0; // 0: Betslip, 1: My Bets

  @override
  void dispose() {
    _wagerController.dispose();
    super.dispose();
  }

  Future<void> _placeBet(BetSlipProvider betSlip) async {
    setState(() { _isPlacingBet = true; });
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      final wager = double.tryParse(_wagerController.text) ?? 0.0;
      if (wager < 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Min Stake is 100')), // Already handled in UI, but double check
        );
        return;
      }

      // Validate premium subscription limits
      final validation = await SubscriptionService.validateBetPlacement(wager, betSlip.selections.length);
      if (!validation['canPlace']) {
        if (validation['upgradeRequired']) {
          // Show upgrade dialog
          final shouldUpgrade = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Premium Feature Required'),
              content: Text(validation['reason']),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  child: const Text('Upgrade to Premium'),
                ),
              ],
            ),
          );

          if (shouldUpgrade == true) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PremiumSubscriptionScreen()),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(validation['reason'])),
          );
        }
        return;
      }

      // Fetch user balance
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userBalance = (userDoc['balance'] as num?)?.toDouble() ?? 0.0;
      if (userBalance < wager) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insufficient balance. Please deposit to place bet.')),
        );
        return;
      }
      // Deduct stake from balance
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'balance': userBalance - wager,
      });
      final selections = betSlip.selections.map((s) => {
        'matchId': s.matchId,
        'matchTitle': s.matchTitle,
        'market': s.market,
        'oddKey': s.oddKey,
        'oddValue': s.oddValue,
      }).toList();
      await FirebaseFirestore.instance.collection('bets').add({
        'userId': user.uid,
        'wager': wager,
        'cumulativeOdds': betSlip.cumulativeOdds,
        'selections': selections,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      
      // Get user name for notification
      final userName = userDoc['name'] ?? 'Unknown User';
      
      // Create admin notification
      await NotificationsService.notifyBetPlaced(
        userName: userName,
        userId: user.uid,
        wager: wager,
        selectionsCount: selections.length,
      );
      
      await logAdminEvent('bet_placed', {'wager': wager, 'selections': selections.length});
      betSlip.clear();
      _wagerController.clear();
      if (mounted) {
        setState(() { _selectedTab = 1; }); // Switch to My Bets after placing
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bet placed!')),
        );
      }
    } catch (e) {
      print('DEBUG: Failed to place bet: $e'); // Debug print for Firestore errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place bet: $e')),
      );
    } finally {
      setState(() { _isPlacingBet = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BetSlipProvider>(
      builder: (context, betSlip, child) {
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 340,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(left: BorderSide(color: Colors.grey.shade300, width: 1)),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(-2, 0))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium status indicator
                  FutureBuilder<User?>(
                    future: SubscriptionService.getCurrentUser(),
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      final isPremium = user?.hasActiveSubscription ?? false;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isPremium ? Colors.amber.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPremium ? Colors.amber.shade200 : Colors.blue.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isPremium ? Icons.star : Icons.info,
                              color: isPremium ? Colors.amber.shade600 : Colors.blue.shade600,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isPremium 
                                    ? 'Premium: Up to 1M RWF, 15 selections'
                                    : 'Free: Up to 10K RWF, 5 selections',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isPremium ? Colors.amber.shade700 : Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (!isPremium)
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PremiumSubscriptionScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                ),
                                child: Text(
                                  'Upgrade',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _selectedTab = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 0 ? Colors.green[100] : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Betslip', style: TextStyle(fontWeight: FontWeight.bold, color: _selectedTab == 0 ? Colors.green[900] : Colors.grey[700])),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => _selectedTab = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 1 ? Colors.green[100] : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('My Bets', style: TextStyle(fontWeight: FontWeight.bold, color: _selectedTab == 1 ? Colors.green[900] : Colors.grey[700])),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedTab == 0 && betSlip.selections.isNotEmpty)
                        IconButton(
                          onPressed: () => betSlip.clear(),
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                          tooltip: 'Clear All',
                        ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: _selectedTab == 0
                        ? _BetslipPanel(
                            betSlip: betSlip,
                            wagerController: _wagerController,
                            isPlacingBet: _isPlacingBet,
                            onPlaceBet: () => _placeBet(betSlip),
                          )
                        : _UserBetsList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BetslipPanel extends StatefulWidget {
  final BetSlipProvider betSlip;
  final TextEditingController wagerController;
  final bool isPlacingBet;
  final VoidCallback onPlaceBet;
  const _BetslipPanel({required this.betSlip, required this.wagerController, required this.isPlacingBet, required this.onPlaceBet});

  @override
  State<_BetslipPanel> createState() => _BetslipPanelState();
}

class _BetslipPanelState extends State<_BetslipPanel> {
  @override
  void initState() {
    super.initState();
    widget.wagerController.addListener(_onStakeChanged);
  }

  @override
  void dispose() {
    widget.wagerController.removeListener(_onStakeChanged);
    super.dispose();
  }

  void _onStakeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final betSlip = widget.betSlip;
    final wagerController = widget.wagerController;
    final isPlacingBet = widget.isPlacingBet;
    final onPlaceBet = widget.onPlaceBet;
    if (betSlip.selections.isEmpty) {
      return Center(child: Text('No selections yet.', style: TextStyle(color: Colors.grey[600])));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: betSlip.selections.length,
            itemBuilder: (context, index) {
              final s = betSlip.selections[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                color: Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  title: Text(s.matchTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${s.market} (${s.oddKey})', style: const TextStyle(fontSize: 13)),
                  trailing: Column(
                    children: [
                      Text(s.oddValue.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red, size: 20),
                        onPressed: () => betSlip.removeSelection(s.matchId),
                        tooltip: 'Remove',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Stake:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: wagerController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: 'min stake is 100',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Min stake validation
        if (wagerController.text.isNotEmpty && (double.tryParse(wagerController.text) ?? 0) < 100)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text('Min Stake is 100', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Odds: ${betSlip.cumulativeOdds.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (wagerController.text.isNotEmpty && double.tryParse(wagerController.text) != null)
              Text(
                'Potential Winnings: ${(betSlip.cumulativeOdds * double.parse(wagerController.text)).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
          ],
        ),
        if (wagerController.text.isNotEmpty && double.tryParse(wagerController.text) != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Payout: ${(betSlip.cumulativeOdds * double.parse(wagerController.text) + double.parse(wagerController.text)).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lime,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            onPressed: betSlip.selections.isEmpty || isPlacingBet || (wagerController.text.isEmpty || (double.tryParse(wagerController.text) ?? 0) < 100)
                ? null
                : onPlaceBet,
            child: isPlacingBet
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('PLACE BET'),
          ),
        ),
      ],
    );
  }
}

class _UserBetsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bets')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('DEBUG: Firestore query error: ${snapshot.error}'); // Debug print for query errors
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No bets found.', style: TextStyle(color: Colors.grey)),
          );
        }
        final bets = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          itemCount: bets.length,
          itemBuilder: (context, index) {
            final bet = bets[index].data() as Map<String, dynamic>;
            final selections = bet['selections'] as List<dynamic>? ?? [];
            final wager = bet['wager'] ?? 0.0;
            final odds = bet['cumulativeOdds'] ?? 0.0;
            final status = bet['status'] ?? 'pending';
            final timestamp = (bet['timestamp'] as Timestamp?)?.toDate();
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ExpansionTile(
                title: Text('Bet: ${timestamp != null ? timestamp.toString().substring(0, 16) : 'Unknown'}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wager: $wager  |  Odds: $odds'),
                    Text('Status: $status'),
                  ],
                ),
                children: [
                  ...selections.map((s) => ListTile(
                        dense: true,
                        title: Text('${s['matchTitle'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Market: ${s['market'] ?? ''} | Pick: ${s['oddKey'] ?? ''} | Odd: ${s['oddValue'] ?? ''}'),
                      )),
                ],
              ),
            );
          },
        );
      },
    );
  }
} 