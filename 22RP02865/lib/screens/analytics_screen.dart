import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/task_provider.dart';
import '../providers/premium_provider.dart';
import '../theme.dart';
import '../models/task.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'week';
  String _selectedChart = 'hours';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analytics', style: AppTextStyles.heading),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          final tasks = taskProvider.getTasksImmediately();
          final completedTasks = tasks.where((task) => task.isCompleted).toList();
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium Check
                Consumer<PremiumProvider>(
                  builder: (context, premiumProvider, child) {
                    if (!premiumProvider.isPremium) {
                      return _buildPremiumUpgradeCard();
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Summary Cards
                _buildSummaryCards(completedTasks),
                const SizedBox(height: 24),

                // Chart Controls
                _buildChartControls(),
                const SizedBox(height: 16),

                // Charts
                _buildCharts(completedTasks),
                const SizedBox(height: 24),

                // Insights
                _buildInsights(completedTasks),
                const SizedBox(height: 24),

                // Subject Breakdown
                _buildSubjectBreakdown(completedTasks),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumUpgradeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.amber[600]!, Colors.amber[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.analytics,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Unlock Advanced Analytics',
              style: AppTextStyles.heading.copyWith(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get detailed insights into your study patterns and progress',
              style: AppTextStyles.body.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/premium');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.amber[600],
              ),
              child: const Text('Upgrade to Premium'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(List<Task> completedTasks) {
    final totalHours = completedTasks.fold<int>(
      0, (sum, task) => sum + task.duration
    );
    final totalTasks = completedTasks.length;
    final averageHoursPerDay = totalHours / 7; // Assuming weekly view
    final completionRate = totalTasks > 0 ? (completedTasks.length / totalTasks) * 100 : 0;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Hours',
            '${totalHours}h',
            Icons.timer,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Tasks Completed',
            totalTasks.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Avg Hours/Day',
            '${averageHoursPerDay.toStringAsFixed(1)}h',
            Icons.trending_up,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.heading.copyWith(
                fontSize: 20,
                color: color,
              ),
            ),
            Text(
              title,
              style: AppTextStyles.body.copyWith(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartControls() {
    return Row(
      children: [
        Expanded(
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'week', label: Text('Week')),
              ButtonSegment(value: 'month', label: Text('Month')),
              ButtonSegment(value: 'year', label: Text('Year')),
            ],
            selected: {_selectedPeriod},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _selectedPeriod = newSelection.first;
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'hours', label: Text('Hours')),
              ButtonSegment(value: 'tasks', label: Text('Tasks')),
              ButtonSegment(value: 'subjects', label: Text('Subjects')),
            ],
            selected: {_selectedChart},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _selectedChart = newSelection.first;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCharts(List<Task> completedTasks) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getChartTitle(),
              style: AppTextStyles.subheading.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: _buildChart(completedTasks),
            ),
          ],
        ),
      ),
    );
  }

  String _getChartTitle() {
    switch (_selectedChart) {
      case 'hours':
        return 'Study Hours';
      case 'tasks':
        return 'Tasks Completed';
      case 'subjects':
        return 'Subject Distribution';
      default:
        return 'Analytics';
    }
  }

  Widget _buildChart(List<Task> completedTasks) {
    switch (_selectedChart) {
      case 'hours':
        return _buildHoursChart(completedTasks);
      case 'tasks':
        return _buildTasksChart(completedTasks);
      case 'subjects':
        return _buildSubjectsChart(completedTasks);
      default:
        return const Center(child: Text('No data available'));
    }
  }

  Widget _buildHoursChart(List<Task> completedTasks) {
    final data = _getWeeklyData(completedTasks);
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}h');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (value.toInt() < days.length) {
                  return Text(days[value.toInt()]);
                }
                return const Text('');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value);
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksChart(List<Task> completedTasks) {
    final data = _getWeeklyData(completedTasks);
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.isEmpty ? 10 : data.reduce((a, b) => a > b ? a : b) + 2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (value.toInt() < days.length) {
                  return Text(days[value.toInt()]);
                }
                return const Text('');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: Colors.green,
                width: 20,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubjectsChart(List<Task> completedTasks) {
    final subjectData = _getSubjectData(completedTasks);
    
    if (subjectData.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return PieChart(
      PieChartData(
        sections: subjectData.map((data) {
          return PieChartSectionData(
            value: data['value'].toDouble(),
            title: '${data['subject']}\n${data['value']}h',
            color: data['color'] as Color,
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  List<double> _getWeeklyData(List<Task> completedTasks) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final data = List<double>.filled(7, 0);

    for (final task in completedTasks) {
      final taskDate = task.dateTime;
      final daysDiff = taskDate.difference(weekStart).inDays;
      if (daysDiff >= 0 && daysDiff < 7) {
        data[daysDiff] += task.duration.toDouble();
      }
    }

    return data;
  }

  List<Map<String, dynamic>> _getSubjectData(List<Task> completedTasks) {
    final subjectMap = <String, int>{};
    
    for (final task in completedTasks) {
      subjectMap[task.subject] = (subjectMap[task.subject] ?? 0) + task.duration;
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    return subjectMap.entries.map((entry) {
      final index = subjectMap.keys.toList().indexOf(entry.key);
      return {
        'subject': entry.key,
        'value': entry.value,
        'color': colors[index % colors.length],
      };
    }).toList();
  }

  Widget _buildInsights(List<Task> completedTasks) {
    if (completedTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    final insights = _generateInsights(completedTasks);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Insights',
              style: AppTextStyles.subheading.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    insight['icon'] as IconData,
                    color: insight['color'] as Color,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      insight['text'] as String,
                      style: AppTextStyles.body,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _generateInsights(List<Task> completedTasks) {
    final insights = <Map<String, dynamic>>[];
    
    if (completedTasks.isEmpty) return insights;

    // Most productive day
    final dayData = _getWeeklyData(completedTasks);
    final mostProductiveDay = dayData.indexOf(dayData.reduce((a, b) => a > b ? a : b));
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    insights.add({
      'text': 'Your most productive day is ${days[mostProductiveDay]}',
      'icon': Icons.trending_up,
      'color': Colors.green,
    });

    // Most studied subject
    final subjectData = _getSubjectData(completedTasks);
    if (subjectData.isNotEmpty) {
      final topSubject = subjectData.first;
      insights.add({
        'text': 'You study ${topSubject['subject']} the most (${topSubject['value']} hours)',
        'icon': Icons.school,
        'color': Colors.blue,
      });
    }

    // Average study time
    final totalHours = completedTasks.fold<int>(0, (sum, task) => sum + task.duration);
    final avgHours = totalHours / completedTasks.length;
    insights.add({
      'text': 'Average study session: ${avgHours.toStringAsFixed(1)} hours',
      'icon': Icons.timer,
      'color': Colors.orange,
    });

    return insights;
  }

  Widget _buildSubjectBreakdown(List<Task> completedTasks) {
    final subjectData = _getSubjectData(completedTasks);
    
    if (subjectData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subject Breakdown',
              style: AppTextStyles.subheading.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            ...subjectData.map((data) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: data['color'] as Color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data['subject'] as String,
                      style: AppTextStyles.body,
                    ),
                  ),
                  Text(
                    '${data['value']}h',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
} 