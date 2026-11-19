import 'package:flutter_test/flutter_test.dart';
import 'package:glow_up/data/database/database_helper.dart';
import 'package:glow_up/data/repositories/cart_repository.dart';
import 'package:glow_up/data/repositories/order_repository.dart';
import 'package:glow_up/data/repositories/profile_repository.dart';
import 'package:glow_up/data/repositories/wishlist_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late WishlistRepository wishlistRepository;
  late CartRepository cartRepository;
  late OrderRepository orderRepository;
  late ProfileRepository profileRepository;

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
          'title': 'Velvet Petal Lip Oil',
          'subtitle': 'Tinted Oil',
          'price': 2400,
          'badgeText': 'New',
          'imageUrl': 'https://example.com/lipoil.jpg',
          'category': 'skincare',
          'description': 'Lip oil',
          'isFeatured': 1,
          'isNewArrival': 0,
        });
      },
    );

    DatabaseHelper.withDatabase(db);
    wishlistRepository = WishlistRepository();
    cartRepository = CartRepository();
    orderRepository = OrderRepository();
    profileRepository = ProfileRepository();
  });

  tearDown(() async {
    await db.close();
    DatabaseHelper.resetDatabase();
  });

  test('Wishlist starts empty and loads items when added', () async {
    expect(await wishlistRepository.getWishlistItems(), isEmpty);

    await wishlistRepository.addToWishlist('prod_1');
    final items = await wishlistRepository.getWishlistItems();

    expect(items.length, equals(1));
    expect(items.first.title, equals('Luminous Dew Drops'));
    expect(await wishlistRepository.isWishlisted('prod_1'), isTrue);
  });

  test('Removing an item from wishlist updates SQLite storage', () async {
    await wishlistRepository.addToWishlist('prod_1');
    await wishlistRepository.addToWishlist('prod_2');

    expect((await wishlistRepository.getWishlistItems()).length, equals(2));

    await wishlistRepository.removeFromWishlist('prod_1');

    final remaining = await wishlistRepository.getWishlistItems();
    expect(remaining.length, equals(1));
    expect(remaining.first.id, equals('prod_2'));
    expect(await wishlistRepository.isWishlisted('prod_1'), isFalse);
  });

  test('Adding wishlisted product to cart updates cart line items', () async {
    await wishlistRepository.addToWishlist('prod_1');
    final wishItem = (await wishlistRepository.getWishlistItems()).first;

    await cartRepository.addToCart(wishItem.id, quantity: 1);

    final cartItems = await cartRepository.getCartItems();
    expect(cartItems.length, equals(1));
    expect(cartItems.first.product?.title, equals('Luminous Dew Drops'));
  });

  test('Order history returns empty when no orders exist and fetches saved orders when created', () async {
    expect(await orderRepository.getAllOrders(), isEmpty);

    await cartRepository.addToCart('prod_1', quantity: 2);
    final cartItems = await cartRepository.getCartItems();

    final order = await orderRepository.createOrder(
      shippingAddress: 'Maya Ahmed, 03001234567\nLahore 54000',
      paymentMethod: 'Cash on Delivery (COD)',
      items: cartItems,
    );

    final orderHistory = await orderRepository.getAllOrders();
    expect(orderHistory.length, equals(1));
    expect(orderHistory.first.id, equals(order.id));
    expect(orderHistory.first.totalAmount, equals(9700));

    final fetched = await orderRepository.getOrderById(order.id);
    expect(fetched, isNotNull);
    expect(fetched!.items.first.productName, equals('Luminous Dew Drops'));
  });

  test('Profile information persists and updates in SQLite', () async {
    final profileInitial = await profileRepository.getProfile();
    expect(profileInitial.name, equals('Maya Ahmed'));

    final updatedProfile = profileInitial.copyWith(
      name: 'Maya A. Khan',
      skinType: 'Oily & Acne Prone',
    );
    await profileRepository.saveProfile(updatedProfile);

    final profileFetched = await profileRepository.getProfile();
    expect(profileFetched.name, equals('Maya A. Khan'));
    expect(profileFetched.skinType, equals('Oily & Acne Prone'));
  });
}
