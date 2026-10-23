import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:emergency_sos/models/emergency_card.dart';
import 'package:emergency_sos/models/emergency_contact.dart';
import 'package:emergency_sos/models/sos_alert.dart';
import 'package:emergency_sos/services/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper SQLite Integration Tests', () {
    late Database db;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      // Run schema migrations on in-memory DB
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
      await db.execute('''
        CREATE TABLE app_settings (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');

      DatabaseHelper.setMockDatabase(db);
    });

    tearDown(() async {
      await db.close();
      DatabaseHelper.setMockDatabase(null);
    });

    test('EmergencyCard CRUD operations in database', () async {
      final helper = DatabaseHelper.instance;

      // Initially empty
      final initial = await helper.getEmergencyCard();
      expect(initial, isNull);

      // Save card
      final card = EmergencyCard(
        id: 'user_1',
        fullName: 'Jane Foster',
        bloodGroup: 'A+',
        medicalConditions: 'Asthma',
        allergies: 'Penicillin',
      );
      await helper.saveEmergencyCard(card);

      final retrieved = await helper.getEmergencyCard();
      expect(retrieved, isNotNull);
      expect(retrieved!.fullName, 'Jane Foster');
      expect(retrieved.bloodGroup, 'A+');
      expect(retrieved.medicalConditions, 'Asthma');

      // Update card
      final updated = card.copyWith(medicalConditions: 'Asthma, Allergy to Pollen');
      await helper.saveEmergencyCard(updated);
      final retrieved2 = await helper.getEmergencyCard();
      expect(retrieved2!.medicalConditions, 'Asthma, Allergy to Pollen');

      // Delete card
      await helper.deleteEmergencyCard();
      final retrieved3 = await helper.getEmergencyCard();
      expect(retrieved3, isNull);
    });

    test('Emergency Contacts CRUD and primary exclusivity', () async {
      final helper = DatabaseHelper.instance;

      final contact1 = EmergencyContact(
        id: 'c1',
        name: 'Alice',
        phone: '+1 555-0101',
        relationship: 'Mom',
        isPrimary: true,
      );
      final contact2 = EmergencyContact(
        id: 'c2',
        name: 'Bob',
        phone: '+1 555-0102',
        relationship: 'Brother',
        isPrimary: false,
      );

      await helper.insertContact(contact1);
      await helper.insertContact(contact2);

      var contacts = await helper.getContacts();
      expect(contacts.length, 2);

      var primary = await helper.getPrimaryContact();
      expect(primary?.id, 'c1');

      // Make contact2 primary, verifying contact1 is automatically demoted
      await helper.setPrimaryContact('c2');
      primary = await helper.getPrimaryContact();
      expect(primary?.id, 'c2');

      contacts = await helper.getContacts();
      final c1Restored = contacts.firstWhere((c) => c.id == 'c1');
      expect(c1Restored.isPrimary, isFalse);

      // Delete contact
      await helper.deleteContact('c1');
      contacts = await helper.getContacts();
      expect(contacts.length, 1);
      expect(contacts.first.id, 'c2');
    });

    test('SOS Alerts logging and status updates', () async {
      final helper = DatabaseHelper.instance;

      final alert = SosAlert(
        id: 'alert_1',
        userName: 'Test User',
        message: 'HELP!',
        latitude: 37.7749,
        longitude: -122.4194,
        recipientPhones: ['+15550101'],
        status: AlertStatus.pending,
      );

      await helper.insertSosAlert(alert);
      var alerts = await helper.getSosAlerts();
      expect(alerts.length, 1);
      expect(alerts.first.status, AlertStatus.pending);

      // Update status to sent
      final updated = alert.copyWith(
        status: AlertStatus.sent,
        statusMessage: 'Dispatched successfully',
      );
      await helper.updateSosAlert(updated);

      alerts = await helper.getSosAlerts();
      expect(alerts.first.status, AlertStatus.sent);
      expect(alerts.first.statusMessage, 'Dispatched successfully');

      // Clear alerts
      await helper.clearSosAlerts();
      alerts = await helper.getSosAlerts();
      expect(alerts.isEmpty, isTrue);
    });

    test('AppSettings key-value storage', () async {
      final helper = DatabaseHelper.instance;

      expect(await helper.getSetting('countdown_seconds', defaultValue: '5'), '5');

      await helper.setSetting('countdown_seconds', '10');
      expect(await helper.getSetting('countdown_seconds'), '10');
    });
  });
}
