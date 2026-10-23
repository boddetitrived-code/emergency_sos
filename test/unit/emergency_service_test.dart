import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:emergency_sos/models/emergency_card.dart';
import 'package:emergency_sos/models/emergency_contact.dart';
import 'package:emergency_sos/models/sos_alert.dart';
import 'package:emergency_sos/services/database_helper.dart';
import 'package:emergency_sos/services/emergency_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('EmergencyService SOS Dispatch Tests', () {
    late Database db;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
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
      EmergencyService.instance.resetState();
    });

    tearDown(() async {
      await db.close();
      DatabaseHelper.setMockDatabase(null);
      EmergencyService.instance.resetState();
    });

    test('SOS alert requires recipients and records failure if no contacts exist', () async {
      final card = EmergencyCard(fullName: 'John Doe', bloodGroup: 'O+');
      final result = await EmergencyService.instance.triggerSosAlert(
        card: card,
        contacts: [], // No contacts
      );

      expect(result.success, isFalse);
      expect(result.alert.status, AlertStatus.failed);
      expect(result.message, contains('No emergency contacts'));
    });

    test('Test alert is explicitly marked as non-emergency test', () async {
      final card = EmergencyCard(
        fullName: 'Jane Doe',
        bloodGroup: 'B+',
        medicalConditions: 'Asthma',
      );
      final contact = EmergencyContact(
        id: 'c1',
        name: 'Bob',
        phone: '+15550100',
        isSosRecipient: true,
      );

      final result = await EmergencyService.instance.triggerSosAlert(
        card: card,
        contacts: [contact],
        isTest: true,
      );

      expect(result.alert.isTest, isTrue);
      expect(result.alert.message, contains('[TEST ALERT - NO EMERGENCY]'));
      expect(result.alert.message, contains('No actual emergency response is required'));
    });

    test('Real SOS alert message includes patient name and medical details', () async {
      EmergencyService.instance.resetState();
      final card = EmergencyCard(
        fullName: 'David Miller',
        bloodGroup: 'A-',
        medicalConditions: 'Type 1 Diabetes',
        allergies: 'Penicillin',
      );
      final contact = EmergencyContact(
        id: 'c1',
        name: 'Doctor Who',
        phone: '+15550100',
        isSosRecipient: true,
      );

      final result = await EmergencyService.instance.triggerSosAlert(
        card: card,
        contacts: [contact],
        isTest: false,
      );

      expect(result.alert.isTest, isFalse);
      expect(result.alert.message, contains('EMERGENCY SOS ALERT!'));
      expect(result.alert.message, contains('David Miller'));
      expect(result.alert.message, contains('Blood Group: A-'));
      expect(result.alert.message, contains('Conditions: Type 1 Diabetes'));
      expect(result.alert.message, contains('Allergies: Penicillin'));
    });

    test('Duplicate tap prevention during rapid requests', () async {
      final card = EmergencyCard(fullName: 'Sarah', bloodGroup: 'O-');
      final contact = EmergencyContact(
        id: 'c1',
        name: 'Tom',
        phone: '+15550199',
        isSosRecipient: true,
      );

      // Trigger first alert
      final firstFuture = EmergencyService.instance.triggerSosAlert(
        card: card,
        contacts: [contact],
        isTest: true,
      );

      // Trigger second alert immediately during cooldown
      final secondResult = await EmergencyService.instance.triggerSosAlert(
        card: card,
        contacts: [contact],
        isTest: true,
      );

      await firstFuture;

      // The second call should either be duplicate prevented or cooldown active
      expect(secondResult.success, isFalse);
      expect(secondResult.alert.status, AlertStatus.cancelled);
    });
  });
}
