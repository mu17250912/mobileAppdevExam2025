import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/water_log_service.dart';
import '../screens/log_water_screen.dart';
import '../widgets/usage_chart.dart';

class DashboardPage extends StatelessWidget {
  final User user;
  final WaterLogService waterLogService;

  const DashboardPage({
    Key? key,
    required this.user,
    required this.waterLogService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final todaysLogs = waterLogService.todaysLogs;
    final totalAmount = todaysLogs.fold<double>(0, (sum, log) => sum + log.amount);
    final activityCount = todaysLogs.length;

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekLogs = waterLogService.allLogs.where((log) {
      final d = log.timestamp;
      return d.isAfter(weekStart.subtract(const Duration(days: 1))) && d.isBefore(now.add(const Duration(days: 1)));
    }).toList();
    final weekTotal = weekLogs.fold<double>(0, (sum, log) => sum + log.amount);

    final goalPercent = user.waterUsageGoalPercent;
    final goalTarget = weekTotal > 0 ? weekTotal * (1 - goalPercent / 100) : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to AquTrack Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Welcome, household of ${user.householdSize}!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 18),
            Card(
              color: Colors.blue.shade700,
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Water Usage",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      totalAmount == 0 ? 'No usage logged yet.' : '${totalAmount.toStringAsFixed(1)} units',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      activityCount == 1 ? '1 activity logged' : '$activityCount activities logged',
                      style: const TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              color: Colors.blue.shade600,
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "This Week's Usage",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      weekTotal == 0 ? 'No usage logged yet.' : '${weekTotal.toStringAsFixed(1)} units',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              color: Colors.blue.shade50,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Goal Progress',
                      style: TextStyle(
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      goalTarget == 0 ? 'Set a goal in onboarding.' : 'Target: ${goalTarget.toStringAsFixed(1)} units/week',
                      style: const TextStyle(
                        color: Color(0xFF1976D2),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (weekTotal > 0 && goalTarget > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: LinearProgressIndicator(
                          value: (weekTotal / goalTarget).clamp(0, 1),
                          backgroundColor: Colors.blue.shade100,
                          color: Colors.blue.shade700,
                          minHeight: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            UsageChart(logs: waterLogService.allLogs),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.water_drop),
                label: const Text('Log Water Usage'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LogWaterScreen(logService: waterLogService),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
