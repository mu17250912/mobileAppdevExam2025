class Workout {
  final String id;
  final String title;
  final String description;
  final List<String> steps;
  final bool isPremium;
  final String? area;

  Workout({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
    this.isPremium = false,
    this.area,
  });

  factory Workout.fromMap(Map<String, dynamic> data, String id) {
    bool parseIsPremium(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) return value.toLowerCase() == 'true';
      return false;
    }
    return Workout(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      steps: List<String>.from(data['steps'] ?? []),
      isPremium: parseIsPremium(data['isPremium']),
      area: data['area'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'steps': steps,
      'isPremium': isPremium,
      if (area != null) 'area': area,
    };
  }
} 