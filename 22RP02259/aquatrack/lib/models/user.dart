class User {
  int householdSize;
  double? averageWaterBill;
  double waterUsageGoalPercent; // e.g., 20 for 20%
  bool usesSmartMeter;

  User({
    required this.householdSize,
    this.averageWaterBill,
    required this.waterUsageGoalPercent,
    required this.usesSmartMeter,
  });
} 