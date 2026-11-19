import 'package:flutter_test/flutter_test.dart';
import 'package:glow_up/data/database/database_helper.dart';
import 'package:glow_up/data/repositories/cart_repository.dart';
import 'package:glow_up/data/repositories/category_repository.dart';
import 'package:glow_up/data/repositories/product_repository.dart';
import 'package:glow_up/data/repositories/wishlist_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            iconName TEXT NOT NULL,
            description TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            subtitle TEXT NOT NULL,
            price INTEGER NOT NULL,
            badgeText TEXT,
            imageUrl TEXT NOT NULL,
            category TEXT NOT NULL,
            description TEXT,
            isFeatured INTEGER NOT NULL DEFAULT 0,
            isNewArrival INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (category) REFERENCES categories (id) ON DELETE CASCADE
          );
        ''');

        await db.execute('''
          CREATE TABLE cart_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            productId TEXT NOT NULL UNIQUE,
            quantity INTEGER NOT NULL CHECK (quantity > 0),
            FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
          );
        ''');

        await db.execute('''
          CREATE TABLE wishlist_items (
            productId TEXT PRIMARY KEY,
            addedAt TEXT NOT NULL,
            FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
          );
        ''');

        await db.insert('categories', {
          'id': 'skincare',
          'name': 'Skincare',
          'iconName': 'spa',
          'description': 'Serums and creams',
        });

        await db.insert('products', {
          'id': 'product_1',
          'title': 'Luminous Dew Drops',
          'subtitle': '30ml Elixir Concentrate',
          'price': 4850,
          'badgeText': 'Bestseller',
          'imageUrl': 'https://example.com/dew.jpg',
          'category': 'skincare',
          'description': 'Rosehip dew concentrate for natural radiance.',
          'isFeatured': 1,
          'isNewArrival': 0,
        });
      },
    );

    DatabaseHelper.withDatabase(db);
  });

  tearDown(() async {
    await db.close();
    DatabaseHelper.resetDatabase();
  });

  test('Categories screen data source loads SQLite categories', () async {
    final repo = CategoryRepository();
    final categories = await repo.getAllCategories();
    expect(categories.length, equals(1));
    expect(categories.first.id, equals('skincare'));
    expect(categories.first.name, equals('Skincare'));
  });

  test('Product listing data source filters by category and keyword search', () async {
    final repo = ProductRepository();

    final skincareProducts = await repo.getProductsByCategory('skincare');
    expect(skincareProducts.length, equals(1));
    expect(skincareProducts.first.title, equals('Luminous Dew Drops'));

    final searchResults = await repo.searchProducts('Dew');
    expect(searchResults.length, equals(1));
    expect(searchResults.first.id, equals('product_1'));
  });

  test('Product details actions test cart and wishlist integration', () async {
    final cartRepo = CartRepository();
    final wishlistRepo = WishlistRepository();

    // Verify initial state
    expect(await wishlistRepo.isWishlisted('product_1'), isFalse);

    // Toggle wishlist
    final nowFav = await wishlistRepo.toggleWishlist('product_1');
    expect(nowFav, isTrue);
    expect(await wishlistRepo.isWishlisted('product_1'), isTrue);

    // Add product to cart from details screen
    await cartRepo.addToCart('product_1', quantity: 2);
    final cartItems = await cartRepo.getCartItems();
    expect(cartItems.length, equals(1));
    expect(cartItems.first.quantity, equals(2));
    expect(cartItems.first.itemSubtotal, equals(9700));
  });
}
