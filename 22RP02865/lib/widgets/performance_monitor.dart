import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import 'dart:async'; // Added for Timer

class PerformanceMonitor extends StatefulWidget {
  const PerformanceMonitor({Key? key}) : super(key: key);

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> with WidgetsBindingObserver {
  final AnalyticsService _analytics = AnalyticsService();
  bool _isVisible = false;
  String _performanceStatus = 'Good';
  double _memoryUsage = 0.0;
  int _frameCount = 0;
  DateTime? _lastFrameTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startMonitoring();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startMonitoring() {
    // Monitor frame rate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _frameCount++;
      final now = DateTime.now();
      if (_lastFrameTime != null) {
        final frameTime = now.difference(_lastFrameTime!).inMilliseconds;
        if (frameTime > 16) { // More than 60 FPS threshold
          _performanceStatus = 'Warning';
          _analytics.trackEvent('performance_warning', {
            'frame_time': frameTime,
            'frame_count': _frameCount,
          });
        }
      }
      _lastFrameTime = now;
    });

    // Monitor memory usage periodically
    Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkMemoryUsage();
    });
  }

  void _checkMemoryUsage() async {
    try {
      // Simplified memory usage check - in a real app, you'd use platform channels
      // For now, we'll simulate memory usage based on time
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      _memoryUsage = random.toDouble();
      
      if (_memoryUsage > 80) {
        _performanceStatus = 'Critical';
        _analytics.trackEvent('memory_warning', {
          'memory_usage': _memoryUsage,
        });
      } else if (_memoryUsage > 60) {
        _performanceStatus = 'Warning';
      } else {
        _performanceStatus = 'Good';
      }
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('PerformanceMonitor: Error checking memory: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode or when there are performance issues
    if (!_isVisible && _performanceStatus == 'Good') {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 50,
      right: 10,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isVisible = !_isVisible;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStatusIcon(),
                color: Colors.white,
                size: 16,
              ),
              if (_isVisible) ...[
                const SizedBox(height: 4),
                Text(
                  'Performance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _performanceStatus,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                  ),
                ),
                Text(
                  '${_memoryUsage.toInt()}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (_performanceStatus) {
      case 'Good':
        return Colors.green;
      case 'Warning':
        return Colors.orange;
      case 'Critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_performanceStatus) {
      case 'Good':
        return Icons.check_circle;
      case 'Warning':
        return Icons.warning;
      case 'Critical':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Track app lifecycle events
    _analytics.trackEvent('app_lifecycle', {
      'state': state.toString(),
    });
    
    // Optimize performance when app goes to background
    if (state == AppLifecycleState.paused) {
      _performanceStatus = 'Good';
      if (mounted) {
        setState(() {});
      }
    }
  }
} 