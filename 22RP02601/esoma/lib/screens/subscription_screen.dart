import 'package:flutter/material.dart';
import '../notifications_manager.dart';
import '../main.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  void _showConfirmation(BuildContext rootContext, String plan, String price) {
    if (plan == 'Free Trial') {
      // Log analytics event for starting free trial
      analytics.logEvent(name: 'subscribe', parameters: {'plan': 'Free Trial'});
      showDialog(
        context: rootContext,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Free Trial Started'),
          content: const Text('You have started your free trial! Enjoy premium features for 7 days.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      NotificationsManager.add(
        title: 'Free Trial Started',
        message: 'You started a free trial. Enjoy premium features for 7 days.',
        type: 'info',
        imageUrl: null,
      );
    } else {
      // Log analytics event for paid subscription attempt
      analytics.logEvent(name: 'subscribe', parameters: {'plan': plan, 'price': price});
      _showPaymentMethods(rootContext, plan, price);
    }
  }

  void _showPaymentMethods(BuildContext rootContext, String plan, String price) {
    showModalBottomSheet(
      context: rootContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose Payment Method',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue[900])),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _paymentMethodTile(
                    rootContext,
                    icon: Image.asset('assets/momo.png', height: 32, errorBuilder: (context, error, stackTrace) => const Icon(Icons.phone_android, color: Colors.green)),
                    label: 'MoMo',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showMomoDialog(rootContext, plan, price);
                    },
                  ),
                  _paymentMethodTile(
                    rootContext,
                    icon: Image.asset('assets/paypal.png', height: 32, errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance_wallet, color: Colors.blue)),
                    label: 'PayPal',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showInputDialog(rootContext, plan, price, 'PayPal', 'PayPal Email', 'example@paypal.com');
                    },
                  ),
                  _paymentMethodTile(
                    rootContext,
                    icon: Image.asset('assets/paytm.png', height: 32, errorBuilder: (context, error, stackTrace) => const Icon(Icons.qr_code, color: Colors.indigo)),
                    label: 'Paytm',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showInputDialog(rootContext, plan, price, 'Paytm', 'Paytm Number', '1234567890');
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _paymentMethodTile(BuildContext rootContext, {required Widget icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blue[100]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showMomoDialog(BuildContext rootContext, String plan, String price) {
    final phoneController = TextEditingController();
    final pinController = TextEditingController();
    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Image.asset('assets/momo.png', height: 28, errorBuilder: (context, error, stackTrace) => const Icon(Icons.phone_android, color: Colors.green)),
            const SizedBox(width: 8),
            const Text('MoMo Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your MoMo number and PIN to proceed with $plan payment of $price.'),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'MoMo Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'MoMo PIN',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (phoneController.text.trim().isEmpty || pinController.text.trim().isEmpty) {
                ScaffoldMessenger.of(rootContext).showSnackBar(const SnackBar(content: Text('Please enter all required details.')));
                return;
              }
              Navigator.pop(dialogContext);
              _showPaymentDetails(rootContext, plan, price, 'MoMo', 'Number: ${phoneController.text}, PIN: ${pinController.text}');
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _showInputDialog(BuildContext rootContext, String plan, String price, String method, String label, String hint) {
    final controller = TextEditingController();
    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: Text('$method Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your $label to proceed with $plan payment of $price.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), hintText: hint),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(rootContext).showSnackBar(SnackBar(content: Text('Please enter your $label.')));
                return;
              }
              Navigator.pop(dialogContext);
              _showPaymentDetails(rootContext, plan, price, method, '$label: ${controller.text}');
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetails(BuildContext rootContext, String plan, String price, String method, String details) {
    NotificationsManager.add(
      title: 'Payment Successful',
      message: '[$method] $plan payment of $price. Details: $details',
      type: 'payment',
      imageUrl: null,
    );
    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: Text('$method Payment Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan: $plan'),
            Text('Amount: $price'),
            Text('Details: $details'),
            const SizedBox(height: 16),
            const Text('Payment instructions have been sent to your notifications.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Done')),
        ],
      ),
    );
    ScaffoldMessenger.of(rootContext).showSnackBar(SnackBar(
      content: Text('[$method] $plan payment details sent to notifications.'),
      backgroundColor: Colors.blue[800],
    ));
  }

  Widget _buildOption({
    required BuildContext context,
    required String title,
    required String description,
    required String price,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isTrial = false,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: isTrial ? Colors.green[50] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.15), radius: 32, child: Icon(icon, color: color, size: 36)),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
            const SizedBox(height: 16),
            if (price.isNotEmpty) Text(price, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 18),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: onPressed,
              child: Text(isTrial ? 'Start Free Trial' : 'Choose'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription'), backgroundColor: Colors.blue[800]),
      backgroundColor: Colors.blue[50],
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text(
                  'Upgrade Your Experience',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue[900], letterSpacing: 1.1),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Unlock all features and enjoy unlimited access.',
                  style: TextStyle(fontSize: 16, color: Colors.blueGrey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (isSmallScreen)
                  Column(
                    children: [
                      _buildOption(
                        context: context,
                        title: 'Free Trial',
                        description: 'Try premium features free for 7 days. No payment required.',
                        price: '',
                        icon: Icons.hourglass_top_rounded,
                        color: Colors.green,
                        isTrial: true,
                        onPressed: () => _showConfirmation(context, 'Free Trial', ''),
                      ),
                      const SizedBox(height: 16),
                      _buildOption(
                        context: context,
                        title: 'Premium',
                        description: 'Access all features for a one-time payment.',
                        price: '\$5',
                        icon: Icons.star_rounded,
                        color: Colors.amber[800]!,
                        onPressed: () => _showConfirmation(context, 'Premium', '\$5'),
                      ),
                      const SizedBox(height: 16),
                      _buildOption(
                        context: context,
                        title: 'Lifetime',
                        description: 'Enjoy lifetime access to all features.',
                        price: '\$20',
                        icon: Icons.workspace_premium_rounded,
                        color: Colors.blue[800]!,
                        onPressed: () => _showConfirmation(context, 'Lifetime', '\$20'),
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildOption(
                          context: context,
                          title: 'Free Trial',
                          description: 'Try premium features free for 7 days. No payment required.',
                          price: '',
                          icon: Icons.hourglass_top_rounded,
                          color: Colors.green,
                          isTrial: true,
                          onPressed: () => _showConfirmation(context, 'Free Trial', ''),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildOption(
                          context: context,
                          title: 'Premium',
                          description: 'Access all features for a one-time payment.',
                          price: '\$5',
                          icon: Icons.star_rounded,
                          color: Colors.amber[800]!,
                          onPressed: () => _showConfirmation(context, 'Premium', '\$5'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildOption(
                          context: context,
                          title: 'Lifetime',
                          description: 'Enjoy lifetime access to all features.',
                          price: '\$20',
                          icon: Icons.workspace_premium_rounded,
                          color: Colors.blue[800]!,
                          onPressed: () => _showConfirmation(context, 'Lifetime', '\$20'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 40),
                Container(
                  width: double.infinity,
                  color: Colors.blueGrey[50],
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copyright, size: 18, color: Colors.blueGrey),
                        SizedBox(width: 6),
                        Text(
                          'Powered by Esoma • Secure & Fast Payment',
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
