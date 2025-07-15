import 'package:flutter/material.dart';
import '../services/sustainability_service.dart';
import '../services/firebase_analytics_service.dart';
import '../widgets/insight_card.dart';
import '../widgets/streak_widget.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final SustainabilityService _sustainabilityService = SustainabilityService();
  final FirebaseAnalyticsService _analyticsService = FirebaseAnalyticsService();
  
  List<RetentionInsight> _insights = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsights();
    _analyticsService.trackScreenView(screenName: 'insights_screen');
  }

  Future<void> _loadInsights() async {
    try {
      await _sustainabilityService.initialize();
      
      _sustainabilityService.insightsStream.listen((insights) {
        setState(() {
          _insights = insights;
          _isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load insights');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleInsightAction(RetentionInsight insight) {
    switch (insight.actionType) {
      case InsightActionType.addMedication:
        Navigator.pushNamed(context, '/medication/add');
        break;
      case InsightActionType.caregiverSetup:
        Navigator.pushNamed(context, '/caregiver/assign');
        break;
      case InsightActionType.enableNotifications:
        Navigator.pushNamed(context, '/settings');
        break;
      case InsightActionType.reminder:
        Navigator.pushNamed(context, '/home');
        break;
      case InsightActionType.celebrate:
      case InsightActionType.motivate:
        // Show celebration or motivation dialog
        _showMotivationDialog(insight);
        break;
    }
  }

  void _showMotivationDialog(RetentionInsight insight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(insight.title),
        content: Text(insight.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Insights'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadInsights();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInsights,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 24),
                    
                    // Streak widget
                    _buildStreakWidget(),
                    const SizedBox(height: 24),
                    
                    // Insights
                    _buildInsightsSection(),
                    const SizedBox(height: 24),
                    
                    // Tips and motivation
                    _buildTipsSection(),
                    const SizedBox(height: 24),
                    
                    // Progress summary
                    _buildProgressSummary(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Health Journey',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Personalized insights to help you stay on track',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStreakWidget() {
    // Find streak insight
    final streakInsight = _insights.where(
      (insight) => insight.type == RetentionInsightType.streak,
    ).firstOrNull;

    if (streakInsight != null) {
      return StreakWidget(insight: streakInsight);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start Your Streak',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Take your first medication to begin tracking your progress',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection() {
    if (_insights.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.lightbulb_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No insights yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start using the app to receive personalized insights and tips',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personalized Insights',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._insights.map((insight) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InsightCard(
            insight: insight,
            onAction: () => _handleInsightAction(insight),
          ),
        )),
      ],
    );
  }

  Widget _buildTipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tips for Success',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildTipCard(
          icon: Icons.schedule,
          title: 'Set Consistent Times',
          description: 'Take your medications at the same time each day to build a routine.',
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        
        _buildTipCard(
          icon: Icons.notifications,
          title: 'Enable Notifications',
          description: 'Turn on reminders to never miss a dose.',
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        
        _buildTipCard(
          icon: Icons.people,
          title: 'Involve Caregivers',
          description: 'Share your progress with family members for additional support.',
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        
        _buildTipCard(
          icon: Icons.analytics,
          title: 'Track Your Progress',
          description: 'Review your adherence reports to identify patterns and improve.',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                'Your Progress',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Every medication taken is a step toward better health. Keep up the great work!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/analytics'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green.shade600,
            ),
            child: const Text('View Detailed Analytics'),
          ),
        ],
      ),
    );
  }
} 