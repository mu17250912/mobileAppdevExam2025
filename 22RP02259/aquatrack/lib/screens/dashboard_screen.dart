import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/water_log_service.dart';
import '../widgets/usage_chart.dart';
import 'log_water_screen.dart';

class DashboardScreen extends StatelessWidget {
  final User user;
  final WaterLogService waterLogService;
  const DashboardScreen({Key? key, required this.user, required this.waterLogService}) : super(key: key);

  void _showPlaceholder(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('This feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todaysLogs = waterLogService.todaysLogs;
    final totalAmount = todaysLogs.fold<double>(0, (sum, log) => sum + log.amount);
    final activityCount = todaysLogs.length;
    // This week's logs
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekLogs = waterLogService.allLogs.where((log) {
      final d = log.timestamp;
      return d.isAfter(weekStart.subtract(const Duration(days: 1))) && d.isBefore(now.add(const Duration(days: 1)));
    }).toList();
    final weekTotal = weekLogs.fold<double>(0, (sum, log) => sum + log.amount);
    // Goal progress (dummy for now)
    final goalPercent = user.waterUsageGoalPercent;
    final goalTarget = weekTotal > 0 ? weekTotal * (1 - goalPercent / 100) : 0;
    return Scaffold(
      appBar: AppBar(title: const Text('AquTrack Dashboard!!')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.water_drop, size: 32, color: Colors.blue.shade700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user is dynamic && (user as dynamic).email != null ? (user as dynamic).email : 'Welcome!',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'AquTrack User',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF1976D2)),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                _showPlaceholder(context, 'Profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Color(0xFF1976D2)),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                _showPlaceholder(context, 'Settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.subscriptions, color: Color(0xFF1976D2)),
              title: const Text('Subscription'),
              onTap: () {
                Navigator.pop(context);
                _showPlaceholder(context, 'Subscription');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        child: const Text('Logout', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Welcome, household of \\${user.householdSize}!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 18),
            // Today Card
            Card(
              color: Colors.blue.shade700,
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Water Usageeee",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      totalAmount == 0 ? 'No usage logged yet.' :
                        '${totalAmount.toStringAsFixed(1)} units',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      activityCount == 1
                        ? '1 activity logged'
                        : '$activityCount activities logged',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // This Week Card
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Goal Progress Card
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
            // Usage Chart
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