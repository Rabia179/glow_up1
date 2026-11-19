import 'package:flutter_test/flutter_test.dart';
import 'package:glow_up/data/database/database_helper.dart';
import 'package:glow_up/data/repositories/cart_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late CartRepository cartRepository;

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

        await db.insert('categories', {
          'id': 'skincare',
          'name': 'Skincare',
          'iconName': 'spa',
          'description': 'Serums and creams',
        });

        await db.insert('products', {
          'id': 'prod_1',
          'title': 'Luminous Dew Drops',
          'subtitle': '30ml Concentrate',
          'price': 4850,
          'badgeText': 'Bestseller',
          'imageUrl': 'https://example.com/dew.jpg',
          'category': 'skincare',
          'description': 'Hydrating serum',
          'isFeatured': 1,
          'isNewArrival': 0,
        });

        await db.insert('products', {
          'id': 'prod_2',
          'title': 'Rose Botanical Mist',
          'subtitle': '100ml Floral Mist',
          'price': 2200,
          'badgeText': 'New',
          'imageUrl': 'https://example.com/mist.jpg',
          'category': 'skincare',
          'description': 'Refreshing mist',
          'isFeatured': 0,
          'isNewArrival': 1,
        });
      },
    );

    DatabaseHelper.withDatabase(db);
    cartRepository = CartRepository();
  });

  tearDown(() async {
    await db.close();
    DatabaseHelper.resetDatabase();
  });

  test('Cart starts empty with 0 subtotal and 0 units', () async {
    final items = await cartRepository.getCartItems();
    final subtotal = await cartRepository.getSubtotal();
    final totalCount = await cartRepository.getTotalItemCount();

    expect(items, isEmpty);
    expect(subtotal, equals(0));
    expect(totalCount, equals(0));
  });

  test('Adding items to cart calculates item unit count and PKR subtotal', () async {
    await cartRepository.addToCart('prod_1', quantity: 1); // 4850
    await cartRepository.addToCart('prod_2', quantity: 2); // 2 * 2200 = 4400

    final items = await cartRepository.getCartItems();
    final subtotal = await cartRepository.getSubtotal();
    final totalUnits = await cartRepository.getTotalItemCount();

    expect(items.length, equals(2));
    expect(totalUnits, equals(3));
    expect(subtotal, equals(9250)); // 4850 + 4400 = 9250
  });

  test('Cart badge count agrees with actual displayable cart items', () async {
    await cartRepository.addToCart('prod_1', quantity: 3);

    final displayItems = await cartRepository.getCartItems();
    final totalCount = await cartRepository.getTotalItemCount();

    int computedUnits = 0;
    for (final item in displayItems) {
      computedUnits += item.quantity;
    }

    expect(totalCount, equals(computedUnits));
    expect(totalCount, equals(3));
  });

  test('Updating quantity adjusts cart totals and auto-removes when quantity <= 0', () async {
    await cartRepository.addToCart('prod_1', quantity: 1);
    final itemsInitial = await cartRepository.getCartItems();
    final cartItemId = itemsInitial.first.id!;

    // Increment
    await cartRepository.updateQuantity(cartItemId, 3);
    expect(await cartRepository.getTotalItemCount(), equals(3));
    expect(await cartRepository.getSubtotal(), equals(14550)); // 3 * 4850

    // Decrement to 0
    await cartRepository.updateQuantity(cartItemId, 0);
    expect(await cartRepository.getCartItems(), isEmpty);
    expect(await cartRepository.getTotalItemCount(), equals(0));
  });

  test('Removing an item removes it from SQLite cart', () async {
    await cartRepository.addToCart('prod_1', quantity: 1);
    await cartRepository.addToCart('prod_2', quantity: 1);

    final itemsBefore = await cartRepository.getCartItems();
    expect(itemsBefore.length, equals(2));

    final firstItemId = itemsBefore.first.id!;
    await cartRepository.removeFromCart(firstItemId);

    final itemsAfter = await cartRepository.getCartItems();
    expect(itemsAfter.length, equals(1));
    expect(itemsAfter.first.productId, equals('prod_2'));
  });

  test('Clearing cart deletes all line items atomically', () async {
    await cartRepository.addToCart('prod_1', quantity: 2);
    await cartRepository.addToCart('prod_2', quantity: 3);

    expect(await cartRepository.getTotalItemCount(), equals(5));

    await cartRepository.clearCart();

    expect(await cartRepository.getCartItems(), isEmpty);
    expect(await cartRepository.getTotalItemCount(), equals(0));
    expect(await cartRepository.getSubtotal(), equals(0));
  });
}
