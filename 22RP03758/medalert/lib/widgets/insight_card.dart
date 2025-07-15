import 'package:flutter/material.dart';
import '../services/sustainability_service.dart';

class InsightCard extends StatelessWidget {
  final RetentionInsight insight;
  final VoidCallback onAction;

  const InsightCard({
    super.key,
    required this.insight,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(context),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getIconBackgroundColor(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIcon(),
                    color: _getIconColor(context),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getPriorityText(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Message
            Text(
              insight.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _getTextColor(context),
              ),
            ),
            const SizedBox(height: 16),
            
            // Action button
            if (_shouldShowActionButton())
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getActionButtonColor(context),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _getActionButtonText(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    switch (insight.priority) {
      case InsightPriority.high:
        return Colors.red.shade50;
      case InsightPriority.medium:
        return Colors.orange.shade50;
      case InsightPriority.low:
        return Colors.blue.shade50;
    }
  }

  Color _getBorderColor(BuildContext context) {
    switch (insight.priority) {
      case InsightPriority.high:
        return Colors.red.shade200;
      case InsightPriority.medium:
        return Colors.orange.shade200;
      case InsightPriority.low:
        return Colors.blue.shade200;
    }
  }

  Color _getIconBackgroundColor(BuildContext context) {
    switch (insight.type) {
      case RetentionInsightType.streak:
        return Colors.orange.shade100;
      case RetentionInsightType.medication:
        return Colors.blue.shade100;
      case RetentionInsightType.engagement:
        return Colors.green.shade100;
      case RetentionInsightType.notification:
        return Colors.purple.shade100;
    }
  }

  Color _getIconColor(BuildContext context) {
    switch (insight.type) {
      case RetentionInsightType.streak:
        return Colors.orange.shade700;
      case RetentionInsightType.medication:
        return Colors.blue.shade700;
      case RetentionInsightType.engagement:
        return Colors.green.shade700;
      case RetentionInsightType.notification:
        return Colors.purple.shade700;
    }
  }

  Color _getTextColor(BuildContext context) {
    switch (insight.priority) {
      case InsightPriority.high:
        return Colors.red.shade800;
      case InsightPriority.medium:
        return Colors.orange.shade800;
      case InsightPriority.low:
        return Colors.blue.shade800;
    }
  }

  Color _getPriorityColor(BuildContext context) {
    switch (insight.priority) {
      case InsightPriority.high:
        return Colors.red;
      case InsightPriority.medium:
        return Colors.orange;
      case InsightPriority.low:
        return Colors.blue;
    }
  }

  String _getPriorityText() {
    switch (insight.priority) {
      case InsightPriority.high:
        return 'HIGH PRIORITY';
      case InsightPriority.medium:
        return 'MEDIUM PRIORITY';
      case InsightPriority.low:
        return 'LOW PRIORITY';
    }
  }

  IconData _getIcon() {
    switch (insight.type) {
      case RetentionInsightType.streak:
        return Icons.local_fire_department;
      case RetentionInsightType.medication:
        return Icons.medication;
      case RetentionInsightType.engagement:
        return Icons.touch_app;
      case RetentionInsightType.notification:
        return Icons.notifications;
    }
  }

  bool _shouldShowActionButton() {
    return insight.actionType != InsightActionType.celebrate &&
           insight.actionType != InsightActionType.motivate;
  }

  Color _getActionButtonColor(BuildContext context) {
    switch (insight.actionType) {
      case InsightActionType.addMedication:
        return Colors.blue;
      case InsightActionType.caregiverSetup:
        return Colors.green;
      case InsightActionType.enableNotifications:
        return Colors.orange;
      case InsightActionType.reminder:
        return Colors.purple;
      case InsightActionType.celebrate:
      case InsightActionType.motivate:
        return Colors.grey;
    }
  }

  String _getActionButtonText() {
    switch (insight.actionType) {
      case InsightActionType.addMedication:
        return 'Add Medication';
      case InsightActionType.caregiverSetup:
        return 'Setup Caregiver';
      case InsightActionType.enableNotifications:
        return 'Enable Notifications';
      case InsightActionType.reminder:
        return 'View Reminders';
      case InsightActionType.celebrate:
        return 'Celebrate!';
      case InsightActionType.motivate:
        return 'Stay Motivated';
    }
  }
} 