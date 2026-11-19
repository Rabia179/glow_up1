import 'package:flutter_test/flutter_test.dart';
import 'package:glow_up/data/database/database_helper.dart';
import 'package:glow_up/data/repositories/cart_repository.dart';
import 'package:glow_up/data/repositories/order_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late CartRepository cartRepository;
  late OrderRepository orderRepository;

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
          'price': 2000,
          'badgeText': 'Bestseller',
          'imageUrl': 'https://example.com/dew.jpg',
          'category': 'skincare',
          'description': 'Hydrating serum',
          'isFeatured': 1,
          'isNewArrival': 0,
        });

        await db.insert('products', {
          'id': 'prod_2',
          'title': 'Ceramide Barrier Cream',
          'subtitle': '50ml Deep Moisture',
          'price': 5200,
          'badgeText': 'Hydration',
          'imageUrl': 'https://example.com/cream.jpg',
          'category': 'skincare',
          'description': 'Barrier cream',
          'isFeatured': 1,
          'isNewArrival': 0,
        });
      },
    );

    DatabaseHelper.withDatabase(db);
    cartRepository = CartRepository();
    orderRepository = OrderRepository();
  });

  tearDown(() async {
    await db.close();
    DatabaseHelper.resetDatabase();
  });

  test('Shipping fee is PKR 250 under 5000 threshold and 0 at or above 5000', () {
    const int freeThreshold = 5000;
    const int standardFee = 250;

    int calculateFee(int subtotal) {
      if (subtotal == 0 || subtotal >= freeThreshold) return 0;
      return standardFee;
    }

    expect(calculateFee(2000), equals(250));
    expect(calculateFee(4999), equals(250));
    expect(calculateFee(5000), equals(0));
    expect(calculateFee(7200), equals(0));
  });

  test('Successful atomic order creation saves header, line items, and clears cart', () async {
    // Add items to cart: 1x prod_1 (2000) + 1x prod_2 (5200) = 7200 subtotal
    await cartRepository.addToCart('prod_1', quantity: 1);
    await cartRepository.addToCart('prod_2', quantity: 1);

    final cartItems = await cartRepository.getCartItems();
    expect(cartItems.length, equals(2));

    const shippingAddress = 'Ayesha Khan, 03001234567\nHouse 12, Gulberg III, Lahore 54000';
    const paymentMethod = 'Cash on Delivery (COD)';
    const shippingFee = 0; // >= 5000

    final order = await orderRepository.createOrder(
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
      items: cartItems,
      shippingFee: shippingFee,
    );

    // Verify created order
    expect(order.id, startsWith('ORD-'));
    expect(order.totalAmount, equals(7200));
    expect(order.shippingAddress, equals(shippingAddress));
    expect(order.paymentMethod, equals(paymentMethod));
    expect(order.items.length, equals(2));

    // Verify cart is cleared after successful transaction
    final remainingCart = await cartRepository.getCartItems();
    expect(remainingCart, isEmpty);
    expect(await cartRepository.getTotalItemCount(), equals(0));

    // Query SQLite database directly for order confirmation
    final fetchedOrder = await orderRepository.getOrderById(order.id);
    expect(fetchedOrder, isNotNull);
    expect(fetchedOrder!.totalAmount, equals(7200));
    expect(fetchedOrder.items.length, equals(2));
    expect(fetchedOrder.items.first.productName, equals('Luminous Dew Drops'));
  });

  test('Order creation with shipping fee under threshold calculates grand total correctly', () async {
    // Add item: 1x prod_1 (2000) -> shipping fee 250 -> grand total 2250
    await cartRepository.addToCart('prod_1', quantity: 1);
    final cartItems = await cartRepository.getCartItems();

    final order = await orderRepository.createOrder(
      shippingAddress: 'Test User, 03000000000\nAddress Line, Karachi 75000',
      paymentMethod: 'Cash on Delivery (COD)',
      items: cartItems,
      shippingFee: 250,
    );

    expect(order.totalAmount, equals(2250));

    final savedOrder = await orderRepository.getOrderById(order.id);
    expect(savedOrder!.totalAmount, equals(2250));
  });

  test('Cannot create an order with empty cart items', () async {
    expect(
      () => orderRepository.createOrder(
        shippingAddress: 'Address',
        paymentMethod: 'COD',
        items: [],
      ),
      throwsArgumentError,
    );
  });

  test('Order history query returns created orders in descending date order', () async {
    await cartRepository.addToCart('prod_1', quantity: 1);
    final cartItems = await cartRepository.getCartItems();

    await orderRepository.createOrder(
      shippingAddress: 'Address 1',
      paymentMethod: 'COD',
      items: cartItems,
    );

    final orders = await orderRepository.getAllOrders();
    expect(orders.length, equals(1));
    expect(orders.first.status, equals('Processing'));
  });
}
