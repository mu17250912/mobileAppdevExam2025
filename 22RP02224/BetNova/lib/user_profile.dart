import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_screen.dart';
import 'main.dart';
import 'user_home.dart'; // For MfaEnrollWidget
import 'premium_subscription_screen.dart';

class UserProfile extends StatelessWidget {
  const UserProfile({super.key});

  Future<Map<String, dynamic>> _fetchUserStats(String userId) async {
    final betsSnap = await FirebaseFirestore.instance
        .collection('bets')
        .where('userId', isEqualTo: userId)
        .get();
    int total = betsSnap.docs.length;
    int won = 0, lost = 0;
    for (var doc in betsSnap.docs) {
      final data = doc.data();
      if (data['result'] == 'won') {
        won++;
      } else if (data['result'] == 'lost') {
        lost++;
      }
    }
    return {
      'total': total,
      'won': won,
      'lost': lost,
    };
  }

  void _showSimulatedMobileMoneyDialog(BuildContext context, String userId) {
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simulated Mobile Money Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'e.g. 078xxxxxxx',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: 'e.g. 1000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final phone = phoneController.text.trim();
              final amount = double.tryParse(amountController.text.trim()) ?? 0;
              if (phone.length < 10 || amount < 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter valid phone and amount (min 100)')),
                );
                return;
              }
              // Simulate payment processing
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              await Future.delayed(const Duration(seconds: 2));
              Navigator.pop(context); // remove progress
              // Simulate success: update user balance
              final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
              final current = (doc['balance'] as num?)?.toDouble() ?? 0.0;
              await FirebaseFirestore.instance.collection('users').doc(userId).update({'balance': current + amount});
              Navigator.pop(context); // remove dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment successful (simulated)!')),
              );
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in.')));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BetNova Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withValues(alpha: 0.3),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.deepPurple.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.displayName ?? 'User',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.email ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user.uid.substring(0, 4).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Stats Cards
                  FutureBuilder<Map<String, dynamic>>(
                    future: _fetchUserStats(user.uid),
                    builder: (context, statsSnap) {
                      if (!statsSnap.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.deepPurple,
                          ),
                        );
                      }
                      final stats = statsSnap.data!;
                      return Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Bets',
                              '${stats['total']}',
                              Icons.sports_soccer,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Won',
                              '${stats['won']}',
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Lost',
                              '${stats['lost']}',
                              Icons.cancel,
                              Colors.red,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // My Bets Horizontal Scroll Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.history, color: Colors.deepPurple, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'My Bets',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 180,
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('bets')
                                .where('userId', isEqualTo: user.uid)
                                .orderBy('timestamp', descending: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                              }
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
                              }
                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return const Center(
                                  child: Text('No bets yet', style: TextStyle(color: Colors.grey)),
                                );
                              }
                              final bets = snapshot.data!.docs;
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: bets.map((betDoc) {
                                    final data = betDoc.data() as Map<String, dynamic>;
                                    final status = data['status'] ?? 'pending';
                                    final amount = data['amount']?.toString() ?? '0';
                                    final selections = data['selections']?.length?.toString() ?? '0';
                                    final timestamp = data['timestamp'] as Timestamp?;
                                    Color statusColor;
                                    String statusText;
                                    switch (status) {
                                      case 'won':
                                        statusColor = Colors.green;
                                        statusText = 'Won';
                                        break;
                                      case 'lost':
                                        statusColor = Colors.red;
                                        statusText = 'Lost';
                                        break;
                                      case 'approved':
                                        statusColor = Colors.blue;
                                        statusText = 'Approved';
                                        break;
                                      default:
                                        statusColor = Colors.blue;
                                        statusText = 'Pending';
                                    }
                                    return Container(
                                      width: 220,
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Card(
                                        color: Colors.white,
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Bet: ${timestamp != null ? '${timestamp.toDate().year}-${timestamp.toDate().month.toString().padLeft(2, '0')}-${timestamp.toDate().day.toString().padLeft(2, '0')}' : 'N/A'}',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              Text('Wager: $amount'),
                                              Text('Odds: ${data['odds'] ?? '-'}'),
                                              Text('Selections: $selections'),
                                              const SizedBox(height: 8),
                                              Text(
                                                statusText,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildActionButton(
                          'Deposit Funds',
                          Icons.account_balance_wallet,
                          Colors.green,
                          () => _showDepositDialog(context, user.uid),
                        ),
                        const SizedBox(height: 12),
                        _buildActionButton(
                          'Deposit via Mobile Money',
                          Icons.phone_android,
                          Colors.orange,
                          () => _showSimulatedMobileMoneyDialog(context, user.uid),
                        ),
                        const SizedBox(height: 12),
                        _buildActionButton(
                          'Withdraw Funds',
                          Icons.money_off,
                          Colors.orange,
                          () => _showWithdrawDialog(context, user.uid),
                        ),
                        const SizedBox(height: 12),
                        _buildActionButton(
                          'Change PIN',
                          Icons.lock,
                          Colors.blue,
                          () => _showChangePinDialog(context, user.uid),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.description, color: Colors.deepPurple),
                          title: const Text('Statement'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // TODO: Implement statement page
                          },
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        _buildActionButton(
                          'Log Out',
                          Icons.logout,
                          Colors.red,
                          () async {
                            await FirebaseAuth.instance.signOut();
                            await logAdminEvent('logout', {});
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const AuthScreen()),
                                (route) => false,
                              );
                            }
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.contact_mail, color: Colors.deepPurple),
                          title: const Text('Contact', style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ContactPage()),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.settings, color: Colors.deepPurple),
                          title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const UserSettingsPage()),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Premium Subscription Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.amber.shade400, Colors.amber.shade600],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.star, color: Colors.white, size: 24),
                                  SizedBox(width: 8),
                                  Text(
                                    'Premium Subscription',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Unlock exclusive features and higher betting limits',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const PremiumSubscriptionScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.amber.shade600,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Upgrade to Premium',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Add this section for email verification
                        if (!user.emailVerified) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.email, color: Colors.white),
                            label: const Text(
                              'Ohereza Verification Email',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              await user.sendEmailVerification();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Verification email yoherejwe kuri ${user.email}')),
                                );
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Info message for MFA
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lock, color: Colors.blue, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'For your security: Enabling SMS Multi-Factor Authentication (MFA) helps protect your account from unauthorized access, even if someone knows your password. You will be asked for a code sent to your phone when signing in.',
                            style: TextStyle(color: Colors.blue[900], fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  MfaEnrollWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
                                      color: color.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  void _showDepositDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => _DepositWithdrawDialog(
        title: 'Deposit',
        onConfirm: (amount) async {
          final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
          final current = (doc['balance'] as num?)?.toDouble() ?? 0.0;
          await FirebaseFirestore.instance.collection('users').doc(userId).update({'balance': current + amount});
          await logAdminEvent('deposit', {'amount': amount});
        },
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => _DepositWithdrawDialog(
        title: 'Withdraw',
        onConfirm: (amount) async {
          final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
          final current = (doc['balance'] as num?)?.toDouble() ?? 0.0;
          if (amount > current) throw Exception('Insufficient balance');
          await FirebaseFirestore.instance.collection('users').doc(userId).update({'balance': current - amount});
          await logAdminEvent('withdraw', {'amount': amount});
        },
      ),
    );
  }

  void _showChangePinDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => _ChangePinDialog(userId: userId),
    );
  }
}

class _DepositWithdrawDialog extends StatefulWidget {
  final String title;
  final Future<void> Function(double amount) onConfirm;
  const _DepositWithdrawDialog({required this.title, required this.onConfirm});

  @override
  State<_DepositWithdrawDialog> createState() => _DepositWithdrawDialogState();
}

class _DepositWithdrawDialogState extends State<_DepositWithdrawDialog> {
  final _amountController = TextEditingController();
  String? _error;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.deepPurple,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Amount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: 'RWF ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Min: 10, Max: 5,000,000',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      final amount = double.tryParse(_amountController.text.trim()) ?? 0;
                      if (amount < 10 || amount > 5000000) {
                        setState(() { _error = 'Amount must be between 10 and 5,000,000'; });
                        return;
                      }
                      setState(() { _isLoading = true; _error = null; });
                      try {
                        await widget.onConfirm(amount);
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        setState(() { _error = e.toString(); });
                      } finally {
                        setState(() { _isLoading = false; });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(widget.title.toUpperCase()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePinDialog extends StatefulWidget {
  final String userId;
  const _ChangePinDialog({required this.userId});

  @override
  State<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<_ChangePinDialog> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String? _error;
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Change PIN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.deepPurple,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'New PIN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'XXXX',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Confirm PIN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'XXXX',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      final pin = _pinController.text.trim();
                      final confirmPin = _confirmPinController.text.trim();
                      if (pin.length != 4 || !RegExp(r'^[0-9]+$').hasMatch(pin)) {
                        setState(() { _error = 'PIN must be 4 digits'; });
                        return;
                      }
                      if (pin != confirmPin) {
                        setState(() { _error = 'PINs do not match'; });
                        return;
                      }
                      setState(() { _isLoading = true; _error = null; });
                      try {
                        await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({'pin': pin});
                        await logAdminEvent('profile_update', {'field': 'pin'});
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        setState(() { _error = e.toString(); });
                      } finally {
                        setState(() { _isLoading = false; });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('CHANGE PIN'),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade50, Colors.blue.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  const Text('Get in Touch', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  const SizedBox(height: 16),
                  const Text('Connect with us on social media or WhatsApp for support and updates.',
                      style: TextStyle(fontSize: 16, color: Colors.black54), textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  // Social Media Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.facebook, size: 36),
                        color: Colors.blue,
                        onPressed: () => _launchUrl('https://web.facebook.com/Dwayne.manirakiza.12'),
                        tooltip: 'Facebook',
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: const Icon(Icons.camera_alt, size: 36), // Instagram alternative
                        color: Colors.purple,
                        onPressed: () => _launchUrl('https://www.instagram.com/manirakizadwayne/'),
                        tooltip: 'Instagram',
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: const Icon(Icons.clear, size: 36), // X (Twitter) alternative
                        color: Colors.black,
                        onPressed: () => _launchUrl('https://x.com/manirakizadani7'),
                        tooltip: 'X',
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: const Icon(Icons.chat, size: 36),
                        color: Colors.green,
                        onPressed: () => _launchUrl('https://wa.me/250783158697'),
                        tooltip: 'WhatsApp',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Contact Info
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.email, color: Colors.deepPurple, size: 20),
                      SizedBox(width: 8),
                      Text('daniel@gmail.com', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone, color: Colors.deepPurple, size: 20),
                      SizedBox(width: 8),
                      Text('+250 783 158 697', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class UserSettingsPage extends StatefulWidget {
  const UserSettingsPage({super.key});
  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  bool _darkTheme = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.lock, color: Colors.deepPurple),
                title: const Text('Change PIN', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {
                  // TODO: Implement change PIN dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Change PIN'),
                      content: const Text('PIN change functionality coming soon.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.email, color: Colors.deepPurple),
                title: const Text('Update Email', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {
                  // TODO: Implement update email dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Update Email'),
                      content: const Text('Email update functionality coming soon.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: SwitchListTile(
                secondary: const Icon(Icons.notifications, color: Colors.deepPurple),
                title: const Text('Enable Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                value: _notificationsEnabled,
                onChanged: (val) {
                  setState(() => _notificationsEnabled = val);
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.language, color: Colors.deepPurple),
                title: const Text('Language', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: DropdownButton<String>(
                  value: _selectedLanguage,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'English', child: Text('English')),
                    DropdownMenuItem(value: 'Kinyarwanda', child: Text('Kinyarwanda')),
                    DropdownMenuItem(value: 'French', child: Text('French')),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedLanguage = val!);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: SwitchListTile(
                secondary: const Icon(Icons.dark_mode, color: Colors.deepPurple),
                title: const Text('Dark Theme', style: TextStyle(fontWeight: FontWeight.bold)),
                value: _darkTheme,
                onChanged: (val) {
                  setState(() => _darkTheme = val);
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
} 