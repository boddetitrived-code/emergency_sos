import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_sos/models/emergency_contact.dart';

void main() {
  group('EmergencyContact Model Tests', () {
    test('Valid phone numbers pass validation', () {
      final validPhones = [
        '+1 555-123-4567',
        '+919876543210',
        '(555) 000-1122',
        '1234567890',
        '+44 20 7946 0919',
        '555-0199',
      ];

      for (final phone in validPhones) {
        final error = EmergencyContact.validatePhoneNumber(phone);
        expect(error, isNull, reason: '$phone should be valid');
      }
    });

    test('Invalid phone numbers fail validation with message', () {
      final invalidPhones = [
        '',
        '   ',
        '12345', // Too short (< 7 digits)
        'abcdefg', // No digits
        'phone: 1234567', // Invalid characters
        '123456789012345678', // Too long (> 15 digits)
      ];

      for (final phone in invalidPhones) {
        final error = EmergencyContact.validatePhoneNumber(phone);
        expect(error, isNotNull, reason: '$phone should be invalid');
      }
    });

    test('Sanitized phone strips non-numeric characters except +', () {
      final contact = EmergencyContact(
        id: 'c1',
        name: 'Alice',
        phone: '+1 (555) 234-5678',
      );

      expect(contact.sanitizedPhone, '+15552345678');
    });

    test('Serialization toMap and fromMap roundtrip', () {
      final contact = EmergencyContact(
        id: 'contact_abc',
        name: 'Bob Jones',
        phone: '+1 555-8888',
        relationship: 'Spouse',
        isPrimary: true,
        isSosRecipient: true,
      );

      final map = contact.toMap();
      final restored = EmergencyContact.fromMap(map);

      expect(restored.id, 'contact_abc');
      expect(restored.name, 'Bob Jones');
      expect(restored.phone, '+1 555-8888');
      expect(restored.relationship, 'Spouse');
      expect(restored.isPrimary, isTrue);
      expect(restored.isSosRecipient, isTrue);
    });
  });
}
