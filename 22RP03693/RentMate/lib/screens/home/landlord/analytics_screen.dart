import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/property_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/payment_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<PaymentRecord> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() { _isLoading = true; });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) {
      setState(() { _isLoading = false; });
      return;
    }
    // For demo: get all payments for this landlord (simulate with PaymentService or Firestore as in PaymentManagementScreen)
    // Here, you may need to adjust to your actual payment fetching logic
    final paymentService = PaymentService();
    // For demo, use user.id as key (adjust as needed)
    final payments = await paymentService.getPaymentHistory(user.id);
    setState(() {
      _payments = payments;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final properties = propertyProvider.properties;
    final int totalProperties = properties.length;
    final completedPayments = _payments.where((p) => p.status == PaymentStatus.completed).toList();
    final int totalBookings = completedPayments.length;
    final double totalRevenue = completedPayments.fold(0.0, (sum, p) => sum + p.amount);
    final double avgRating = properties.isNotEmpty
        ? properties.map((p) => p.rating).reduce((a, b) => a + b) / properties.length
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatCard('Properties', totalProperties.toString(), Icons.home_work, Colors.blue),
                const SizedBox(width: 16),
                _buildStatCard('Bookings', totalBookings.toString(), Icons.book_online, Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                      _buildStatCard('Revenue', 'RWF ${totalRevenue.toStringAsFixed(0)}', Icons.attach_money, Colors.orange),
                const SizedBox(width: 16),
                _buildStatCard('Avg. Rating', avgRating.toStringAsFixed(1), Icons.star, Colors.amber),
              ],
            ),
            const SizedBox(height: 32),
            Text('Revenue Trend', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('Simple revenue chart (mock)')),
            ),
            const SizedBox(height: 32),
            Text('Booking Trend', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
                  // You can add a booking trend chart here
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 