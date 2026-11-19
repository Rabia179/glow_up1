import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glow_up/data/database/database_helper.dart';
import 'package:glow_up/data/repositories/cart_repository.dart';
import 'package:glow_up/data/repositories/profile_repository.dart';
import 'package:glow_up/data/repositories/wishlist_repository.dart';
import 'package:glow_up/data/services/google_drive_backup_service.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as path;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getTemporaryPath() async {
    return Directory.systemTemp.path;
  }
}

class MockDriveApi implements drive.DriveApi {
  final Map<String, List<int>> _storage = {};
  final List<drive.File> _filesMeta = [];
  bool shouldFailUpload = false;

  @override
  drive.FilesResource get files => MockFilesResource(this);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFilesResource implements drive.FilesResource {
  final MockDriveApi api;

  MockFilesResource(this.api);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #list) {
      final q = invocation.namedArguments[#q] as String?;
      if (q != null && q.contains("mimeType = 'application/vnd.google-apps.folder'")) {
        return Future.value(
          drive.FileList(
            files: [drive.File()..id = 'folder_123'..name = 'GLOW_UP_Backups'],
          ),
        );
      }
      return Future.value(drive.FileList(files: List.from(api._filesMeta)));
    }

    if (invocation.memberName == #create) {
      final request = invocation.positionalArguments.first as drive.File;
      final uploadMedia = invocation.namedArguments[#uploadMedia] as drive.Media?;

      if (api.shouldFailUpload) {
        return Future<drive.File>.error(Exception('Simulated Google Drive network upload error'));
      }

      final id = 'drive_file_${DateTime.now().millisecondsSinceEpoch}';
      final name = request.name ?? 'backup.db';

      final completer = Completer<drive.File>();
      (() async {
        List<int> bytes = [];
        if (uploadMedia != null) {
          bytes = await uploadMedia.stream.fold<List<int>>([], (prev, elem) => prev..addAll(elem));
        }

        api._storage[id] = bytes;

        final created = drive.File()
          ..id = id
          ..name = name
          ..size = bytes.length.toString()
          ..createdTime = DateTime.now();

        api._filesMeta.add(created);
        completer.complete(created);
      })();

      return completer.future;
    }

    if (invocation.memberName == #get) {
      final fileId = invocation.positionalArguments.first as String;
      final downloadOptions = invocation.namedArguments[#downloadOptions] as drive.DownloadOptions?;

      if (downloadOptions == drive.DownloadOptions.fullMedia) {
        final bytes = api._storage[fileId] ?? [];
        final stream = Stream<List<int>>.value(bytes);
        return Future.value(drive.Media(stream, bytes.length));
      }
      final meta = api._filesMeta.firstWhere((f) => f.id == fileId);
      return Future.value(meta);
    }

    return super.noSuchMethod(invocation);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = FakePathProviderPlatform();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late String dbFilePath;
  late MockDriveApi mockDriveApi;
  late GoogleDriveBackupService backupService;
  late CartRepository cartRepository;
  late WishlistRepository wishlistRepository;
  late ProfileRepository profileRepository;

  setUp(() async {
    final tempDir = Directory.systemTemp.createTempSync('glow_up_test_');
    dbFilePath = path.join(tempDir.path, 'glow_up.db');

    db = await openDatabase(
      dbFilePath,
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

        await db.execute('''
          CREATE TABLE user_profile (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            skinType TEXT NOT NULL,
            phone TEXT
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
      },
    );

    DatabaseHelper.withDatabase(db);
    mockDriveApi = MockDriveApi();
    backupService = GoogleDriveBackupService(driveApi: mockDriveApi);
    cartRepository = CartRepository();
    wishlistRepository = WishlistRepository();
    profileRepository = ProfileRepository();
  });

  tearDown(() async {
    try {
      await db.close();
    } catch (_) {}
    DatabaseHelper.resetDatabase();
  });

  test('Database validation rejects non-SQLite files and files missing required tables', () async {
    final tempDir = Directory.systemTemp.createTempSync();
    final invalidFile = File(path.join(tempDir.path, 'invalid.db'))..writeAsStringSync('NOT A SQLITE FILE');

    await expectLater(
      backupService.validateDatabaseFile(invalidFile),
      throwsFormatException,
    );

    tempDir.deleteSync(recursive: true);
  });

  test('Drive backup service creates folder, lists files, and handles upload errors safely', () async {
    final folderId = await backupService.getOrCreateBackupFolder(mockDriveApi);
    expect(folderId, equals('folder_123'));

    mockDriveApi.shouldFailUpload = true;
    expect(
      () => backupService.performBackup(),
      throwsA(isA<Exception>()),
    );
  });

  test('Backup and restore pipeline preserves SQLite schema, cart, wishlist, and profile data', () async {
    // 1. Populate initial user state
    await cartRepository.addToCart('prod_1', quantity: 2);
    await wishlistRepository.addToWishlist('prod_1');
    await profileRepository.saveProfile(
      const UserProfileModel(
        name: 'Maya Test User',
        email: 'maya@test.com',
        skinType: 'Sensitive Glow',
        phone: '03009998877',
      ),
    );

    expect(await cartRepository.getTotalItemCount(), equals(2));
    expect(await wishlistRepository.isWishlisted('prod_1'), isTrue);
    expect((await profileRepository.getProfile()).name, equals('Maya Test User'));

    // 2. Perform Drive Backup
    final backupItem = await backupService.performBackup();
    expect(backupItem.id, startsWith('drive_file_'));

    // 3. Clear local state
    await cartRepository.clearCart();
    await wishlistRepository.removeFromWishlist('prod_1');
    expect(await cartRepository.getTotalItemCount(), equals(0));
    expect(await wishlistRepository.isWishlisted('prod_1'), isFalse);

    // 4. Restore from Drive Backup
    await backupService.restoreBackup(backupItem);

    // 5. Verify restored state
    expect(await cartRepository.getTotalItemCount(), equals(2));
    expect(await wishlistRepository.isWishlisted('prod_1'), isTrue);
    final restoredProfile = await profileRepository.getProfile();
    expect(restoredProfile.name, equals('Maya Test User'));
    expect(restoredProfile.skinType, equals('Sensitive Glow'));
  });
}
