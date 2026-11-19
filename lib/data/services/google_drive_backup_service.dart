import 'dart:async';
import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

/// Metadata model for Google Drive backup files.
class DriveBackupItem {
  final String id;
  final String name;
  final int sizeBytes;
  final DateTime createdTime;

  const DriveBackupItem({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.createdTime,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String get formattedDate {
    final year = createdTime.year;
    final month = createdTime.month.toString().padLeft(2, '0');
    final day = createdTime.day.toString().padLeft(2, '0');
    final hour = createdTime.hour.toString().padLeft(2, '0');
    final minute = createdTime.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}

/// Service managing real Google Authentication, Drive file operations,
/// SQLite database backups, and transactional database restoration.
class GoogleDriveBackupService {
  static const String driveFolderName = 'GLOW_UP_Backups';
  static const List<String> requiredTables = [
    'categories',
    'products',
    'cart_items',
    'wishlist_items',
    'orders',
    'order_items',
    'user_profile',
  ];

  final GoogleSignIn _googleSignIn;
  final DatabaseHelper _dbHelper;
  final drive.DriveApi? _injectedDriveApi;

  GoogleDriveBackupService({
    GoogleSignIn? googleSignIn,
    DatabaseHelper? dbHelper,
    drive.DriveApi? driveApi,
  })  : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: [
                drive.DriveApi.driveFileScope,
              ],
            ),
        _dbHelper = dbHelper ?? DatabaseHelper(),
        _injectedDriveApi = driveApi;

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// Signs in the user to Google Authentication
  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      rethrow;
    }
  }

  /// Attempts silent sign-in if credentials exist
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      return account;
    } catch (_) {
      return null;
    }
  }

  /// Signs out / disconnects the Google account
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  /// Obtains authenticated Drive API instance
  Future<drive.DriveApi> getDriveApi() async {
    final injected = _injectedDriveApi;
    if (injected != null) return injected;

    final httpClient = await _googleSignIn.authenticatedClient();
    if (httpClient == null) {
      throw Exception('Failed to obtain authenticated Google HTTP client. Please sign in again.');
    }
    return drive.DriveApi(httpClient);
  }

  /// Finds or creates the GLOW_UP_Backups application folder in Google Drive
  Future<String> getOrCreateBackupFolder(drive.DriveApi driveApi) async {
    final query = "name = '$driveFolderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
    final folderList = await driveApi.files.list(q: query, $fields: "files(id, name)");

    final files = folderList.files;
    if (files != null && files.isNotEmpty) {
      return files.first.id ?? 'folder_id';
    }

    final folderFile = drive.File()
      ..name = driveFolderName
      ..mimeType = 'application/vnd.google-apps.folder';

    final createdFolder = await driveApi.files.create(folderFile);
    return createdFolder.id ?? 'folder_created';
  }

  /// Performs a real backup of the local SQLite database to Google Drive
  Future<DriveBackupItem> performBackup() async {
    if (!isSignedIn && _injectedDriveApi == null) {
      throw StateError('Google account is not connected. Sign in before performing a backup.');
    }

    final driveApi = await getDriveApi();
    final folderId = await getOrCreateBackupFolder(driveApi);

    // 1. Flush WAL & Pending Writes
    final db = await _dbHelper.database;
    try {
      await db.execute('PRAGMA wal_checkpoint(FULL);');
    } catch (_) {}

    // 2. Close active connection safely before copying
    await _dbHelper.closeDatabase();

    final dbPath = await _dbHelper.getDatabasePath();
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      // Reopen before throwing
      await _dbHelper.database;
      throw FileSystemException('Local database file does not exist at $dbPath');
    }

    final now = DateTime.now();
    final timestampStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
    final backupFileName = 'glow_up_backup_$timestampStr.db';

    final tempDir = await getTemporaryDirectory();
    final tempBackupFile = File(path.join(tempDir.path, backupFileName));
    await dbFile.copy(tempBackupFile.path);

    // Reopen local database so app stays responsive
    await _dbHelper.database;

    try {
      final fileLength = await tempBackupFile.length();
      final media = drive.Media(tempBackupFile.openRead(), fileLength);

      final driveFile = drive.File()
        ..name = backupFileName
        ..parents = [folderId]
        ..description = 'GLOW UP SQLite Database Backup ($timestampStr)';

      final uploaded = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
        $fields: "id, name, size, createdTime",
      );

      // Clean up temporary local file
      if (await tempBackupFile.exists()) {
        await tempBackupFile.delete();
      }

      return DriveBackupItem(
        id: uploaded.id!,
        name: uploaded.name ?? backupFileName,
        sizeBytes: int.tryParse(uploaded.size ?? '') ?? fileLength,
        createdTime: uploaded.createdTime ?? DateTime.now(),
      );
    } catch (e) {
      if (await tempBackupFile.exists()) {
        await tempBackupFile.delete();
      }
      rethrow;
    }
  }

  /// Retrieves list of backup files from the GLOW_UP_Backups folder in Google Drive
  Future<List<DriveBackupItem>> fetchBackups() async {
    if (!isSignedIn && _injectedDriveApi == null) {
      throw StateError('Google account is not connected.');
    }

    final driveApi = await getDriveApi();
    final folderId = await getOrCreateBackupFolder(driveApi);

    final query = "'$folderId' in parents and trashed = false";
    final fileList = await driveApi.files.list(
      q: query,
      orderBy: "createdTime desc",
      $fields: "files(id, name, size, createdTime)",
    );

    if (fileList.files == null || fileList.files!.isEmpty) {
      return [];
    }

    return fileList.files!.map((f) {
      return DriveBackupItem(
        id: f.id!,
        name: f.name ?? 'glow_up_backup.db',
        sizeBytes: int.tryParse(f.size ?? '') ?? 0,
        createdTime: f.createdTime ?? DateTime.now(),
      );
    }).toList();
  }

  /// Downloads a backup file from Google Drive and restores it safely into local SQLite storage
  Future<void> restoreBackup(DriveBackupItem backupItem) async {
    if (!isSignedIn && _injectedDriveApi == null) {
      throw StateError('Google account is not connected.');
    }

    final driveApi = await getDriveApi();

    // 1. Download file to temporary location
    final tempDir = await getTemporaryDirectory();
    final tempRestoreFile = File(path.join(tempDir.path, 'temp_restore_${backupItem.id}.db'));

    final media = await driveApi.files.get(
      backupItem.id,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final sink = tempRestoreFile.openWrite();
    await media.stream.pipe(sink);
    await sink.close();

    // 2. Validate downloaded database file integrity & schema
    await validateDatabaseFile(tempRestoreFile);

    // 3. Create recoverable local safety backup
    final dbPath = await _dbHelper.getDatabasePath();
    final activeDbFile = File(dbPath);
    final safetyBackupFile = File(path.join(tempDir.path, 'glow_up_safety_backup.db'));

    // Flush and close active database
    final db = await _dbHelper.database;
    try {
      await db.execute('PRAGMA wal_checkpoint(FULL);');
    } catch (_) {}
    await _dbHelper.closeDatabase();

    if (await activeDbFile.exists()) {
      await activeDbFile.copy(safetyBackupFile.path);
    }

    // 4. Safely replace active database file
    try {
      if (await activeDbFile.exists()) {
        await activeDbFile.delete();
      }

      final walFile = File('$dbPath-wal');
      final shmFile = File('$dbPath-shm');
      if (await walFile.exists()) await walFile.delete();
      if (await shmFile.exists()) await shmFile.delete();

      await tempRestoreFile.copy(activeDbFile.path);

      if (await tempRestoreFile.exists()) {
        await tempRestoreFile.delete();
      }

      // 5. Reopen & Verify restored database
      final reopenedDb = await _dbHelper.database;
      final verifyCount = await reopenedDb.rawQuery('SELECT COUNT(*) FROM products');
      if (verifyCount.isEmpty) {
        throw const FormatException('Verification query failed on restored database.');
      }

      // Cleanup safety backup on success
      if (await safetyBackupFile.exists()) {
        await safetyBackupFile.delete();
      }
    } catch (e) {
      // 6. Rollback to safety backup if replacement or verification failed
      if (await safetyBackupFile.exists()) {
        await _dbHelper.closeDatabase();
        if (await activeDbFile.exists()) await activeDbFile.delete();
        await safetyBackupFile.copy(activeDbFile.path);
        await safetyBackupFile.delete();
        await _dbHelper.database;
      }
      rethrow;
    }
  }

  /// Validates that a file is a valid SQLite database containing required GLOW UP tables
  Future<void> validateDatabaseFile(File dbFile) async {
    if (!await dbFile.exists()) {
      throw const FormatException('Downloaded backup file does not exist.');
    }
    if (await dbFile.length() == 0) {
      throw const FormatException('Downloaded backup file is empty.');
    }

    Database? testDb;
    try {
      try {
        testDb = await openDatabase(dbFile.path, readOnly: true);
      } catch (e) {
        throw FormatException('File is not a valid SQLite database: ${e.toString()}');
      }

      // Integrity check
      final integrityResult = await testDb.rawQuery('PRAGMA quick_check;');
      if (integrityResult.isEmpty ||
          integrityResult.first.values.first.toString().toLowerCase() != 'ok') {
        throw const FormatException('Database file integrity check failed.');
      }

      // Schema tables check
      final tableMaps = await testDb.rawQuery("SELECT name FROM sqlite_master WHERE type='table';");
      final existingTables = tableMaps.map((m) => m['name'].toString()).toSet();

      for (final table in requiredTables) {
        if (!existingTables.contains(table)) {
          throw FormatException('Backup database is missing required table: $table');
        }
      }
    } catch (e) {
      if (e is FormatException) rethrow;
      throw FormatException('Invalid or corrupt database backup file: ${e.toString()}');
    } finally {
      if (testDb != null && testDb.isOpen) {
        await testDb.close();
      }
    }
  }
}
