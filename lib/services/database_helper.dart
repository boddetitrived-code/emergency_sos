import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/emergency_card.dart';
import '../models/emergency_contact.dart';
import '../models/sos_alert.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  /// Allow injecting a mock or in-memory DB for testing
  @visibleForTesting
  static void setMockDatabase(Database? db) {
    _database = db;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static void initializeFfiIfNeeded() {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> _initDatabase() async {
    initializeFfiIfNeeded();

    String path;
    if (kIsWeb) {
      path = 'emergency_sos.db';
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, 'emergency_sos.db');
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Emergency Info Card Table
    await db.execute('''
      CREATE TABLE emergency_card (
        id TEXT PRIMARY KEY,
        fullName TEXT NOT NULL,
        photoPath TEXT,
        bloodGroup TEXT,
        dateOfBirth TEXT,
        medicalConditions TEXT,
        allergies TEXT,
        currentMedications TEXT,
        emergencyContactName TEXT,
        emergencyContactPhone TEXT,
        additionalNotes TEXT,
        showOnLockScreen INTEGER DEFAULT 1,
        updatedAt TEXT NOT NULL
      )
    ''');

    // 2. Emergency Contacts Table
    await db.execute('''
      CREATE TABLE emergency_contacts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        relationship TEXT,
        isPrimary INTEGER DEFAULT 0,
        isSosRecipient INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL
      )
    ''');

    // 3. SOS Alerts History Table
    await db.execute('''
      CREATE TABLE sos_alerts (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        userName TEXT,
        message TEXT,
        latitude REAL,
        longitude REAL,
        isLocationOutdated INTEGER DEFAULT 0,
        googleMapsUrl TEXT,
        recipientPhones TEXT,
        status TEXT NOT NULL,
        statusMessage TEXT,
        isTest INTEGER DEFAULT 0
      )
    ''');

    // 4. App Settings Table
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Insert initial default settings
    await db.insert('app_settings', {
      'key': 'countdown_seconds',
      'value': '5',
    });
    await db.insert('app_settings', {
      'key': 'tracking_duration_minutes',
      'value': '30',
    });
  }

  // ==================== EMERGENCY CARD CRUD ====================

  Future<EmergencyCard?> getEmergencyCard() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'emergency_card',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return EmergencyCard.fromMap(maps.first);
    }
    return null;
  }

  Future<void> saveEmergencyCard(EmergencyCard card) async {
    final db = await database;
    await db.insert(
      'emergency_card',
      card.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteEmergencyCard() async {
    final db = await database;
    await db.delete('emergency_card');
  }

  // ==================== CONTACTS CRUD ====================

  Future<List<EmergencyContact>> getContacts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'emergency_contacts',
      orderBy: 'isPrimary DESC, name ASC',
    );
    return maps.map((m) => EmergencyContact.fromMap(m)).toList();
  }

  Future<EmergencyContact?> getPrimaryContact() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'emergency_contacts',
      where: 'isPrimary = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return EmergencyContact.fromMap(maps.first);
    }
    // If no primary is marked, return first contact if any
    final all = await getContacts();
    return all.isNotEmpty ? all.first : null;
  }

  Future<void> insertContact(EmergencyContact contact) async {
    final db = await database;
    await db.transaction((txn) async {
      if (contact.isPrimary) {
        // Demote existing primary contacts
        await txn.update(
          'emergency_contacts',
          {'isPrimary': 0},
          where: 'isPrimary = ?',
          whereArgs: [1],
        );
      }
      await txn.insert(
        'emergency_contacts',
        contact.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> updateContact(EmergencyContact contact) async {
    final db = await database;
    await db.transaction((txn) async {
      if (contact.isPrimary) {
        // Demote existing primary contacts
        await txn.update(
          'emergency_contacts',
          {'isPrimary': 0},
          where: 'isPrimary = ?',
          whereArgs: [1],
        );
      }
      await txn.update(
        'emergency_contacts',
        contact.toMap(),
        where: 'id = ?',
        whereArgs: [contact.id],
      );
    });
  }

  Future<void> setPrimaryContact(String contactId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('emergency_contacts', {'isPrimary': 0});
      await txn.update(
        'emergency_contacts',
        {'isPrimary': 1},
        where: 'id = ?',
        whereArgs: [contactId],
      );
    });
  }

  Future<void> deleteContact(String id) async {
    final db = await database;
    await db.delete(
      'emergency_contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== SOS ALERTS HISTORY ====================

  Future<List<SosAlert>> getSosAlerts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sos_alerts',
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => SosAlert.fromMap(m)).toList();
  }

  Future<void> insertSosAlert(SosAlert alert) async {
    final db = await database;
    await db.insert(
      'sos_alerts',
      alert.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSosAlert(SosAlert alert) async {
    final db = await database;
    await db.update(
      'sos_alerts',
      alert.toMap(),
      where: 'id = ?',
      whereArgs: [alert.id],
    );
  }

  Future<void> clearSosAlerts() async {
    final db = await database;
    await db.delete('sos_alerts');
  }

  // ==================== SETTINGS KEY-VALUE ====================

  Future<String?> getSetting(String key, {String? defaultValue}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return defaultValue;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
