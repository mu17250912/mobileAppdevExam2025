import 'package:flutter/material.dart';

class TypingIndicator extends StatelessWidget {
  final bool isTyping;
  final String name;

  const TypingIndicator({
    super.key,
    required this.isTyping,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    if (!isTyping) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$name is typing...',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
