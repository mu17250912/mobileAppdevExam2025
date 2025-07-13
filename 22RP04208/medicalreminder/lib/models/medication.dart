class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final String nextDose;
  final bool isActive;
  final DateTime? lastTaken;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.nextDose,
    required this.isActive,
    this.lastTaken,
  });

  factory Medication.fromMap(String id, Map<String, dynamic> data) {
    return Medication(
      id: id,
      name: data['name'] ?? '',
      dosage: data['dosage'] ?? '',
      frequency: data['frequency'] ?? '',
      nextDose: data['nextDose'] ?? '',
      isActive: data['isActive'] ?? true,
      lastTaken: data['lastTaken'] != null ? DateTime.tryParse(data['lastTaken']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'nextDose': nextDose,
      'isActive': isActive,
      'lastTaken': lastTaken?.toIso8601String(),
    };
  }
} 