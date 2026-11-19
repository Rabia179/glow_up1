import '../database/database_helper.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartRepository {
  final DatabaseHelper _dbHelper;

  CartRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  /// Fetches all items in the shopping cart joined with product details
  Future<List<CartItemModel>> getCartItems() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT c.id, c.productId, c.quantity, p.title, p.subtitle, p.price, p.badgeText, p.imageUrl, p.category, p.description
      FROM cart_items c
      INNER JOIN products p ON c.productId = p.id
    ''');

    return maps.map((map) {
      final product = ProductModel(
        id: map['productId'] as String,
        title: map['title'] as String,
        subtitle: map['subtitle'] as String,
        price: map['price'] as int,
        badgeText: map['badgeText'] as String?,
        imageUrl: map['imageUrl'] as String,
        category: map['category'] as String,
        description: map['description'] as String?,
      );
      return CartItemModel.fromMap(map, product: product);
    }).toList();
  }

  /// Adds a product to cart or increments quantity if already present
  Future<void> addToCart(String productId, {int quantity = 1}) async {
    if (quantity <= 0) return;

    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> existing = await db.query(
      'cart_items',
      where: 'productId = ?',
      whereArgs: [productId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final int currentQty = existing.first['quantity'] as int;
      final int id = existing.first['id'] as int;
      await db.update(
        'cart_items',
        {'quantity': currentQty + quantity},
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await db.insert(
        'cart_items',
        {
          'productId': productId,
          'quantity': quantity,
        },
      );
    }
  }

  /// Updates quantity for a specific cart line item.
  /// If quantity <= 0, automatically removes item.
  Future<void> updateQuantity(int cartItemId, int newQuantity) async {
    final db = await _dbHelper.database;
    if (newQuantity <= 0) {
      await removeFromCart(cartItemId);
    } else {
      await db.update(
        'cart_items',
        {'quantity': newQuantity},
        where: 'id = ?',
        whereArgs: [cartItemId],
      );
    }
  }

  /// Removes an item from cart by cart_items primary key
  Future<void> removeFromCart(int cartItemId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'cart_items',
      where: 'id = ?',
      whereArgs: [cartItemId],
    );
  }

  /// Clears all cart items
  Future<void> clearCart() async {
    final db = await _dbHelper.database;
    await db.delete('cart_items');
  }

  /// Calculates total subtotal amount in PKR
  Future<int> getSubtotal() async {
    final items = await getCartItems();
    int subtotal = 0;
    for (final item in items) {
      subtotal += item.itemSubtotal;
    }
    return subtotal;
  }

  /// Returns total quantity of units in cart for valid products
  Future<int> getTotalItemCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT SUM(c.quantity) as total
      FROM cart_items c
      INNER JOIN products p ON c.productId = p.id
    ''');
    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as int;
    }
    return 0;
  }
}
