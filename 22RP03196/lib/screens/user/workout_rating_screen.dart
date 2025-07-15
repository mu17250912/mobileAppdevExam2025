import 'package:flutter/material.dart';

class WorkoutRatingScreen extends StatefulWidget {
  const WorkoutRatingScreen({super.key});

  @override
  State<WorkoutRatingScreen> createState() => _WorkoutRatingScreenState();
}

class _WorkoutRatingScreenState extends State<WorkoutRatingScreen> {
  int rating = 0;
  final _controller = TextEditingController();

  void _submit() {
    // You can handle the submission logic here
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Thank you!'),
        content: Text('Your feedback has been submitted.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK'))],
      ),
    );
    setState(() {
      rating = 0;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Color(0xFF1A3365)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 24),
            Text('Rate Your Workout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFF1A3365))),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => IconButton(
                icon: Icon(
                  i < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 36,
                ),
                onPressed: () => setState(() => rating = i + 1),
              )),
            ),
            SizedBox(height: 24),
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Tell us what you liked or didn't like",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                fillColor: Colors.grey[100],
                filled: true,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1A3365),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                textStyle: TextStyle(fontSize: 18),
                elevation: 2,
              ),
              child: Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
} 