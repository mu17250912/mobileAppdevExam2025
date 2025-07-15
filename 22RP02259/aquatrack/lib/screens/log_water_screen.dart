import 'package:flutter/material.dart';
import '../models/water_log.dart';
import '../services/water_log_service.dart';

class LogWaterScreen extends StatefulWidget {
  final WaterLogService logService;
  final String email;
  const LogWaterScreen({Key? key, required this.logService, required this.email}) : super(key: key);

  @override
  State<LogWaterScreen> createState() => _LogWaterScreenState();
}

class _LogWaterScreenState extends State<LogWaterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedActivity = 'Shower';
  double? _amount;
  String _selectedUnit = 'liters';
  final _noteController = TextEditingController();

  static const activities = [
    {'name': 'Shower', 'units': ['minutes', 'liters']},
    {'name': 'Washing Dishes', 'units': ['liters', 'minutes']},
    {'name': 'Laundry', 'units': ['loads', 'liters']},
    {'name': 'Toilet Flush', 'units': ['flushes', 'liters']},
    {'name': 'Drinking Water', 'units': ['liters', 'glasses']},
  ];

  List<String> get _unitsForSelectedActivity {
    return activities.firstWhere((a) => a['name'] == _selectedActivity)['units'] as List<String>;
  }

  void _addLog() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      widget.logService.addLog(WaterLog(
        timestamp: DateTime.now(),
        activityType: _selectedActivity,
        amount: _amount!,
        unit: _selectedUnit,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
      ));
      setState(() {
        _amount = null;
        _noteController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = widget.logService.todaysLogs;
    return Scaffold(
      appBar: AppBar(title: const Text('Log Water Usage')),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2196F3),
              Color(0xFF64B5F6),
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Log a Water Activity',
                            style: TextStyle(
                              color: Color(0xFF1976D2),
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 24),
                          DropdownButtonFormField<String>(
                            value: _selectedActivity,
                            decoration: InputDecoration(
                              labelText: 'Activity',
                              prefixIcon: Icon(Icons.water_drop, color: Colors.blue),
                              filled: true,
                              fillColor: Colors.blue.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: activities.map((a) => DropdownMenuItem(
                              value: a['name'] as String,
                              child: Text(a['name'] as String),
                            )).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedActivity = val!;
                                _selectedUnit = _unitsForSelectedActivity.first;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              prefixIcon: Icon(Icons.tune, color: Colors.blue),
                              filled: true,
                              fillColor: Colors.blue.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Enter amount';
                              if (double.tryParse(value) == null || double.parse(value) <= 0) return 'Enter a valid number';
                              return null;
                            },
                            onSaved: (value) => _amount = double.tryParse(value ?? ''),
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: _selectedUnit,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              prefixIcon: Icon(Icons.straighten, color: Colors.blue),
                              filled: true,
                              fillColor: Colors.blue.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: _unitsForSelectedActivity.map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(u),
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedUnit = val!),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _noteController,
                            decoration: InputDecoration(
                              labelText: 'Note (optional)',
                              prefixIcon: Icon(Icons.note, color: Colors.blue),
                              filled: true,
                              fillColor: Colors.blue.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                elevation: 6,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _addLog,
                              child: const Text(
                                'Add',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Today's logs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Logs",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...logs.isEmpty
                          ? [
                              const Text(
                                'No logs yet today.',
                                style: TextStyle(color: Colors.white70),
                              )
                            ]
                          : logs.map((log) => Card(
                                color: Colors.white.withOpacity(0.9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  leading: Icon(Icons.water_drop, color: Colors.blue.shade700),
                                  title: Text('${log.activityType}: ${log.amount} ${log.unit}'),
                                  subtitle: log.note != null ? Text(log.note!) : null,
                                  trailing: Text(
                                    '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                                  ),
                                ),
                              )),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 