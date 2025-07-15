import 'package:flutter/material.dart';
import 'dart:math';

class QuoteWidget extends StatelessWidget {
  const QuoteWidget({super.key});

  static const List<String> quotes = [
    'Success is the sum of small efforts, repeated day in and day out.',
    'The secret of getting ahead is getting started.',
    'Don’t watch the clock; do what it does. Keep going.',
    'It always seems impossible until it’s done.',
    'You don’t have to be great to start, but you have to start to be great.',
    'The future depends on what you do today.',
    'Dream big. Start small. Act now.',
    'Push yourself, because no one else is going to do it for you.',
    'Great things never come from comfort zones.',
    'Believe you can and you’re halfway there.',
  ];

  @override
  Widget build(BuildContext context) {
    final quote = quotes[Random().nextInt(quotes.length)];
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.format_quote, size: 32, color: Colors.deepPurple),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                quote,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
