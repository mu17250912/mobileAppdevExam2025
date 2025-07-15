import 'package:flutter/material.dart';
import '../config/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/models.dart'; // Make sure Document model is imported
import 'empty_state_screen.dart';

class DocumentHistoryScreen extends StatefulWidget {
  const DocumentHistoryScreen({Key? key}) : super(key: key);

  @override
  State<DocumentHistoryScreen> createState() => _DocumentHistoryScreenState();
}

class _DocumentHistoryScreenState extends State<DocumentHistoryScreen> {
  String selectedFilter = 'All';

  final List<String> filters = [''];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return StreamBuilder<List<Document>>(
      stream: appState.documentsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error loading documents')),
          );
        }

        final docs = snapshot.data ?? [];

        // Optional filtering
        final filteredDocs = selectedFilter == 'All'
            ? docs
            : docs.where((d) => d.type.name.toLowerCase() == selectedFilter.toLowerCase()).toList();

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
            title: const Text('Document History', style: AppTypography.titleMedium),
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: filters.map((filter) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: selectedFilter == filter,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selectedFilter == filter
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        onSelected: (_) => setState(() => selectedFilter = filter),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: filteredDocs.isEmpty
                    ? const EmptyStateScreen()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          return DocumentListItem(
                            documentNumber: doc.number,
                            clientName: doc.clientInfo.name,
                            total: doc.total,
                            status: doc.status.name,
                            date: '${doc.createdDate.day}/${doc.createdDate.month}/${doc.createdDate.year}',
                            onTap: () => context.go('/document-detail?id=${doc.id}'),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DocumentListItem extends StatelessWidget {
  final String documentNumber;
  final String clientName;
  final double total;
  final String status;
  final String date;
  final VoidCallback onTap;

  const DocumentListItem({
    required this.documentNumber,
    required this.clientName,
    required this.total,
    required this.status,
    required this.date,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'overdue':
        return AppColors.error;
      default:
        return AppColors.gray500;
    }
  }

  Color _getStatusTextColor() {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'pending':
      case 'overdue':
        return Colors.white;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.green100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.description, color: AppColors.primary),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(documentNumber, style: AppTypography.bodyLarge),
                  Text(clientName, style: AppTypography.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('RWF ${total.toStringAsFixed(2)}', style: AppTypography.bodyLarge),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: AppTypography.bodySmall.copyWith(
                      color: _getStatusTextColor(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date, style: AppTypography.bodySmall),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.gray400),
            ],
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
