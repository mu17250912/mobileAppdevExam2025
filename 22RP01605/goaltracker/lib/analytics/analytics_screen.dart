import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ads/ad_service.dart';
import '../shared/app_theme.dart';
import '../settings/theme_service.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final templateName = ThemeService.getCurrentTemplate();
    return FutureBuilder<String>(
      future: templateName,
      builder: (context, snapshot) {
        final templateData = ThemeService.getTemplateData(
          snapshot.data ?? 'Elegant Purple',
        );
        if (uid == null) {
          return Scaffold(
            backgroundColor: templateData['backgroundColor'],
            appBar: AppBar(
              title: const Text('Analytics'),
              backgroundColor: templateData['appBarColor'],
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Text('Please sign in to view analytics.'),
            ),
          );
        }

        return Scaffold(
          backgroundColor: templateData['backgroundColor'],
          appBar: AppBar(
            title: const Text('Analytics'),
            backgroundColor: templateData['appBarColor'],
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Analytics Info',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Analytics Explained'),
                      content: const Text(
                        'This screen shows your goal progress, completion rate, and current streak. The progress chart shows how many goals you\'ve completed vs. total goals.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Got it'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('goals')
                .where('uid', isEqualTo: uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final goals = snapshot.data!.docs;
              final total = goals.length;
              final completed = goals
                  .where((g) => g['status'] == 'completed')
                  .length;
              final inProgress = goals
                  .where((g) => g['status'] == 'in_progress')
                  .length;
              final canceled = goals
                  .where((g) => g['status'] == 'canceled')
                  .length;
              final progress = total > 0 ? completed / total : 0.0;

              String insight = '';
              if (total == 0) {
                insight = 'Start by adding your first goal!';
              } else if (completed == total) {
                insight = 'Amazing! You have completed all your goals.';
              } else if (completed > 0) {
                insight = 'Great job! Keep going to complete more goals.';
              } else if (inProgress > 0) {
                insight = 'You have goals in progress. Stay focused!';
              } else if (canceled == total) {
                insight = 'All your goals are canceled. Try setting new ones!';
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    child: Card(
                      color: templateData['cardColor'],
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          'Total Goals: $total',
                          style: TextStyle(
                            color: templateData['textColor'],
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    child: Card(
                      color: templateData['cardColor'],
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          'In Progress: $inProgress',
                          style: TextStyle(
                            color: templateData['textColor'],
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    child: Card(
                      color: templateData['cardColor'],
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          'Completed: $completed',
                          style: TextStyle(
                            color: templateData['textColor'],
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    child: Card(
                      color: templateData['cardColor'],
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          'Canceled: $canceled',
                          style: TextStyle(
                            color: templateData['textColor'],
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    child: Card(
                      color: templateData['cardColor'],
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          'Completion Rate: ${(progress * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: templateData['primaryColor'],
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    child: Card(
                      color: templateData['cardColor'],
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          insight,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: templateData['primaryColor'],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    child: Card(
                      color: templateData['cardColor'],
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Progress Chart',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 16,
                                    child: Stack(
                                      children: [
                                        // Background bar
                                        Container(
                                          decoration: BoxDecoration(
                                            color: templateData['primaryColor']
                                                .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        // In-progress (white) bar
                                        FractionallySizedBox(
                                          widthFactor: total > 0
                                              ? (inProgress + completed) / total
                                              : 0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                        // Completed (primary) bar
                                        FractionallySizedBox(
                                          widthFactor: total > 0
                                              ? completed / total
                                              : 0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  templateData['primaryColor'],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  total > 0
                                      ? '${(completed / total * 100).toStringAsFixed(0)}%'
                                      : '0%',
                                  style: TextStyle(
                                    color: templateData['primaryColor'],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const BannerAdWidget(),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
