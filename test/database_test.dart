import 'package:flutter_test/flutter_test.dart';
import 'package:glow_up/data/database/database_helper.dart';
import 'package:glow_up/data/repositories/cart_repository.dart';
import 'package:glow_up/data/repositories/category_repository.dart';
import 'package:glow_up/data/repositories/order_repository.dart';
import 'package:glow_up/data/repositories/product_repository.dart';
import 'package:glow_up/data/repositories/wishlist_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize FFI for running sqflite tests in Dart VM environment
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late DatabaseHelper dbHelper;
  late ProductRepository productRepo;
  late CategoryRepository categoryRepo;
  late CartRepository cartRepo;
  late WishlistRepository wishlistRepo;
  late OrderRepository orderRepo;

  setUp(() async {
    // Open isolated in-memory database per test
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

        await db.execute('''
          CREATE TABLE orders (
            id TEXT PRIMARY KEY,
            orderDate TEXT NOT NULL,
            totalAmount INTEGER NOT NULL,
            status TEXT NOT NULL,
            shippingAddress TEXT NOT NULL,
            paymentMethod TEXT NOT NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE order_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            orderId TEXT NOT NULL,
            productId TEXT NOT NULL,
            productName TEXT NOT NULL,
            price INTEGER NOT NULL,
            quantity INTEGER NOT NULL CHECK (quantity > 0),
            FOREIGN KEY (orderId) REFERENCES orders (id) ON DELETE CASCADE
          );
        ''');

        // Seed data
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
          'description': 'Rosehip dew concentrate.',
          'isFeatured': 1,
          'isNewArrival': 0,
        });

        await db.insert('products', {
          'id': 'product_2',
          'title': 'Velvet Petal Lip Oil',
          'subtitle': 'Tinted Nourishment',
          'price': 2400,
          'badgeText': '★ 4.9',
          'imageUrl': 'https://example.com/lip.jpg',
          'category': 'skincare',
          'description': 'Plush lip oil.',
          'isFeatured': 1,
          'isNewArrival': 0,
        });
      },
    );

    dbHelper = DatabaseHelper.withDatabase(db);
    productRepo = ProductRepository(dbHelper: dbHelper);
    categoryRepo = CategoryRepository(dbHelper: dbHelper);
    cartRepo = CartRepository(dbHelper: dbHelper);
    wishlistRepo = WishlistRepository(dbHelper: dbHelper);
    orderRepo = OrderRepository(dbHelper: dbHelper);
  });

  tearDown(() async {
    await db.close();
    DatabaseHelper.resetDatabase();
  });

  group('SQLite Database & Seed Tests', () {
    test('Categories and Products seed data exist in PKR', () async {
      final categories = await categoryRepo.getAllCategories();
      expect(categories.length, equals(1));
      expect(categories.first.name, equals('Skincare'));

      final products = await productRepo.getAllProducts();
      expect(products.length, equals(2));
      expect(products.first.price, equals(4850)); // PKR 4,850
    });

    test('Fetch product by ID', () async {
      final product = await productRepo.getProductById('product_1');
      expect(product, isNotNull);
      expect(product!.title, equals('Luminous Dew Drops'));
    });

    test('Search products by keyword', () async {
      final results = await productRepo.searchProducts('Dew');
      expect(results.length, equals(1));
      expect(results.first.id, equals('product_1'));
    });
  });

  group('Cart Repository Tests', () {
    test('Add item to cart and calculate subtotal', () async {
      await cartRepo.addToCart('product_1', quantity: 2); // 2 * 4,850 = 9,700
      final items = await cartRepo.getCartItems();

      expect(items.length, equals(1));
      expect(items.first.quantity, equals(2));
      expect(items.first.itemSubtotal, equals(9700));

      final subtotal = await cartRepo.getSubtotal();
      expect(subtotal, equals(9700));

      final totalQty = await cartRepo.getTotalItemCount();
      expect(totalQty, equals(2));
    });

    test('Increment cart item quantity on subsequent add', () async {
      await cartRepo.addToCart('product_1', quantity: 1);
      await cartRepo.addToCart('product_1', quantity: 2);

      final items = await cartRepo.getCartItems();
      expect(items.length, equals(1));
      expect(items.first.quantity, equals(3));
    });

    test('Update quantity and remove when quantity <= 0', () async {
      await cartRepo.addToCart('product_1', quantity: 2);
      final items = await cartRepo.getCartItems();
      final cartItemId = items.first.id!;

      await cartRepo.updateQuantity(cartItemId, 0); // Should auto remove
      final updatedItems = await cartRepo.getCartItems();
      expect(updatedItems, isEmpty);
    });
  });

  group('Wishlist Repository Tests', () {
    test('Add and remove from wishlist', () async {
      expect(await wishlistRepo.isWishlisted('product_1'), isFalse);

      await wishlistRepo.addToWishlist('product_1');
      expect(await wishlistRepo.isWishlisted('product_1'), isTrue);

      final wishlisted = await wishlistRepo.getWishlistItems();
      expect(wishlisted.length, equals(1));
      expect(wishlisted.first.title, equals('Luminous Dew Drops'));

      await wishlistRepo.removeFromWishlist('product_1');
      expect(await wishlistRepo.isWishlisted('product_1'), isFalse);
    });
  });

  group('Order Repository Tests', () {
    test('Create order in transaction and clear cart', () async {
      await cartRepo.addToCart('product_1', quantity: 1); // 4,850
      await cartRepo.addToCart('product_2', quantity: 2); // 2 * 2,400 = 4,800 -> Total = 9,650

      final cartItems = await cartRepo.getCartItems();
      expect(cartItems.length, equals(2));

      final order = await orderRepo.createOrder(
        shippingAddress: 'House 42, Street 5, F-7/2, Islamabad',
        paymentMethod: 'Cash on Delivery',
        items: cartItems,
      );

      expect(order.id, startsWith('ORD-'));
      expect(order.totalAmount, equals(9650)); // PKR 9,650
      expect(order.paymentMethod, equals('Cash on Delivery'));

      // Cart should now be empty after order creation
      final remainingCart = await cartRepo.getCartItems();
      expect(remainingCart, isEmpty);

      // Verify order history
      final orders = await orderRepo.getAllOrders();
      expect(orders.length, equals(1));
      expect(orders.first.items.length, equals(2));
    });
  });
}
