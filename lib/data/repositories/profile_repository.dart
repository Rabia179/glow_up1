import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

/// User profile data model for local account preferences.
class UserProfileModel {
  final String name;
  final String email;
  final String skinType;
  final String phone;

  const UserProfileModel({
    required this.name,
    required this.email,
    required this.skinType,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'name': name,
      'email': email,
      'skinType': skinType,
      'phone': phone,
    };
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      name: map['name'] as String? ?? 'Maya Ahmed',
      email: map['email'] as String? ?? 'maya.ahmed@example.com',
      skinType: map['skinType'] as String? ?? 'Dry & Sensitive Skin',
      phone: map['phone'] as String? ?? '03001234567',
    );
  }

  UserProfileModel copyWith({
    String? name,
    String? email,
    String? skinType,
    String? phone,
  }) {
    return UserProfileModel(
      name: name ?? this.name,
      email: email ?? this.email,
      skinType: skinType ?? this.skinType,
      phone: phone ?? this.phone,
    );
  }
}

/// Repository for persisting local user profile data in SQLite and SharedPreferences.
class ProfileRepository {
  final DatabaseHelper _dbHelper;

  ProfileRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<void> _ensureTableExists(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        skinType TEXT NOT NULL,
        phone TEXT
      );
    ''');
  }

  /// Fetches the local user profile or initializes default profile
  Future<UserProfileModel> getProfile() async {
    String? savedName;
    String? savedEmail;
    String? savedSkinType;
    String? savedPhone;

    try {
      final prefs = await SharedPreferences.getInstance();
      savedName = prefs.getString('profile_name');
      savedEmail = prefs.getString('profile_email');
      savedSkinType = prefs.getString('profile_skinType');
      savedPhone = prefs.getString('profile_phone');
    } catch (_) {}

    final db = await _dbHelper.database;
    await _ensureTableExists(db);

    final List<Map<String, dynamic>> maps = await db.query(
      'user_profile',
      where: 'id = 1',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final profile = UserProfileModel.fromMap(maps.first);
      return UserProfileModel(
        name: (savedName != null && savedName.isNotEmpty) ? savedName : profile.name,
        email: (savedEmail != null && savedEmail.isNotEmpty) ? savedEmail : profile.email,
        skinType: (savedSkinType != null && savedSkinType.isNotEmpty) ? savedSkinType : profile.skinType,
        phone: (savedPhone != null && savedPhone.isNotEmpty) ? savedPhone : profile.phone,
      );
    } else {
      final defaultProfile = UserProfileModel(
        name: (savedName != null && savedName.isNotEmpty) ? savedName : 'Maya Ahmed',
        email: (savedEmail != null && savedEmail.isNotEmpty) ? savedEmail : 'maya.ahmed@example.com',
        skinType: (savedSkinType != null && savedSkinType.isNotEmpty) ? savedSkinType : 'Dry & Sensitive Skin',
        phone: (savedPhone != null && savedPhone.isNotEmpty) ? savedPhone : '03001234567',
      );
      await saveProfile(defaultProfile);
      return defaultProfile;
    }
  }

  /// Saves updated profile data to SQLite and SharedPreferences
  Future<void> saveProfile(UserProfileModel profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_name', profile.name);
      await prefs.setString('profile_email', profile.email);
      await prefs.setString('profile_skinType', profile.skinType);
      await prefs.setString('profile_phone', profile.phone);
    } catch (_) {}

    final db = await _dbHelper.database;
    await _ensureTableExists(db);

    await db.insert(
      'user_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
