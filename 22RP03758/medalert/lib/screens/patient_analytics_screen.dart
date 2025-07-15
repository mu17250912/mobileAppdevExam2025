import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/analytics_service.dart';

class PatientAnalyticsScreen extends StatefulWidget {
  const PatientAnalyticsScreen({super.key});

  @override
  State<PatientAnalyticsScreen> createState() => _PatientAnalyticsScreenState();
}

class _PatientAnalyticsScreenState extends State<PatientAnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;
  String _selectedPeriod = '30'; // days
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final analytics = await _analyticsService.getPatientAnalytics(
          user.uid,
          startDate: _startDate,
          endDate: _endDate,
        );

        setState(() {
          _analytics = analytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      final now = DateTime.now();
      
      switch (period) {
        case '7':
          _startDate = now.subtract(const Duration(days: 7));
          break;
        case '30':
          _startDate = now.subtract(const Duration(days: 30));
          break;
        case '90':
          _startDate = now.subtract(const Duration(days: 90));
          break;
        case '365':
          _startDate = now.subtract(const Duration(days: 365));
          break;
      }
      _endDate = now;
    });

    _loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1976D2),
              Color(0xFF42A5F5),
              Color(0xFF90CAF9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.analytics,
                        size: 32,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Analytics & Reports',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Track your medication adherence patterns',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        )
                      : _analytics.isEmpty
                          ? _buildEmptyState()
                          : _buildAnalyticsContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Analytics Data',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start taking medications to see your analytics',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector
          _buildPeriodSelector(),
          
          const SizedBox(height: 20),
          
          // Summary Cards
          _buildSummaryCards(),
          
          const SizedBox(height: 20),
          
          // Daily Adherence Chart
          _buildDailyAdherenceChart(),
          
          const SizedBox(height: 20),
          
          // Medication Breakdown
          _buildMedicationBreakdown(),
          
          const SizedBox(height: 20),
          
          // Streak Information
          _buildStreakInfo(),
          
          const SizedBox(height: 20),
          
          // Missed Doses Analysis
          _buildMissedDosesAnalysis(),
          
          const SizedBox(height: 20),
          
          // Time of Day Analysis
          _buildTimeOfDayAnalysis(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Time Period',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPeriodButton('7', '7 Days'),
              const SizedBox(width: 8),
              _buildPeriodButton('30', '30 Days'),
              const SizedBox(width: 8),
              _buildPeriodButton('90', '90 Days'),
              const SizedBox(width: 8),
              _buildPeriodButton('365', '1 Year'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => _changePeriod(period),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.blue,
          elevation: isSelected ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final summary = _analytics['summary'] as Map<String, dynamic>? ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Overall Adherence',
                '${summary['adherence']?.toStringAsFixed(1) ?? '0'}%',
                Colors.green,
                Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Total Doses',
                '${summary['totalDoses'] ?? 0}',
                Colors.blue,
                Icons.medication,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Taken Doses',
                '${summary['takenDoses'] ?? 0}',
                Colors.green,
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Missed Doses',
                '${summary['missedDoses'] ?? 0}',
                Colors.red,
                Icons.cancel,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyAdherenceChart() {
    final dailyData = _analytics['dailyAdherence'] as List<dynamic>? ?? [];
    
    if (dailyData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Adherence',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _buildBarChart(dailyData),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<dynamic> data) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index] as Map<String, dynamic>;
        final adherence = item['adherence'] as double? ?? 0;
        final date = item['date'] as String? ?? '';
        final height = (adherence / 100) * 150; // Max height 150

        return Container(
          width: 30,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 20,
                height: height,
                decoration: BoxDecoration(
                  color: adherence >= 80 
                      ? Colors.green 
                      : adherence >= 60 
                          ? Colors.orange 
                          : Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MM/dd').format(DateFormat('yyyy-MM-dd').parse(date)),
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMedicationBreakdown() {
    final medicationData = _analytics['medicationBreakdown'] as List<dynamic>? ?? [];
    
    if (medicationData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Medication Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...medicationData.map((item) {
            final data = item as Map<String, dynamic>;
            final medication = data['medication'] as Map<String, dynamic>? ?? {};
            final adherence = data['adherence'] as double? ?? 0;
            final totalDoses = data['totalDoses'] as int? ?? 0;
            final takenDoses = data['takenDoses'] as int? ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication['name'] ?? 'Unknown Medication',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: adherence / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            adherence >= 80 
                                ? Colors.green 
                                : adherence >= 60 
                                    ? Colors.orange 
                                    : Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${adherence.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$takenDoses of $totalDoses doses taken',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStreakInfo() {
    final streakData = _analytics['streakData'] as Map<String, dynamic>? ?? {};
    final currentStreak = streakData['currentStreak'] as int? ?? 0;
    final longestStreak = streakData['longestStreak'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Streak Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStreakCard(
                  'Current Streak',
                  '$currentStreak days',
                  Colors.blue,
                  Icons.local_fire_department,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStreakCard(
                  'Longest Streak',
                  '$longestStreak days',
                  Colors.orange,
                  Icons.emoji_events,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMissedDosesAnalysis() {
    final missedData = _analytics['missedDoses'] as Map<String, dynamic>? ?? {};
    final totalMissed = missedData['totalMissed'] as int? ?? 0;
    final mostMissedHour = missedData['mostMissedHour'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Missed Doses Analysis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMissedCard(
                  'Total Missed',
                  '$totalMissed doses',
                  Colors.red,
                  Icons.cancel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMissedCard(
                  'Most Missed Time',
                  '$mostMissedHour:00',
                  Colors.orange,
                  Icons.access_time,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissedCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeOfDayAnalysis() {
    final timeData = _analytics['timeOfDayAnalysis'] as Map<String, dynamic>? ?? {};
    final timeDistribution = timeData['timeDistribution'] as Map<String, dynamic>? ?? {};
    final mostCommonHour = timeData['mostCommonHour'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Time of Day Analysis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Most common time for taking medications: $mostCommonHour:00',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (timeDistribution.isNotEmpty) ...[
            const Text(
              'Time Distribution:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...timeDistribution.entries.map((entry) {
              final hour = int.parse(entry.key);
              final count = entry.value as int;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: count / (timeDistribution.values.reduce((a, b) => a > b ? a : b) as int),
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$count',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
} 