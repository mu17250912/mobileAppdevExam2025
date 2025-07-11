import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ads/ad_service.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: const Center(child: Text('Please sign in to view analytics.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
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
          final canceled = goals.where((g) => g['status'] == 'canceled').length;
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Goals: $total',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'In Progress: $inProgress',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Completed: $completed',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Canceled: $canceled',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Completion Rate: ${(progress * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      insight,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Progress Chart',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 16,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const BannerAdWidget(),
            ],
          );
        },
      ),
    );
  }
}
