import 'product.dart';

/// Model for cart line items stored in SQLite.
class CartItemModel {
  final int? id;
  final String productId;
  final int quantity;
  final ProductModel? product; // Joined product details for UI

  const CartItemModel({
    this.id,
    required this.productId,
    required this.quantity,
    this.product,
  });

  int get itemSubtotal {
    if (product != null) {
      return product!.price * quantity;
    }
    return 0;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'productId': productId,
      'quantity': quantity,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map, {ProductModel? product}) {
    return CartItemModel(
      id: map['id'] as int?,
      productId: map['productId'] as String,
      quantity: map['quantity'] as int,
      product: product,
    );
  }

  CartItemModel copyWith({
    int? id,
    String? productId,
    int? quantity,
    ProductModel? product,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      product: product ?? this.product,
    );
  }
}
