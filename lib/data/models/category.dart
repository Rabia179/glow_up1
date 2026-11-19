/// Category model representing beauty product categories.
class CategoryModel {
  final String id;
  final String name;
  final String iconName;
  final String? description;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'description': description,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      iconName: map['iconName'] as String,
      description: map['description'] as String?,
    );
  }
}
