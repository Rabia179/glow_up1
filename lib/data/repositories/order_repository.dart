import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

class OrderRepository {
  final DatabaseHelper _dbHelper;

  OrderRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  /// Creates a new order and its line items inside an atomic SQLite transaction.
  /// Automatically clears cart items only when the transaction succeeds.
  Future<OrderModel> createOrder({
    required String shippingAddress,
    required String paymentMethod,
    required List<CartItemModel> items,
    int shippingFee = 0,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('Cannot create an order with empty items');
    }

    final db = await _dbHelper.database;
    final String orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
    final String orderDate = DateTime.now().toIso8601String();

    int subtotal = 0;
    for (final item in items) {
      subtotal += item.itemSubtotal;
    }
    final int grandTotal = subtotal + shippingFee;

    final List<OrderItemModel> orderItems = [];
    for (final item in items) {
      final String name = item.product?.title ?? 'Formulation (${item.productId})';
      final int unitPrice = item.product?.price ?? 0;
      orderItems.add(
        OrderItemModel(
          orderId: orderId,
          productId: item.productId,
          productName: name,
          price: unitPrice,
          quantity: item.quantity,
        ),
      );
    }

    final OrderModel order = OrderModel(
      id: orderId,
      orderDate: orderDate,
      totalAmount: grandTotal,
      status: 'Processing',
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
      items: orderItems,
    );

    // Execute atomic transaction for order, order items, and clearing cart
    await db.transaction((txn) async {
      // 1. Insert order header
      await txn.insert(
        'orders',
        order.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Insert order line items
      for (final orderItem in orderItems) {
        await txn.insert('order_items', orderItem.toMap());
      }

      // 3. Clear cart items safely inside transaction
      await txn.delete('cart_items');
    });

    return order;
  }

  /// Fetches all completed orders from SQLite
  Future<List<OrderModel>> getAllOrders() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> orderMaps = await db.query(
      'orders',
      orderBy: 'orderDate DESC',
    );

    final List<OrderModel> orders = [];
    for (final map in orderMaps) {
      final String orderId = map['id'] as String;
      final List<Map<String, dynamic>> itemMaps = await db.query(
        'order_items',
        where: 'orderId = ?',
        whereArgs: [orderId],
      );
      final items = itemMaps.map((itemMap) => OrderItemModel.fromMap(itemMap)).toList();
      orders.add(OrderModel.fromMap(map, items: items));
    }

    return orders;
  }

  /// Fetches a specific order by order ID from SQLite
  Future<OrderModel?> getOrderById(String orderId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> orderMaps = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
      limit: 1,
    );

    if (orderMaps.isEmpty) return null;

    final List<Map<String, dynamic>> itemMaps = await db.query(
      'order_items',
      where: 'orderId = ?',
      whereArgs: [orderId],
    );
    final items = itemMaps.map((itemMap) => OrderItemModel.fromMap(itemMap)).toList();

    return OrderModel.fromMap(orderMaps.first, items: items);
  }
}
