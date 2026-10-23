import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:emergency_sos/main.dart';
import 'package:emergency_sos/models/emergency_card.dart';
import 'package:emergency_sos/services/database_helper.dart';
import 'package:emergency_sos/services/emergency_service.dart';
import 'package:emergency_sos/state/emergency_state.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('HomeScreen & SOS Widget Smoke Tests', () {
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
      EmergencyState.instance.resetForTest();
      await EmergencyState.instance.initialize(force: true);
    });

    tearDown(() async {
      await db.close();
      DatabaseHelper.setMockDatabase(null);
      EmergencyState.instance.resetForTest();
    });

    testWidgets('App renders Home Screen with SOS button and Quick Actions',
        (WidgetTester tester) async {
      await tester.pumpWidget(const EmergencySosApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Title
      expect(find.text('EMERGENCY SOS'), findsOneWidget);

      // Verify SOS Button
      expect(find.text('SOS'), findsOneWidget);
      expect(find.text('PRESS FOR HELP'), findsOneWidget);

      // Verify Quick Actions
      expect(find.text('Call Contact'), findsOneWidget);
      expect(find.text('Send SOS'), findsOneWidget);
      expect(find.text('Share Location'), findsOneWidget);
      expect(find.text('Medical Card'), findsOneWidget);

      // Verify Bottom Navigation Bar Destinations
      expect(find.text('SOS Home'), findsOneWidget);
      expect(find.text('Info Card'), findsOneWidget);
      expect(find.text('Contacts'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('Tapping SOS opens countdown screen and CANCEL SOS closes it',
        (WidgetTester tester) async {
      await tester.pumpWidget(const EmergencySosApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap SOS Button
      await tester.tap(find.text('SOS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify countdown screen is displayed
      expect(find.text('SOS ACTIVATION SEQUENCE'), findsOneWidget);
      expect(find.text('CANCEL SOS'), findsOneWidget);
      expect(find.text('SEND IMMEDIATELY'), findsOneWidget);

      // Tap CANCEL SOS
      await tester.tap(find.text('CANCEL SOS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify returned to home screen
      expect(find.text('EMERGENCY SOS'), findsOneWidget);
      expect(find.text('SOS ACTIVATION SEQUENCE'), findsNothing);
    });

    testWidgets('Switching to Info Card tab renders emergency card view',
        (WidgetTester tester) async {
      // Save a sample card in state
      await EmergencyState.instance.saveCard(EmergencyCard(
        fullName: 'Jane Miller',
        bloodGroup: 'O+',
        medicalConditions: 'Asthma',
      ));

      await tester.pumpWidget(const EmergencySosApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Info Card navigation destination
      await tester.tap(find.text('Info Card'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Info Card is rendered with user details
      expect(find.text('Emergency Information Card'), findsOneWidget);
      expect(find.text('Jane Miller'), findsOneWidget);
      expect(find.text('O+'), findsWidgets);
      expect(find.text('Medical Conditions'), findsOneWidget);
      expect(find.text('Asthma'), findsOneWidget);
    });
  });
}
