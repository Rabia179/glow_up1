import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/category.dart';
import '../models/product.dart';

/// Singleton SQLite Database Helper for GLOW UP application.
class DatabaseHelper {
  static const String _databaseName = 'glow_up.db';
  static const int _databaseVersion = 1;

  static DatabaseHelper? _instance;
  static Database? _database;
  static String? _customDbPath;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  /// Optional constructor for testing or custom database instances
  DatabaseHelper.withDatabase(Database db) {
    _database = db;
    _customDbPath = db.path;
    _instance = this;
  }

  /// Resets database instance for isolated testing
  static void resetDatabase() {
    _database = null;
    _instance = null;
    _customDbPath = null;
  }

  /// Closes active database connection safely
  Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
    _database = null;
  }

  /// Returns absolute file path to local SQLite database file
  Future<String> getDatabasePath() async {
    if (_customDbPath != null && _customDbPath!.isNotEmpty) {
      return _customDbPath!;
    }
    if (_database != null && _database!.path.isNotEmpty) {
      return _database!.path;
    }
    final String dbPath = await getDatabasesPath();
    return join(dbPath, _databaseName);
  }

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = _customDbPath ?? join(await getDatabasesPath(), _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enable SQLite Foreign Key constraints
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        iconName TEXT NOT NULL,
        description TEXT
      );
    ''');

    // 2. Products Table
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

    // 3. Cart Items Table
    await db.execute('''
      CREATE TABLE cart_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId TEXT NOT NULL UNIQUE,
        quantity INTEGER NOT NULL CHECK (quantity > 0),
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
      );
    ''');

    // 4. Wishlist Items Table
    await db.execute('''
      CREATE TABLE wishlist_items (
        productId TEXT PRIMARY KEY,
        addedAt TEXT NOT NULL,
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
      );
    ''');

    // 5. Orders Table
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

    // 6. Order Items Table
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

    // 7. Local Profile Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        skinType TEXT NOT NULL,
        phone TEXT
      );
    ''');

    // Seed initial demo data
    await _seedDatabase(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations safely here
  }

  /// Seeds initial categories and products without inserting duplicates
  Future<void> seedIfNeeded() async {
    if (_database == null) return;
    await _seedDatabase(_database!);
  }

  Future<void> _seedDatabase(Database db) async {
    // 1. Seed Categories
    final List<CategoryModel> categories = [
      const CategoryModel(
        id: 'skincare',
        name: 'Skincare',
        iconName: 'spa',
        description: 'Restorative serums, essences, and moisture barriers.',
      ),
      const CategoryModel(
        id: 'makeup',
        name: 'Makeup',
        iconName: 'brush',
        description: 'Luminous lip oils, tints, and glowing enhancements.',
      ),
      const CategoryModel(
        id: 'haircare',
        name: 'Haircare',
        iconName: 'cyclone',
        description: 'Nourishing oils, scalp treats, and gloss serums.',
      ),
      const CategoryModel(
        id: 'fragrance',
        name: 'Fragrance',
        iconName: 'local_florist',
        description: 'Artisanal botanical scents and Eau de Parfum.',
      ),
      const CategoryModel(
        id: 'body_care',
        name: 'Body Care',
        iconName: 'water_drop',
        description: 'Rich body creams, elixirs, and sensory oils.',
      ),
    ];

    for (final cat in categories) {
      await db.insert(
        'categories',
        cat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    // 2. Seed Products
    final List<ProductModel> products = [
      const ProductModel(
        id: 'product_1',
        title: 'Luminous Dew Drops',
        subtitle: '30ml Elixir Concentrate',
        price: 4850,
        badgeText: 'Bestseller',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuB9hLeiB646H984oa6wUCKjdTXABqKz3ptwWIvDcRNT0MH3hpBLsR1IaYA4k6Jc64rmryKBjRmVws-zVjCQRCnx7U-9krZ7ZDbA-M2yLtfpvpw2tkmCcrzrP2k2XRvrgIpVK9EAEiqXmyPYXzPUiggdpbqeBk44C2p2ToTFPEkfp9ut1CK9Hpgwgw938UK0rVVSfwS9ri39G524avGz-zpjqHphbXlNRnHmmHlaSd-sgpU79x1sl0kC2A',
        category: 'skincare',
        description:
            'Concentrated rosehip and niacinamide dew drops formulated for intensive hydration and natural radiance.',
        isFeatured: true,
      ),
      const ProductModel(
        id: 'product_2',
        title: 'Velvet Petal Lip Oil',
        subtitle: 'Tinted Nourishment',
        price: 2400,
        badgeText: '★ 4.9 (120)',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDIFsRz9U9wMbrvbJoVfzZVoJYUXq0e4DibWvcCyT-TqRVEW9v_Vp85eIOjl1JIBcsnQeQH5z1pppEa2TpOVZ4pJjeQdl3d2quLfhF6xVey45q42Ic2WBT2dsYembwjUCWsMa8j0uuWRrQwgNFcADaB_tcCttnCsAXX7ZFogAbiUBbIF2bKQLlsa5lWQ86l7oYJOLlzIFnI-v9PN59R_AjMUEGTcRYnbS9cdYZfLsJS797Y69phNqE0pg',
        category: 'makeup',
        description:
            'Ultra-lightweight lip oil infused with cold-pressed rose petals for a non-sticky, plush sheen.',
        isFeatured: true,
      ),
      const ProductModel(
        id: 'product_3',
        title: 'Ceramide Barrier Cream',
        subtitle: '50ml Deep Moisture',
        price: 5200,
        badgeText: 'Hydration',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDaPXv9MTdf2alsCV9ABsTqhNd4JryxYmDEOKKF1g7iXdH_zMOMqJpnl5xTA4guF63tnW6dGOSwaZSaMGNmO0kqFjVVksLrGGyrGkZ8YpV3tv1kUahSBTUSPPom66J_givm6lxNC7KB8YlRknXqtMf2UaFf-Nel_b3Dq8e5_1D9zcC1x58wh4mpPIaWIZ2fmKjK5I2XXVDxN49SGohsiYrZGS9XDZs1nWRsj4ELjKvrLH-J38OPy1zQBQ',
        category: 'skincare',
        description:
            'Rich restorative cream packed with triple ceramides to reinforce moisture retention and soothe skin.',
        isFeatured: true,
      ),
      const ProductModel(
        id: 'product_4',
        title: 'Rose Quartz Gua Sha & Facial Oil',
        subtitle: 'Sculpts & deeply locks in moisture',
        price: 6500,
        badgeText: 'Self-Care Set',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCLHVfmRJmMIYmthTj5-AEe-0l4e2Tko5veXpw82imIOfTpqdckWUZArM3GKcr_oK70vIpCQrv5eSz6cHWj4ngetvnPWWCu0r_jnrxHMWszGiusPEtGwJysuGYndLJWpnOSGid46m5k_GtCQ-JJYl9Y7qe4mddUvuJl0tbDsDA9GXDQfjD_llDhKR-urlLQSVC4hxz73GkPYyJl_HsYFKVOIZPIcj1ZOgd9fU_N-RIBj7vAvxnyFwufyQ',
        category: 'skincare',
        description:
            'Hand-carved genuine rose quartz sculpting tool paired with botanical facial oil.',
        isNewArrival: true,
      ),
      const ProductModel(
        id: 'product_5',
        title: 'Rosehip Renewal Cleanser',
        subtitle: '150ml Hydrating Milky Wash',
        price: 3200,
        badgeText: 'Gentle',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuB9hLeiB646H984oa6wUCKjdTXABqKz3ptwWIvDcRNT0MH3hpBLsR1IaYA4k6Jc64rmryKBjRmVws-zVjCQRCnx7U-9krZ7ZDbA-M2yLtfpvpw2tkmCcrzrP2k2XRvrgIpVK9EAEiqXmyPYXzPUiggdpbqeBk44C2p2ToTFPEkfp9ut1CK9Hpgwgw938UK0rVVSfwS9ri39G524avGz-zpjqHphbXlNRnHmmHlaSd-sgpU79x1sl0kC2A',
        category: 'skincare',
        description: 'Sulfate-free milky cleanser that dissolves dirt while keeping skin soft.',
      ),
      const ProductModel(
        id: 'product_6',
        title: 'Silk Petal Rose Perfume',
        subtitle: '50ml Artisanal Eau de Parfum',
        price: 8900,
        badgeText: 'Luxury Drop',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCLHVfmRJmMIYmthTj5-AEe-0l4e2Tko5veXpw82imIOfTpqdckWUZArM3GKcr_oK70vIpCQrv5eSz6cHWj4ngetvnPWWCu0r_jnrxHMWszGiusPEtGwJysuGYndLJWpnOSGid46m5k_GtCQ-JJYl9Y7qe4mddUvuJl0tbDsDA9GXDQfjD_llDhKR-urlLQSVC4hxz73GkPYyJl_HsYFKVOIZPIcj1ZOgd9fU_N-RIBj7vAvxnyFwufyQ',
        category: 'fragrance',
        description: 'Artisanal rose water and soft amber accord creating an elegant sensory aroma.',
        isNewArrival: true,
      ),
      const ProductModel(
        id: 'product_7',
        title: 'Botanical Gloss Scalp Serum',
        subtitle: '50ml Nourishing Scalp Oil',
        price: 3800,
        badgeText: 'Scalp Care',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCLHVfmRJmMIYmthTj5-AEe-0l4e2Tko5veXpw82imIOfTpqdckWUZArM3GKcr_oK70vIpCQrv5eSz6cHWj4ngetvnPWWCu0r_jnrxHMWszGiusPEtGwJysuGYndLJWpnOSGid46m5k_GtCQ-JJYl9Y7qe4mddUvuJl0tbDsDA9GXDQfjD_llDhKR-urlLQSVC4hxz73GkPYyJl_HsYFKVOIZPIcj1ZOgd9fU_N-RIBj7vAvxnyFwufyQ',
        category: 'haircare',
        description: 'Nourishing botanical scalp and hair gloss elixir for root vitality and glass sheen.',
        isFeatured: true,
      ),
      const ProductModel(
        id: 'product_8',
        title: 'Velvet Rose Body Cream',
        subtitle: '200ml Rich Lipid Moisture',
        price: 4500,
        badgeText: 'Body Luxury',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDaPXv9MTdf2alsCV9ABsTqhNd4JryxYmDEOKKF1g7iXdH_zMOMqJpnl5xTA4guF63tnW6dGOSwaZSaMGNmO0kqFjVVksLrGGyrGkZ8YpV3tv1kUahSBTUSPPom66J_givm6lxNC7KB8YlRknXqtMf2UaFf-Nel_b3Dq8e5_1D9zcC1x58wh4mpPIaWIZ2fmKjK5I2XXVDxN49SGohsiYrZGS9XDZs1nWRsj4ELjKvrLH-J38OPy1zQBQ',
        category: 'body_care',
        description: 'Ultra-rich body cream infused with cold-pressed rosehip and lipid ceramides.',
      ),
    ];

    for (final prod in products) {
      await db.insert(
        'products',
        prod.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }
}
