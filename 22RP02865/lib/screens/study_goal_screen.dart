import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/study_goal.dart';
import '../theme.dart';
import '../services/hive_service.dart';

class StudyGoalScreen extends StatefulWidget {
  const StudyGoalScreen({Key? key}) : super(key: key);

  @override
  State<StudyGoalScreen> createState() => _StudyGoalScreenState();
}

class _StudyGoalScreenState extends State<StudyGoalScreen> {
  final _dailyController = TextEditingController();
  final _weeklyController = TextEditingController();
  StudyGoal? _goal;

  @override
  void initState() {
    super.initState();
    final box = HiveService().getStudyGoalsBoxSync();
    if (box != null && box.isNotEmpty) {
      _goal = box.getAt(0);
      _dailyController.text = _goal?.dailyMinutes.toString() ?? '';
      _weeklyController.text = _goal?.weeklyMinutes.toString() ?? '';
    }
  }

  void _saveGoal() async {
    final daily = int.tryParse(_dailyController.text) ?? 0;
    final weekly = int.tryParse(_weeklyController.text) ?? 0;
    final box = HiveService().getStudyGoalsBoxSync();
    if (box != null) {
      if (_goal != null) {
        _goal!.dailyMinutes = daily;
        _goal!.weeklyMinutes = weekly;
        await _goal!.save();
      } else {
        final newGoal = StudyGoal(dailyMinutes: daily, weeklyMinutes: weekly);
        await box.clear();
        await box.add(newGoal);
        _goal = newGoal;
      }
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Study goals saved!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Goals', style: AppTextStyles.heading),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set your daily and weekly study goals (in minutes):', style: AppTextStyles.body),
            const SizedBox(height: 24),
            TextField(
              controller: _dailyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Daily Goal (minutes)',
                border: OutlineInputBorder(),
                errorText: _dailyController.text.isNotEmpty && int.tryParse(_dailyController.text) == null ? 'Enter a valid number' : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _weeklyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Weekly Goal (minutes)',
                border: OutlineInputBorder(),
                errorText: _weeklyController.text.isNotEmpty && int.tryParse(_weeklyController.text) == null ? 'Enter a valid number' : null,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (_dailyController.text.isEmpty || int.tryParse(_dailyController.text) == null ||
                      _weeklyController.text.isEmpty || int.tryParse(_weeklyController.text) == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter valid numbers for both goals.')),
                    );
                    return;
                  }
                  _saveGoal();
                },
                child: const Text('Save Goals', style: AppTextStyles.button),
              ),
            ),
            const SizedBox(height: 32),
            if (_goal != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Daily Goal: ${_goal!.dailyMinutes} minutes', style: AppTextStyles.body),
                  const SizedBox(height: 8),
                  Text('Current Weekly Goal: ${_goal!.weeklyMinutes} minutes', style: AppTextStyles.body),
                ],
              )
            else
              Center(
                child: Text('No study goal set yet.', style: AppTextStyles.body.copyWith(color: AppColors.primary.withOpacity(0.7))),
              ),
          ],
        ),
      ),
    );
  }
} 