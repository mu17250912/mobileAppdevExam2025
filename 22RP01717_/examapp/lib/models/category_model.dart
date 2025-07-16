class CategoryModel {
  final String id;
  final String name;

  CategoryModel({required this.id, required this.name});

  factory CategoryModel.fromFirestore(Map<String, dynamic> data) {
    return CategoryModel(
      id: data['id'],
      name: data['name'],
    );
  }
} 