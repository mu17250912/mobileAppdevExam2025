import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import 'custom_button.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

class PremiumUpgradeDialog extends StatefulWidget {
  const PremiumUpgradeDialog({Key? key}) : super(key: key);

  @override
  State<PremiumUpgradeDialog> createState() => _PremiumUpgradeDialogState();
}

class _PremiumUpgradeDialogState extends State<PremiumUpgradeDialog> {
  bool _isProcessing = false;

  Future<void> _upgradeToPremium() async {
    setState(() {
      _isProcessing = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.upgradeToPremium();

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully upgraded to Premium!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Upgrade failed'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _openPayPalCheckout() async {
    if (kIsWeb) {
      // Open PayPal in a new tab on web
      const paypalUrl = 'https://www.sandbox.paypal.com/checkoutnow?token=YOUR_TOKEN_HERE';
      if (await canLaunchUrl(Uri.parse(paypalUrl))) {
        await launchUrl(Uri.parse(paypalUrl), webOnlyWindowName: '_blank');
      }
      // You may want to show a message to the user to complete payment and then click 'Upgrade' again
      return;
    }
    // Mobile: use WebView
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const PayPalWebView(),
    );
    if (result == true) {
      // Payment successful, upgrade user
      await _upgradeToPremium();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white, AppTheme.backgroundColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber, Colors.orange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                'Upgrade to Premium',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                'Unlock all features and enhance your learning experience',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Features List
              _buildFeatureItem(
                Icons.quiz,
                'Unlimited Quizzes',
                'Take as many quizzes as you want',
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                Icons.trending_up,
                'Progress Tracking',
                'Detailed analytics and insights',
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                Icons.dark_mode,
                'Dark Mode',
                'Study comfortably in any lighting',
              ),
              const SizedBox(height: 24),
              // Price Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Special Offer: ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      'FREE',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      ' (Limited Time)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Maybe Later',
                      onPressed: () => Navigator.pop(context),
                      isOutlined: true,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Pay with PayPal',
                      onPressed: _isProcessing ? null : _openPayPalCheckout,
                      isLoading: _isProcessing,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Terms
              Text(
                'By upgrading, you agree to our terms of service',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.check_circle,
          color: AppTheme.successColor,
          size: 20,
        ),
      ],
    );
  }
}

// Add PayPalWebView widget
class PayPalWebView extends StatefulWidget {
  const PayPalWebView({Key? key}) : super(key: key);

  @override
  State<PayPalWebView> createState() => _PayPalWebViewState();
}

class _PayPalWebViewState extends State<PayPalWebView> {
  late final WebViewController _controller;
  bool _loading = true;

  // Replace with your real PayPal checkout URL
  final String paypalUrl = 'https://www.sandbox.paypal.com/checkoutnow?token=YOUR_TOKEN_HERE';
  final String successUrl = 'https://your-success-url.com/';
  final String cancelUrl = 'https://your-cancel-url.com/';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _loading = true);
          },
          onPageFinished: (url) {
            setState(() => _loading = false);
            if (url.startsWith(successUrl)) {
              Navigator.of(context).pop(true);
            } else if (url.startsWith(cancelUrl)) {
              Navigator.of(context).pop(false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(paypalUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 400,
        height: 600,
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
} 