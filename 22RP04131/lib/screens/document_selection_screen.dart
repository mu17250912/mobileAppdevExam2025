import 'package:flutter/material.dart';
import '../config/design_system.dart';
import 'package:go_router/go_router.dart';

class DocumentSelectionScreen extends StatelessWidget {
  const DocumentSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: const Text('Create Document', style: AppTypography.titleMedium),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Choose the type of document you want to create',
              style: AppTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  DocumentTypeCard(
                    title: 'Invoice',
                    description: 'Bill your clients professionally',
                    icon: Icons.description,
                    gradientColors: const [AppColors.success, AppColors.primary],
                    onTap: () => context.go('/document-form?type=invoice'),
                  ),
                  DocumentTypeCard(
                    title: 'Price Quote',
                    description: 'Send price estimates',
                    icon: Icons.attach_money,
                    gradientColors: const [AppColors.secondary, AppColors.orange500],
                    onTap: () => context.go('/document-form?type=quote'),
                  ),
                  DocumentTypeCard(
                    title: 'Proforma Invoice',
                    description: 'Preliminary bill of sale',
                    icon: Icons.description,
                    gradientColors: const [AppColors.blue100, AppColors.blue600],
                    onTap: () => context.go('/document-form?type=proforma'),
                  ),
                  DocumentTypeCard(
                    title: 'Delivery Note',
                    description: 'Track deliveries',
                    icon: Icons.local_shipping,
                    gradientColors: const [AppColors.purple500, AppColors.purple500],
                    onTap: () => context.go('/document-form?type=delivery_note'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DocumentTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const DocumentTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: Colors.white),
                const SizedBox(height: 16),
                Text(title, style: AppTypography.titleMedium.copyWith(color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(description, style: AppTypography.bodySmall.copyWith(color: Colors.white.withOpacity(0.8)), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 