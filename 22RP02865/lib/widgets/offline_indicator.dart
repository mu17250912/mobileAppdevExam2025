import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/task_provider.dart';
import '../services/task_storage.dart';

class OfflineIndicator extends StatefulWidget {
  const OfflineIndicator({Key? key}) : super(key: key);

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  bool _isOnline = true;
  bool _isSyncing = false;
  String _lastSyncTime = '';

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();
    _loadLastSyncTime();
  }

  Future<void> _checkConnectionStatus() async {
    try {
      final canConnect = await TaskStorage().canConnectToFirebase();
      if (mounted) {
        setState(() {
          _isOnline = canConnect;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOnline = false;
        });
      }
    }
  }

  Future<void> _loadLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString('last_sync_timestamp');
      if (lastSync != null) {
        final syncTime = DateTime.parse(lastSync);
        final now = DateTime.now();
        final difference = now.difference(syncTime);
        
        if (mounted) {
          setState(() {
            if (difference.inMinutes < 1) {
              _lastSyncTime = 'Just now';
            } else if (difference.inHours < 1) {
              _lastSyncTime = '${difference.inMinutes}m ago';
            } else if (difference.inDays < 1) {
              _lastSyncTime = '${difference.inHours}h ago';
            } else {
              _lastSyncTime = '${difference.inDays}d ago';
            }
          });
        }
      }
    } catch (e) {
      print('Error loading last sync time: $e');
    }
  }

  Future<void> _syncNow() async {
    if (_isSyncing) return;
    
    setState(() {
      _isSyncing = true;
    });

    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider.refresh();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data synced successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        await _checkConnectionStatus();
        await _loadLastSyncTime();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show when offline or when there are sync issues
    if (_isOnline && !TaskStorage.hasCachedData) {
      return const SizedBox.shrink();
    }

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final hasSyncError = taskProvider.hasSyncError;
        final hasCachedData = taskProvider.hasCachedData;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getStatusColor().withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStatusIcon(),
                size: 16,
                color: _getStatusColor(),
              ),
              const SizedBox(width: 8),
              Text(
                _getStatusText(),
                style: TextStyle(
                  fontSize: 12,
                  color: _getStatusColor(),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (hasCachedData && !_isOnline) ...[
                const SizedBox(width: 8),
                Text(
                  'Last sync: $_lastSyncTime',
                  style: TextStyle(
                    fontSize: 10,
                    color: _getStatusColor().withOpacity(0.7),
                  ),
                ),
              ],
              if (hasSyncError || !_isOnline) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isSyncing ? null : _syncNow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isSyncing
                        ? SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
                            ),
                          )
                        : Text(
                            'Sync',
                            style: TextStyle(
                              fontSize: 10,
                              color: _getStatusColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor() {
    if (!_isOnline) return Colors.orange;
    if (TaskStorage.hasCachedData) return Colors.blue;
    return Colors.red;
  }

  IconData _getStatusIcon() {
    if (!_isOnline) return Icons.wifi_off;
    if (TaskStorage.hasCachedData) return Icons.cloud_done;
    return Icons.error;
  }

  String _getStatusText() {
    if (!_isOnline) return 'Offline';
    if (TaskStorage.hasCachedData) return 'Cached';
    return 'Error';
  }
} 