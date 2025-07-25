import 'package:flutter/material.dart';
import 'dart:io';
import '../../services/logger_service.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  List<String> logFiles = [];
  String? selectedLogFile;
  String logContent = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLogFiles();
  }

  Future<void> _loadLogFiles() async {
    setState(() {
      isLoading = true;
    });

    try {
      final files = await logger.getLogFiles();
      setState(() {
        logFiles = files;
        if (files.isNotEmpty && selectedLogFile == null) {
          selectedLogFile = files.first;
          _loadLogContent(files.first);
        }
      });
    } catch (e) {
      logger.error('Failed to load log files', 'LogViewer', e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadLogContent(String filePath) async {
    setState(() {
      isLoading = true;
    });

    try {
      final content = await logger.getLogContent(filePath);
      setState(() {
        logContent = content;
        selectedLogFile = filePath;
      });
    } catch (e) {
      logger.error('Failed to load log content', 'LogViewer', e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs'),
        content: const Text('Are you sure you want to clear all logs? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await logger.clearLogs();
      _loadLogFiles();
    }
  }

  Future<void> _shareLogs() async {
    if (selectedLogFile == null) return;

    try {
      final file = File(selectedLogFile!);
      if (await file.exists()) {
        // You can implement sharing functionality here
        logger.info('Sharing log file: $selectedLogFile');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Log file ready for sharing: ${file.path}')),
        );
      }
    } catch (e) {
      logger.error('Failed to share logs', 'LogViewer', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogFiles,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Log file selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Log File: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedLogFile,
                    isExpanded: true,
                    hint: const Text('Select a log file'),
                    items: logFiles.map((file) {
                      final fileName = file.split('/').last;
                      return DropdownMenuItem(
                        value: file,
                        child: Text(fileName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _loadLogContent(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Log content
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: SelectableText(
                        logContent.isEmpty ? 'No log content available' : logContent,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
} 