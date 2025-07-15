import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color mainColor = const Color(0xFFFFD600); // Lightning yellow
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.aboutBizTrackr),
        backgroundColor: mainColor,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.aboutHeadline,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: mainColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
              'BizTrackr empowers small business owners in Rwanda and beyond with easy, offline-first tools for sales, inventory, and customer management. Designed for simplicity, affordability, and local language support.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Text(AppLocalizations.of(context)!.keyFeatures, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              '• Offline-first, mobile-friendly app\n• Bilingual: Kinyarwanda & English\n• Simple inventory & sales tracking\n• Customer credit & loyalty management\n• Smart business insights & AI assistant\n• Affordable freemium model',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Text(AppLocalizations.of(context)!.ourVision, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('To help 10,000+ small business owners grow sustainably, save time, and make data-driven decisions—without needing an accountant or constant internet.'),
          ],
        ),
      ),
    );
  }
} 