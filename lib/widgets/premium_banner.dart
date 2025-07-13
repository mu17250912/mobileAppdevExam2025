import 'package:flutter/material.dart';

class PremiumBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onUpgradePressed;
  final Color? backgroundColor;
  final Color? textColor;

  const PremiumBanner({
    super.key,
    this.title = 'Upgrade to Premium',
    this.subtitle = 'Unlock unlimited features and premium content',
    this.onUpgradePressed,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: backgroundColor != null
              ? [backgroundColor!, backgroundColor!.withOpacity(0.8)]
              : const [Colors.amber, Colors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star,
            color: textColor ?? Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: (textColor ?? Colors.white).withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onUpgradePressed ?? () {
              Navigator.pushNamed(context, '/subscription');
            },
            child: Text(
              'Upgrade',
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 