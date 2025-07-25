import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/performance_service.dart';
import '../../services/cache_service.dart';
import '../../services/network_service.dart';
import '../../services/logger_service.dart';

class PerformanceDashboardScreen extends StatefulWidget {
  const PerformanceDashboardScreen({super.key});

  @override
  State<PerformanceDashboardScreen> createState() => _PerformanceDashboardScreenState();
}

class _PerformanceDashboardScreenState extends State<PerformanceDashboardScreen> {
  Map<String, dynamic> _performanceStats = {};
  Map<String, dynamic> _cacheStats = {};
  Map<String, dynamic> _networkStats = {};
  List<Map<String, dynamic>> _recentMetrics = [];
  List<String> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
  }

  Future<void> _loadPerformanceData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final performanceStats = performanceService.getPerformanceStats();
      final cacheStats = await cacheService.getStats();
      final networkStats = await networkService.getNetworkStats();
      final recentMetrics = performanceService.getRecentMetrics(limit: 20);
      final recommendations = performanceService.getPerformanceRecommendations();

      setState(() {
        _performanceStats = performanceStats;
        _cacheStats = cacheStats;
        _networkStats = networkStats;
        _recentMetrics = recentMetrics;
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      logger.error('Failed to load performance data', 'PerformanceDashboard', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPerformanceData,
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAllData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPerformanceData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPerformanceOverview(),
                    const SizedBox(height: 24),
                    _buildCacheStats(),
                    const SizedBox(height: 24),
                    _buildNetworkStats(),
                    const SizedBox(height: 24),
                    _buildRecommendations(),
                    const SizedBox(height: 24),
                    _buildRecentMetrics(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPerformanceOverview() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Performance Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Operations',
                    _performanceStats['totalOperations']?.toString() ?? '0',
                    Icons.analytics,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Avg Duration',
                    '${_performanceStats['averageDuration']?.toString() ?? '0'}ms',
                    Icons.timer,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Slow Operations',
                    _performanceStats['slowOperations']?.toString() ?? '0',
                    Icons.warning,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Error Rate',
                    '${_performanceStats['errorRate']?.toStringAsFixed(1) ?? '0'}%',
                    Icons.error,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheStats() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Cache Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Size',
                    '${(_cacheStats['totalSize'] ?? 0) ~/ 1024}KB',
                    Icons.storage,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Valid Entries',
                    _cacheStats['validEntries']?.toString() ?? '0',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Expired Entries',
                    _cacheStats['expiredEntries']?.toString() ?? '0',
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Entries',
                    _cacheStats['totalEntries']?.toString() ?? '0',
                    Icons.list,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkStats() {
    final isOnline = _networkStats['isOnline'] ?? false;
    final queueLength = _networkStats['offlineQueue']?['queueLength'] ?? 0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOnline ? Icons.wifi : Icons.wifi_off,
                  color: isOnline ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Network Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Connection',
                    isOnline ? 'Online' : 'Offline',
                    isOnline ? Icons.wifi : Icons.wifi_off,
                    isOnline ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Pending Requests',
                    queueLength.toString(),
                    Icons.queue,
                    queueLength > 0 ? Colors.orange : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'Performance Recommendations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recommendations.isEmpty)
              const Text(
                'No performance issues detected. App is running optimally.',
                style: TextStyle(color: Colors.green),
              )
            else
              ..._recommendations.map((recommendation) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(recommendation)),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMetrics() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text(
                  'Recent Operations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentMetrics.isEmpty)
              const Text('No recent operations recorded.')
            else
              ..._recentMetrics.reversed.map((metric) => _buildMetricTile(metric)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(Map<String, dynamic> metric) {
    final operation = metric['operation'] as String;
    final duration = metric['duration'] as int;
    final timestamp = DateTime.parse(metric['timestamp'] as String);
    final hasError = metric['additionalData']?['error'] != null;

    Color durationColor = Colors.green;
    if (duration > 3000) {
      durationColor = Colors.red;
    } else if (duration > 1000) {
      durationColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasError ? Colors.red[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasError ? Colors.red[200]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasError ? Icons.error : Icons.check_circle,
            color: hasError ? Colors.red : Colors.green,
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  operation,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  DateFormat('HH:mm:ss').format(timestamp),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (hasError)
                  Text(
                    'Error: ${metric['additionalData']['error']}',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
              ],
            ),
          ),
          Text(
            '${duration}ms',
            style: TextStyle(
              color: durationColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('This will clear all performance metrics, cache, and logs. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        performanceService.clearMetrics();
        await cacheService.clear();
        networkService.clearOfflineQueue();
        logger.clearLogs();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared successfully')),
        );
        
        _loadPerformanceData();
      } catch (e) {
        logger.error('Failed to clear all data', 'PerformanceDashboard', e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing data: $e')),
        );
      }
    }
  }
} 