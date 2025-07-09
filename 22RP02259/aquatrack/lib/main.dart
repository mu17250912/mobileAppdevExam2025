import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/create_account_screen.dart';
import 'screens/log_water_screen.dart';
import 'models/user.dart';
import 'services/water_log_service.dart';
import 'widgets/usage_chart.dart';

void main() {
  runApp(const WaterSaverApp());
}

class WaterSaverApp extends StatefulWidget {
  const WaterSaverApp({Key? key}) : super(key: key);

  @override
  State<WaterSaverApp> createState() => _WaterSaverAppState();
}

class _WaterSaverAppState extends State<WaterSaverApp> {
  User? _user;
  bool _splashDone = false;
  bool _loggedIn = false;
  bool _showOnboarding = false;
  bool _showCreateAccount = false;
  bool _isNewlyRegistered = false;
  final WaterLogService _waterLogService = WaterLogService();

  void _finishSplash() {
    setState(() {
      _splashDone = true;
    });
  }

  void _onLogin(User user) {
    setState(() {
      _user = user;
      _loggedIn = true;
      _showOnboarding = false;
      _isNewlyRegistered = false;
    });
  }

  void _onOnboardingComplete(User user) {
    setState(() {
      _user = user;
      _showOnboarding = false;
      _isNewlyRegistered = false;
    });
    print('User setup: \n');
    print('Household size: \${user.householdSize}');
    print('Avg bill: \${user.averageWaterBill}');
    print('Goal: \${user.waterUsageGoalPercent}%');
    print('Smart meter: \${user.usesSmartMeter}');
  }

  void _onCreateAccount() {
    setState(() {
      _showCreateAccount = true;
    });
  }

  void _onAccountCreated() {
    setState(() {
      _showCreateAccount = false;
      _showOnboarding = true;
      _isNewlyRegistered = true;
      _loggedIn = true;
    });
  }

  void _onBackToLogin() {
    setState(() {
      _showCreateAccount = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquTrack',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: !_splashDone
          ? SplashScreen(onFinish: _finishSplash)
          : _showCreateAccount
              ? CreateAccountScreen(
                  onAccountCreated: _onAccountCreated,
                  onBackToLogin: _onBackToLogin,
                )
              : _showOnboarding
                  ? OnboardingScreen(onComplete: _onOnboardingComplete)
                  : !_loggedIn
                      ? LoginScreen(onLogin: _onLogin, onCreateAccount: _onCreateAccount)
                      : HomeScreen(user: _user!, waterLogService: _waterLogService),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final User user;
  final WaterLogService waterLogService;
  const HomeScreen({Key? key, required this.user, required this.waterLogService}) : super(key: key);

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
      appBar: AppBar(title: const Text('AquTrack Dashboard')),
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
