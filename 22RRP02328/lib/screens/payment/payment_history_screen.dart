import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../models/payment_model.dart';
import '../../utils/constants.dart';
import 'package:get/get.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllPayments());
  }

  void _loadAllPayments() {
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    paymentProvider.loadAllPayments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, child) {
          if (paymentProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (paymentProvider.payments.isEmpty) {
            return const Center(child: Text('No payments found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: paymentProvider.payments.length,
            itemBuilder: (context, index) {
              final payment = paymentProvider.payments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    payment.method == 'momo'
                        ? Icons.phone_android
                        : payment.method == 'card'
                            ? Icons.credit_card
                            : Icons.money,
                    color: const Color(AppColors.primaryColor),
                  ),
                  title: Text(
                    '${payment.amount.toStringAsFixed(0)} ${payment.currency}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Name: ${payment.fullName}\nTel: ${payment.telephone}\nCharges: ${payment.charges.toStringAsFixed(0)} RWF\nStatus: ${payment.status}\nMethod: ${payment.method}\nDate: ${payment.createdAt.toLocal().toString().split(".")[0]}',
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/payment'),
        icon: const Icon(Icons.add),
        label: const Text('Make Payment'),
      ),
    );
  }
} 