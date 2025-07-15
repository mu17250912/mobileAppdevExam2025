class BMIEntry {
  final String? id; // Firestore document ID
  final double bmi;
  final String category;
  final DateTime date;
  final double? weight;
  final double? height;

  BMIEntry({this.id, required this.bmi, required this.category, required this.date, this.weight, this.height});

  Map<String, dynamic> toJson() => {
        'bmi': bmi,
        'category': category,
        'date': date.toIso8601String(),
        if (weight != null) 'weight': weight,
        if (height != null) 'height': height,
      };

  factory BMIEntry.fromJson(Map<String, dynamic> json, {String? id}) => BMIEntry(
        id: id,
        bmi: json['bmi'],
        category: json['category'],
        date: DateTime.parse(json['date']),
        weight: json['weight']?.toDouble(),
        height: json['height']?.toDouble(),
      );
} 