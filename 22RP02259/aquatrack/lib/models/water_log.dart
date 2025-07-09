class WaterLog {
  final DateTime timestamp;
  final String activityType;
  final double amount;
  final String unit;
  final String? note;

  WaterLog({
    required this.timestamp,
    required this.activityType,
    required this.amount,
    required this.unit,
    this.note,
  });
} 