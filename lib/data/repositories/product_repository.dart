import '../database/database_helper.dart';
import '../models/product.dart';

class ProductRepository {
  final DatabaseHelper _dbHelper;

  ProductRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  /// Fetches all products from SQLite
  Future<List<ProductModel>> getAllProducts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }

  /// Fetches a single product by its unique string ID
  Future<ProductModel?> getProductById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ProductModel.fromMap(maps.first);
    }
    return null;
  }

  /// Searches products by title, subtitle, or description using parameterized SQL LIKE
  Future<List<ProductModel>> searchProducts(String query) async {
    if (query.trim().isEmpty) return getAllProducts();

    final db = await _dbHelper.database;
    final String searchPattern = '%${query.trim()}%';

    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'title LIKE ? OR subtitle LIKE ? OR description LIKE ? OR category LIKE ?',
      whereArgs: [searchPattern, searchPattern, searchPattern, searchPattern],
    );

    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }

  /// Filters products by category ID/name
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'LOWER(category) = LOWER(?)',
      whereArgs: [category],
    );
    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }

  /// Fetches featured products for Home Screen edit
  Future<List<ProductModel>> getFeaturedProducts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'isFeatured = 1',
    );
    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }

  /// Fetches new arrival drop products
  Future<List<ProductModel>> getNewArrivals() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'isNewArrival = 1',
    );
    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }
}
