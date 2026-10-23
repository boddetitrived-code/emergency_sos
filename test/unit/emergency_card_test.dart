import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_sos/models/emergency_card.dart';

void main() {
  group('EmergencyCard Model Tests', () {
    test('Empty card check', () {
      final card = EmergencyCard.empty();
      expect(card.isEmpty, isTrue);
      expect(card.isNotEmpty, isFalse);
      expect(card.fullName, isEmpty);
      expect(card.bloodGroup, 'Unknown');
    });

    test('Age calculation from Date of Birth', () {
      final dob = DateTime(DateTime.now().year - 30, 1, 1);
      final card = EmergencyCard(
        fullName: 'Jane Doe',
        bloodGroup: 'O+',
        dateOfBirth: dob,
      );

      expect(card.age, isNotNull);
      expect(card.age, greaterThanOrEqualTo(29));
      expect(card.age, lessThanOrEqualTo(30));
    });

    test('Serialization toMap and fromMap roundtrip', () {
      final dob = DateTime(1990, 5, 15);
      final original = EmergencyCard(
        id: 'user_123',
        fullName: 'Alex Smith',
        photoPath: '/path/to/alex.jpg',
        bloodGroup: 'B-',
        dateOfBirth: dob,
        medicalConditions: 'Type 1 Diabetes, Asthma',
        allergies: 'Penicillin, Peanuts',
        currentMedications: 'Insulin, Albuterol',
        emergencyContactName: 'Sarah Smith',
        emergencyContactPhone: '+1-555-0199',
        additionalNotes: 'Carries EpiPen in backpack',
        showOnLockScreen: true,
      );

      final map = original.toMap();
      final restored = EmergencyCard.fromMap(map);

      expect(restored.id, 'user_123');
      expect(restored.fullName, 'Alex Smith');
      expect(restored.photoPath, '/path/to/alex.jpg');
      expect(restored.bloodGroup, 'B-');
      expect(restored.dateOfBirth?.year, 1990);
      expect(restored.dateOfBirth?.month, 5);
      expect(restored.medicalConditions, 'Type 1 Diabetes, Asthma');
      expect(restored.allergies, 'Penicillin, Peanuts');
      expect(restored.currentMedications, 'Insulin, Albuterol');
      expect(restored.emergencyContactName, 'Sarah Smith');
      expect(restored.emergencyContactPhone, '+1-555-0199');
      expect(restored.additionalNotes, 'Carries EpiPen in backpack');
      expect(restored.showOnLockScreen, isTrue);
    });

    test('Shareable summary contains all critical information', () {
      final card = EmergencyCard(
        fullName: 'Michael Scott',
        bloodGroup: 'AB+',
        medicalConditions: 'Hypertension',
        allergies: 'Sulfa drugs',
        currentMedications: 'Lisinopril',
        emergencyContactName: 'Dwight Schrute',
        emergencyContactPhone: '+1 555-9876',
        additionalNotes: 'Do not administer aspirin',
      );

      final summary = card.toShareableSummary();

      expect(summary, contains('EMERGENCY MEDICAL CARD'));
      expect(summary, contains('Michael Scott'));
      expect(summary, contains('AB+'));
      expect(summary, contains('Hypertension'));
      expect(summary, contains('Sulfa drugs'));
      expect(summary, contains('Lisinopril'));
      expect(summary, contains('Dwight Schrute'));
      expect(summary, contains('+1 555-9876'));
      expect(summary, contains('Do not administer aspirin'));
    });
  });
}
