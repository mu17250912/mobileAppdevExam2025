import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

class CaregiverAnalyticsScreen extends StatefulWidget {
  const CaregiverAnalyticsScreen({super.key});

  @override
  State<CaregiverAnalyticsScreen> createState() => _CaregiverAnalyticsScreenState();
}

class _CaregiverAnalyticsScreenState extends State<CaregiverAnalyticsScreen> {
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
        final analytics = await _analyticsService.getCaregiverAnalytics(
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
        title: const Text('Caregiver Analytics'),
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
                        Icons.people,
                        size: 32,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Caregiver Analytics',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Monitor all your patients\' adherence',
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
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Patients Assigned',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Patients will appear here once they assign themselves to you',
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
          
          // Overall Summary
          _buildOverallSummary(),
          
          const SizedBox(height: 20),
          
          // Patient List
          _buildPatientList(),
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

  Widget _buildOverallSummary() {
    final summary = _analytics['summary'] as Map<String, dynamic>? ?? {};
    final averageAdherence = _analytics['averageAdherence'] as double? ?? 0;
    final totalPatients = _analytics['totalPatients'] as int? ?? 0;
    
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
            'Overall Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Average Adherence',
                  '${averageAdherence.toStringAsFixed(1)}%',
                  Colors.green,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Total Patients',
                  '$totalPatients',
                  Colors.blue,
                  Icons.people,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Doses',
                  '${summary['totalDoses'] ?? 0}',
                  Colors.orange,
                  Icons.medication,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Total Taken',
                  '${summary['totalTaken'] ?? 0}',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
            ],
          ),
        ],
      ),
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

  Widget _buildPatientList() {
    final patients = _analytics['patients'] as List<dynamic>? ?? [];
    
    if (patients.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Patient Analytics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...patients.map((patientData) {
          final patient = patientData['patient'] as Map<String, dynamic>? ?? {};
          final analytics = patientData['analytics'] as Map<String, dynamic>? ?? {};
          final summary = analytics['summary'] as Map<String, dynamic>? ?? {};
          final adherence = analytics['overallAdherence'] as double? ?? 0;
          final streakData = analytics['streakData'] as Map<String, dynamic>? ?? {};

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        (patient['name'] as String? ?? 'P')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient['name'] ?? 'Unknown Patient',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            patient['email'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: adherence >= 80 
                            ? Colors.green.withValues(alpha: 0.1)
                            : adherence >= 60 
                                ? Colors.orange.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: adherence >= 80 
                              ? Colors.green
                              : adherence >= 60 
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                      child: Text(
                        '${adherence.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: adherence >= 80 
                              ? Colors.green
                              : adherence >= 60 
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Adherence Progress
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Adherence',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${adherence.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
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
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Quick Stats
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickStat(
                        'Doses',
                        '${summary['totalDoses'] ?? 0}',
                        Icons.medication,
                      ),
                    ),
                    Expanded(
                      child: _buildQuickStat(
                        'Taken',
                        '${summary['takenDoses'] ?? 0}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildQuickStat(
                        'Missed',
                        '${summary['missedDoses'] ?? 0}',
                        Icons.cancel,
                        Colors.red,
                      ),
                    ),
                    Expanded(
                      child: _buildQuickStat(
                        'Streak',
                        '${streakData['currentStreak'] ?? 0}',
                        Icons.local_fire_department,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewDetailedAnalytics(patient['id'], patient['name']),
                        icon: const Icon(Icons.analytics, size: 16),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewPatientAdherence(patient['id'], patient['name']),
                        icon: const Icon(Icons.history, size: 16),
                        label: const Text('Adherence'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? Colors.grey.shade600,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.grey.shade800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _viewDetailedAnalytics(String patientId, String patientName) {
    // Navigate to detailed patient analytics
    Navigator.pushNamed(
      context,
      '/patient_analytics',
      arguments: {'patientId': patientId, 'patientName': patientName},
    );
  }

  void _viewPatientAdherence(String patientId, String patientName) {
    // Navigate to patient adherence screen
    Navigator.pushNamed(
      context,
      '/patient_adherence',
      arguments: {'patientId': patientId, 'patientName': patientName},
    );
  }
} 