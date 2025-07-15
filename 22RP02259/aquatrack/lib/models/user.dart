class User {
  final String email;
  final int householdSize;
  final double? averageWaterBill;
  final double waterUsageGoalPercent; // e.g., 20 for 20%
  final bool usesSmartMeter;

  User({
    required this.email,
    required this.householdSize,
    this.averageWaterBill,
    required this.waterUsageGoalPercent,
    required this.usesSmartMeter,
  });
} 