import 'package:flutter/material.dart';
import '../config/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/models.dart';
import '../screens/document_form_screen.dart'; // Added import for DocumentFormScreen
import 'package:badges/badges.dart' as badges;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedFilter = 'All';
  final List<String> filters = ['All', 'Pending', 'Paid', 'Overdue', 'Draft'];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    // Show loading only if user profile is not loaded yet (and user is logged in)
    if (appState.currentUser != null && appState.userProfile == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading profile...', style: AppTypography.bodyMedium),
            ],
          ),
        ),
      );
    }
    
    return StreamBuilder<List<Document>>(
      stream: appState.documentsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading documents'));
        }
        final docs = snapshot.data ?? [];
        // Filtering logic
        List<Document> filteredDocs = selectedFilter == 'All'
            ? docs
            : docs.where((d) => d.status.toString().split('.').last.toLowerCase() == selectedFilter.toLowerCase()).toList();
        // Recent documents (show 5 most recent)
        final recentDocs = docs.take(5).toList();
        final invoices = docs.where((d) => d.type == DocumentType.invoice).length;
        final quotes = docs.where((d) => d.type == DocumentType.quote).length;
        final pending = docs.where((d) => d.status == DocumentStatus.pending).length;
        final recent = docs.isNotEmpty ? docs.first : null;

        return StreamBuilder<List<NotificationItem>>(
          stream: appState.notificationsStream(),
          builder: (context, notifSnapshot) {
            final notifications = notifSnapshot.data ?? [];
            final unreadCount = notifications.where((n) => !n.read).length;
            return Scaffold(
              backgroundColor: AppColors.background,
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.green800],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      appState.userProfile != null 
                                        ? 'Hi ${appState.userProfile!.name}! 👋' 
                                        : 'Hi! 👋',
                                      style: AppTypography.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                    ),
                                    Text('Ready to create documents?', style: AppTypography.bodyMedium.copyWith(color: AppColors.green100)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    // Offline indicator
                                    if (!appState.isInitialized || appState.currentUser == null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Offline',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    badges.Badge(
                                      showBadge: unreadCount > 0,
                                      badgeContent: Text(
                                        unreadCount.toString(),
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      badgeStyle: badges.BadgeStyle(
                                        badgeColor: Colors.redAccent,
                                        padding: const EdgeInsets.all(6),
                                        elevation: 0,
                                      ),
                                      position: badges.BadgePosition.topEnd(top: -6, end: -6),
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.18),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.08),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.notifications, color: Colors.white),
                                          onPressed: () => context.go('/notifications'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(child: _StunningDashboardStatCard(count: invoices, label: 'Invoices', color: Colors.orange, icon: Icons.description)),
                                const SizedBox(width: 12),
                                Expanded(child: _StunningDashboardStatCard(count: quotes, label: 'Quotes', color: AppColors.secondary, icon: null, customText: 'Q')),
                                const SizedBox(width: 12),
                                Expanded(child: _StunningDashboardStatCard(count: pending, label: 'Pending', color: Colors.orange, icon: Icons.timelapse)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Add filter buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: filters.map((filter) {
                            final isSelected = selectedFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Text(filter),
                                selected: isSelected,
                                onSelected: (_) => setState(() => selectedFilter = filter),
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      // Recent Documents section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Recent Documents', style: AppTypography.titleMedium),
                      ),
                      const SizedBox(height: 12),
                      if (recentDocs.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: recentDocs.length,
                          itemBuilder: (context, index) {
                            final doc = recentDocs[index];
                            return Card(
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.green100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.description, color: AppColors.primary),
                                ),
                                title: Text(doc.number, style: AppTypography.bodyLarge),
                                subtitle: Text(doc.clientInfo.name, style: AppTypography.bodySmall),
                                trailing: Text(doc.status.toString().split('.').last, style: AppTypography.bodySmall),
                                onTap: () => context.go('/document-detail?id=${doc.id}'),
                              ),
                            );
                          },
                        )
                      else
                        Text('No recent documents', style: AppTypography.bodyMedium),
                      const SizedBox(height: 24),
                      // Filtered Documents section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('${selectedFilter == 'All' ? 'All' : selectedFilter} Documents', style: AppTypography.titleMedium),
                      ),
                      const SizedBox(height: 12),
                      if (filteredDocs.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, index) {
                            final doc = filteredDocs[index];
                            return Card(
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.green100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.description, color: AppColors.primary),
                                ),
                                title: Text(doc.number, style: AppTypography.bodyLarge),
                                subtitle: Text(doc.clientInfo.name, style: AppTypography.bodySmall),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(doc.status.toString().split('.').last, style: AppTypography.bodySmall),
                                    if (doc.status == DocumentStatus.draft)
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => DocumentFormScreen(
                                                key: UniqueKey(),
                                                document: doc,
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text('Resume Draft'),
                                      ),
                                  ],
                                ),
                                onTap: () => context.go('/document-detail?id=${doc.id}'),
                              ),
                            );
                          },
                        )
                      else
                        Text('No documents found for this filter', style: AppTypography.bodyMedium),
                    ],
                  ),
                ),
              ),
              floatingActionButton: SizedBox(
                height: 72,
                width: 72,
                child: FloatingActionButton(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                  onPressed: () => context.go('/document-selection'),
                  child: const Icon(Icons.add, size: 38),
                  tooltip: 'New Document',
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}

class _DashboardStatCard extends StatelessWidget {
  final int count;
  final String label;
  const _DashboardStatCard({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(count.toString(), style: AppTypography.headlineMedium.copyWith(color: Colors.white)),
            Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.green100)),
          ],
        ),
      ),
    );
  }
}

class _StunningDashboardStatCard extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData? icon;
  final String? customText;

  const _StunningDashboardStatCard({
    required this.count,
    required this.label,
    required this.color,
    this.icon,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (icon != null)
            Icon(icon, size: 40, color: color)
          else if (customText != null)
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                customText!,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: AppTypography.headlineMedium.copyWith(color: label == 'Invoices' ? Colors.orange : color),
          ),
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.green100)),
        ],
      ),
    );
  }
}