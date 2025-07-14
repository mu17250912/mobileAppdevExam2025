import 'package:flutter/material.dart';
import '../services/task_storage.dart';

class FirebaseStatusIndicator extends StatelessWidget {
  final bool showStatus;

  const FirebaseStatusIndicator({
    Key? key,
    this.showStatus = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!showStatus) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_done,
            size: 14,
            color: Colors.green[700],
          ),
          const SizedBox(width: 4),
          Text(
            'Firebase',
            style: TextStyle(
              fontSize: 10,
              color: Colors.green[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 