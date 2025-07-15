class Recipe {
  final String id;
  final String title;
  final String description;
  final List<String> ingredients;
  final bool isSpecial;
  final String authorId;
  final String videoLink;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.authorId,
    this.videoLink = '',
    this.ingredients = const [],
    this.isSpecial = false,
  });

  // Create Recipe from Firestore document
  factory Recipe.fromMap(Map<String, dynamic> map, String id) {
    return Recipe(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      authorId: map['authorId'] ?? '',
      videoLink: map['videoLink'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      isSpecial: map['isSpecial'] ?? false,
    );
  }

  // Convert Recipe to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'authorId': authorId,
      'videoLink': videoLink,
      'ingredients': ingredients,
      'isSpecial': isSpecial,
    };
  }
} 