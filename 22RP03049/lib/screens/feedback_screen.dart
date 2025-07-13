import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _controller = TextEditingController();
  bool _sending = false;
  String? _result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('We value your feedback!', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Type your feedback here...',
              ),
            ),
            const SizedBox(height: 16),
            if (_sending) const CircularProgressIndicator(),
            if (!_sending)
              ElevatedButton(
                onPressed: () async {
                  setState(() { _sending = true; _result = null; });
                  await Future.delayed(const Duration(seconds: 1)); // Simulate sending
                  setState(() {
                    _sending = false;
                    _result = 'Thank you for your feedback!';
                    _controller.clear();
                  });
                },
                child: const Text('Send'),
              ),
            if (_result != null) ...[
              const SizedBox(height: 12),
              Text(_result!, style: const TextStyle(color: Colors.green)),
            ]
          ],
        ),
      ),
    );
  }
} 