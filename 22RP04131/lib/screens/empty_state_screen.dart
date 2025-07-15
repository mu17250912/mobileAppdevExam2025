import 'package:flutter/material.dart';
import '../config/design_system.dart';
import 'package:go_router/go_router.dart';

class EmptyStateScreen extends StatelessWidget {
  const EmptyStateScreen({Key? key}) : super(key: key);

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
        title: const Text('Invoices', style: AppTypography.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.textSecondary),
            onPressed: () {}, // TODO: Show filter options
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.description, size: 64, color: AppColors.gray400),
              ),
              const SizedBox(height: 24),
              const Text(
                'No invoices yet',
                style: AppTypography.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'You haven\'t created any invoices yet. Start by creating your first professional invoice.',
                style: AppTypography.bodyLarge,
                textAlign: TextAlign.center,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Create First Invoice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: AppTypography.labelLarge,
                ),
                onPressed: () => context.go('/document-selection'),
              ),
              const SizedBox(height: 32),
              Column(
                children: [
                  const Text(
                    'Need help getting started?',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {}, // TODO: Show tutorial
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary, textStyle: AppTypography.bodyMedium),
                    child: const Text('View Tutorial'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 