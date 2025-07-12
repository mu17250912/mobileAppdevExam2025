import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddHouseInfoForm extends StatefulWidget {
  final String email;
  final int? initialHouseholdSize;
  final String? initialLocation;
  final int? initialGoalPercent;
  final List<String>? initialGoalReasons;
  final String? initialGoalReasonOther;
  final double? initialWaterBill;
  final String? initialMeterOption;

  const AddHouseInfoForm({
    Key? key,
    required this.email,
    this.initialHouseholdSize,
    this.initialLocation,
    this.initialGoalPercent,
    this.initialGoalReasons,
    this.initialGoalReasonOther,
    this.initialWaterBill,
    this.initialMeterOption,
  }) : super(key: key);

  @override
  State<AddHouseInfoForm> createState() => _AddHouseInfoFormState();
}

class _AddHouseInfoFormState extends State<AddHouseInfoForm> {
  final _formKey = GlobalKey<FormState>();
  int? householdSize;
  String? location;
  int? goalPercent;
  String? goalReasonOther;
  List<String> goalReasons = [];
  double? waterBill;
  String meterOption = 'manual';
  int? customGoalPercent;
  bool _saving = false;

  final List<String> reasons = [
    'Reduce utility bills',
    'Environmental reasons',
    'Drought in my area',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    householdSize = widget.initialHouseholdSize;
    location = widget.initialLocation;
    goalPercent = widget.initialGoalPercent ?? 10;
    goalReasons = List<String>.from(widget.initialGoalReasons ?? []);
    goalReasonOther = widget.initialGoalReasonOther;
    waterBill = widget.initialWaterBill;
    meterOption = widget.initialMeterOption ?? 'manual';
    if (goalPercent != null && goalPercent != 10 && goalPercent != 20 && goalPercent != -1) {
      customGoalPercent = goalPercent;
      goalPercent = -1;
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState?.save();
    setState(() { _saving = true; });
    final selectedGoal = goalPercent == -1 ? customGoalPercent : goalPercent;
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.email).set({
        'email': widget.email,
        'householdSize': householdSize,
        'location': location,
        'waterUsageGoalPercent': selectedGoal,
        'goalReasons': goalReasons,
        'goalReasonOther': goalReasonOther,
        'averageWaterBill': waterBill,
        'usesSmartMeter': meterOption == 'smart',
      }, SetOptions(merge: true));
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('House info saved successfully!'),
            actions: [TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('OK'))],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to save: $e'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() { _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. Household Information', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: householdSize?.toString(),
              decoration: const InputDecoration(
                labelText: 'Number of people in the household',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter household size';
                final n = int.tryParse(value);
                if (n == null || n < 1) return 'Enter a valid number';
                return null;
              },
              onSaved: (value) => householdSize = int.tryParse(value ?? ''),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: location,
              decoration: const InputDecoration(
                labelText: 'Location/Region (optional)',
                border: OutlineInputBorder(),
              ),
              onSaved: (value) => location = value,
            ),
            const SizedBox(height: 20),
            const Text('2. Water Usage Goal', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Column(
              children: [
                RadioListTile<int>(
                  value: 10,
                  groupValue: goalPercent,
                  title: const Text('Reduce water usage by 10%'),
                  onChanged: (v) => setState(() { goalPercent = v; customGoalPercent = null; }),
                ),
                RadioListTile<int>(
                  value: 20,
                  groupValue: goalPercent,
                  title: const Text('Reduce water usage by 20%'),
                  onChanged: (v) => setState(() { goalPercent = v; customGoalPercent = null; }),
                ),
                RadioListTile<int>(
                  value: -1,
                  groupValue: goalPercent,
                  title: Row(
                    children: [
                      const Text('Custom percentage'),
                      const SizedBox(width: 8),
                      if (goalPercent == -1)
                        SizedBox(
                          width: 60,
                          child: TextFormField(
                            initialValue: customGoalPercent?.toString(),
                            decoration: const InputDecoration(suffixText: '%'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (goalPercent == -1) {
                                final n = int.tryParse(value ?? '');
                                if (n == null || n < 1 || n > 100) return '1-100';
                              }
                              return null;
                            },
                            onChanged: (value) => customGoalPercent = int.tryParse(value),
                          ),
                        ),
                    ],
                  ),
                  onChanged: (v) => setState(() { goalPercent = v; }),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text('Why are you saving water? (optional)'),
            ...reasons.map((reason) {
              if (reason == 'Other') {
                return Column(
                  children: [
                    CheckboxListTile(
                      value: goalReasons.contains(reason),
                      title: const Text('Other'),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            goalReasons.add(reason);
                          } else {
                            goalReasons.remove(reason);
                            goalReasonOther = null;
                          }
                        });
                      },
                    ),
                    if (goalReasons.contains('Other'))
                      Padding(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: TextFormField(
                          initialValue: goalReasonOther,
                          decoration: const InputDecoration(labelText: 'Please specify'),
                          onChanged: (v) => goalReasonOther = v,
                        ),
                      ),
                  ],
                );
              } else {
                return CheckboxListTile(
                  value: goalReasons.contains(reason),
                  title: Text(reason),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        goalReasons.add(reason);
                      } else {
                        goalReasons.remove(reason);
                      }
                    });
                  },
                );
              }
            }),
            const SizedBox(height: 20),
            const Text('3. Water Bill (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: waterBill?.toString(),
              decoration: const InputDecoration(
                labelText: 'Monthly water bill (in currency)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onSaved: (value) => waterBill = double.tryParse(value ?? ''),
            ),
            const SizedBox(height: 20),
            const Text('4. Meter Connection Option', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            RadioListTile<String>(
              value: 'smart',
              groupValue: meterOption,
              title: const Text('Connect to smart water meter'),
              onChanged: (v) => setState(() { meterOption = v!; }),
            ),
            if (meterOption == 'smart')
              Padding(
                padding: const EdgeInsets.only(left: 24.0, bottom: 8),
                child: ElevatedButton(
                  onPressed: () {
                    // Placeholder for smart meter connection
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Smart meter connection coming soon!')));
                  },
                  child: const Text('Connect'),
                ),
              ),
            RadioListTile<String>(
              value: 'manual',
              groupValue: meterOption,
              title: const Text('I will enter water meter readings manually'),
              onChanged: (v) => setState(() { meterOption = v!; }),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 