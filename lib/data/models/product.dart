/// Product model representing luxury beauty and skincare items.
/// Prices are stored strictly as integer Pakistani Rupees (PKR).
class ProductModel {
  final String id;
  final String title;
  final String subtitle;
  final int price; // In PKR integer (e.g. 4850 for PKR 4,850)
  final String? badgeText;
  final String imageUrl;
  final String category;
  final String? description;
  final bool isFeatured;
  final bool isNewArrival;

  const ProductModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    this.badgeText,
    required this.imageUrl,
    required this.category,
    this.description,
    this.isFeatured = false,
    this.isNewArrival = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'price': price,
      'badgeText': badgeText,
      'imageUrl': imageUrl,
      'category': category,
      'description': description,
      'isFeatured': isFeatured ? 1 : 0,
      'isNewArrival': isNewArrival ? 1 : 0,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String,
      price: map['price'] as int,
      badgeText: map['badgeText'] as String?,
      imageUrl: map['imageUrl'] as String,
      category: map['category'] as String,
      description: map['description'] as String?,
      isFeatured: (map['isFeatured'] as int? ?? 0) == 1,
      isNewArrival: (map['isNewArrival'] as int? ?? 0) == 1,
    );
  }
}
