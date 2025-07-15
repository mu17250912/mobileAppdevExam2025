import 'package:flutter/material.dart';
import 'dart:async';

class WorkoutStepScreen extends StatefulWidget {
  const WorkoutStepScreen({super.key});

  @override
  State<WorkoutStepScreen> createState() => _WorkoutStepScreenState();
}

class _WorkoutStepScreenState extends State<WorkoutStepScreen> {
  int seconds = 20;
  bool isPaused = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (!isPaused && seconds > 0) {
        setState(() => seconds--);
      }
      if (seconds == 0) {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercise = 'Jumping Jacks';
    final nextExercise = 'Push-Ups';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3365),
        elevation: 0,
        leading: BackButton(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 24),
            Text(exercise, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: const Color(0xFF1A3365))),
            SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: seconds / 20,
                    strokeWidth: 10,
                    backgroundColor: Colors.blue[100],
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22A6F2)),
                  ),
                ),
                Text('$seconds', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF22A6F2))),
              ],
            ),
            SizedBox(height: 18),
            Text('Next: $nextExercise', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
            SizedBox(height: 24),
            Icon(Icons.directions_run, size: 80, color: Color(0xFF22A6F2)),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => isPaused = !isPaused),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[100],
                    foregroundColor: Color(0xFF1A3365),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isPaused ? 'Resume' : 'Pause'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Color(0xFF1A3365),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Skip'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[300],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Stop'),
                ),
              ],
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
} 