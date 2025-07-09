import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/water_log.dart';
import 'dart:collection';

class UsageChart extends StatelessWidget {
  final List<WaterLog> logs;
  const UsageChart({Key? key, required this.logs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Group logs by day (last 7 days)
    final now = DateTime.now();
    final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));
    final usagePerDay = Map<DateTime, double>.fromIterable(
      days,
      key: (d) => d,
      value: (d) => 0.0,
    );
    for (final log in logs) {
      final day = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
      if (usagePerDay.containsKey(day)) {
        usagePerDay[day] = usagePerDay[day]! + log.amount;
      }
    }
    final barGroups = usagePerDay.entries.map((entry) {
      return BarChartGroupData(
        x: days.indexOf(entry.key),
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: Colors.blue.shade700,
            width: 18,
            borderRadius: BorderRadius.circular(6),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: usagePerDay.values.reduce((a, b) => a > b ? a : b) * 1.2 + 1,
              color: Colors.blue.shade100,
            ),
          ),
        ],
      );
    }).toList();
    final maxY = ((usagePerDay.values.reduce((a, b) => a > b ? a : b) * 1.2 + 1).clamp(5, 1000)).toDouble();
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last 7 Days Usage',
              style: TextStyle(
                color: Color(0xFF1976D2),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 32),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx > 6) return const SizedBox.shrink();
                          final date = days[idx];
                          final weekday = date.weekday;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              dayLabels[weekday - 1],
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 