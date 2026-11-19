import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/product.dart';

class WishlistRepository {
  final DatabaseHelper _dbHelper;

  WishlistRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  /// Fetches all wishlisted products joined with product details
  Future<List<ProductModel>> getWishlistItems() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.*
      FROM wishlist_items w
      INNER JOIN products p ON w.productId = p.id
      ORDER BY w.addedAt DESC
    ''');

    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }

  /// Adds a product to the wishlist
  Future<void> addToWishlist(String productId) async {
    final db = await _dbHelper.database;
    await db.insert(
      'wishlist_items',
      {
        'productId': productId,
        'addedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Removes a product from the wishlist
  Future<void> removeFromWishlist(String productId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'wishlist_items',
      where: 'productId = ?',
      whereArgs: [productId],
    );
  }

  /// Checks whether a product is currently wishlisted
  Future<bool> isWishlisted(String productId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      'wishlist_items',
      where: 'productId = ?',
      whereArgs: [productId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Toggles wishlist state for a product and returns new state (true if now wishlisted)
  Future<bool> toggleWishlist(String productId) async {
    final bool currentlyWishlisted = await isWishlisted(productId);
    if (currentlyWishlisted) {
      await removeFromWishlist(productId);
      return false;
    } else {
      await addToWishlist(productId);
      return true;
    }
  }
}
