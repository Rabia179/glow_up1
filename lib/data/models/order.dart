/// Order item model representing an individual line item in a completed order.
class OrderItemModel {
  final int? id;
  final String orderId;
  final String productId;
  final String productName;
  final int price; // In PKR integer
  final int quantity;

  const OrderItemModel({
    this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'orderId': orderId,
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: map['id'] as int?,
      orderId: map['orderId'] as String,
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      price: map['price'] as int,
      quantity: map['quantity'] as int,
    );
  }
}

/// Order model representing a completed order in SQLite.
class OrderModel {
  final String id;
  final String orderDate;
  final int totalAmount; // In PKR integer
  final String status;
  final String shippingAddress;
  final String paymentMethod;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.orderDate,
    required this.totalAmount,
    required this.status,
    required this.shippingAddress,
    required this.paymentMethod,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderDate': orderDate,
      'totalAmount': totalAmount,
      'status': status,
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, {List<OrderItemModel> items = const []}) {
    return OrderModel(
      id: map['id'] as String,
      orderDate: map['orderDate'] as String,
      totalAmount: map['totalAmount'] as int,
      status: map['status'] as String,
      shippingAddress: map['shippingAddress'] as String,
      paymentMethod: map['paymentMethod'] as String,
      items: items,
    );
  }
}
