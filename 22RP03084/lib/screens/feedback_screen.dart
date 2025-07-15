import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 0;
  final _feedbackController = TextEditingController();
  bool _submitting = false;

  void _submitFeedback() async {
    if (_rating == 0 || _feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a rating and feedback.')),
      );
      return;
    }
    setState(() => _submitting = true);
    await FirebaseFirestore.instance.collection('feedback').add({
      'rating': _rating,
      'feedback': _feedbackController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Log feedback event to Firebase Analytics
    await FirebaseAnalytics.instance.logEvent(
      name: 'submit_feedback',
      parameters: {
        'rating': _rating,
        'has_feedback': _feedbackController.text.trim().isNotEmpty,
      },
    );
    setState(() => _submitting = false);
    _feedbackController.clear();
    setState(() => _rating = 0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your feedback!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate & Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rate your experience:', style: TextStyle(fontSize: 18)),
            Row(
              children: List.generate(5, (i) => IconButton(
                icon: Icon(
                  Icons.star,
                  color: i < _rating ? Colors.amber : Colors.grey,
                  size: 32,
                ),
                onPressed: () => setState(() => _rating = i + 1),
              )),
            ),
            const SizedBox(height: 16),
            const Text('Your feedback:', style: TextStyle(fontSize: 18)),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your feedback here...',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitFeedback,
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
