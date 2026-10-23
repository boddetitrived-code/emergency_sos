import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_card.dart';
import '../models/emergency_contact.dart';
import '../models/sos_alert.dart';
import 'database_helper.dart';
import 'location_service.dart';

class SosDispatchResult {
  final bool success;
  final String message;
  final SosAlert alert;
  final bool openedMessenger;

  SosDispatchResult({
    required this.success,
    required this.message,
    required this.alert,
    this.openedMessenger = false,
  });
}

class EmergencyService {
  static final EmergencyService instance = EmergencyService._internal();
  EmergencyService._internal();

  bool _isDispatching = false;
  DateTime? _lastAlertTimestamp;

  bool get isDispatching => _isDispatching;

  @visibleForTesting
  void resetState() {
    _isDispatching = false;
    _lastAlertTimestamp = null;
  }

  // ==================== CALL EMERGENCY CONTACT ====================

  /// Initiates a phone call to the primary contact
  Future<bool> callContact(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) {
      debugPrint('EmergencyService: Invalid phone number for calling');
      return false;
    }

    final Uri telUri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(telUri)) {
        return await launchUrl(telUri);
      } else {
        // Fallback direct launch
        return await launchUrl(telUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('EmergencyService: Error launching phone call: $e');
      return false;
    }
  }

  // ==================== DISPATCH SOS ALERT ====================

  /// Core SOS dispatch logic with debouncing and duplicate prevention
  Future<SosDispatchResult> triggerSosAlert({
    required EmergencyCard card,
    required List<EmergencyContact> contacts,
    bool isTest = false,
    String? customMessage,
  }) async {
    // Prevent duplicate alerts from repeated taps
    if (_isDispatching) {
      return SosDispatchResult(
        success: false,
        message: 'An alert is already being processed. Please wait.',
        alert: SosAlert(
          id: 'duplicate_prevented',
          userName: card.fullName,
          message: 'Duplicate prevented',
          recipientPhones: [],
          status: AlertStatus.cancelled,
        ),
      );
    }

    // Cooldown check (prevent tapping within 3 seconds)
    final now = DateTime.now();
    if (_lastAlertTimestamp != null &&
        now.difference(_lastAlertTimestamp!).inSeconds < 3) {
      return SosDispatchResult(
        success: false,
        message: 'Please wait a moment before sending another alert.',
        alert: SosAlert(
          id: 'cooldown_active',
          userName: card.fullName,
          message: 'Cooldown active',
          recipientPhones: [],
          status: AlertStatus.cancelled,
        ),
      );
    }

    _isDispatching = true;
    _lastAlertTimestamp = now;

    try {
      // 1. Filter active SOS recipients
      final sosRecipients =
          contacts.where((c) => c.isSosRecipient && c.phone.isNotEmpty).toList();

      final recipientPhoneNumbers =
          sosRecipients.map((c) => c.sanitizedPhone).toList();

      // 2. Fetch current GPS location (with fallback to last known)
      final locationResult = await LocationService.instance.getCurrentLocation();

      // 3. Construct structured SOS message
      final timeFormatted =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      final StringBuffer messageBuffer = StringBuffer();
      if (isTest) {
        messageBuffer.writeln('⚠️ [TEST ALERT - NO EMERGENCY]');
        messageBuffer.writeln(
            'This is a TEST of the Emergency SOS system for ${card.fullName.isNotEmpty ? card.fullName : "User"}.');
        messageBuffer.writeln('No actual emergency response is required.');
        messageBuffer.writeln('Time: $timeFormatted');
      } else {
        messageBuffer.writeln('🚨 EMERGENCY SOS ALERT! 🚨');
        messageBuffer.writeln(
            'I need immediate emergency assistance! Name: ${card.fullName.isNotEmpty ? card.fullName : "User"}');
        messageBuffer.writeln('Time: $timeFormatted');
        if (customMessage != null && customMessage.trim().isNotEmpty) {
          messageBuffer.writeln('Message: $customMessage');
        }
      }

      // Location details
      if (locationResult.isSuccess) {
        if (locationResult.isLastKnown) {
          messageBuffer.writeln('📍 Location: ${locationResult.googleMapsUrl}');
          messageBuffer.writeln(
              '⚠️ Note: Real-time GPS unavailable. Location is last-known (potentially outdated).');
        } else {
          messageBuffer.writeln(
              '📍 Real-Time Location: ${locationResult.googleMapsUrl}');
          if (locationResult.accuracy != null) {
            messageBuffer.writeln(
                'Accuracy: ±${locationResult.accuracy!.toStringAsFixed(1)}m');
          }
        }
      } else {
        messageBuffer.writeln(
            '📍 Location: Unavailable (${locationResult.errorMessage ?? "No GPS signal"})');
      }

      // Vital Medical Info
      if (card.bloodGroup.isNotEmpty && card.bloodGroup != 'Unknown') {
        messageBuffer.writeln('🩸 Blood Group: ${card.bloodGroup}');
      }
      if (card.medicalConditions.isNotEmpty) {
        messageBuffer.writeln('⚠️ Conditions: ${card.medicalConditions}');
      }
      if (card.allergies.isNotEmpty) {
        messageBuffer.writeln('🚫 Allergies: ${card.allergies}');
      }

      final String fullMessage = messageBuffer.toString();
      final alertId = 'alert_${DateTime.now().millisecondsSinceEpoch}';

      // 4. Save alert in local SQLite database
      var sosAlert = SosAlert(
        id: alertId,
        timestamp: DateTime.now(),
        userName: card.fullName.isNotEmpty ? card.fullName : 'User',
        message: fullMessage,
        latitude: locationResult.latitude,
        longitude: locationResult.longitude,
        isLocationOutdated: locationResult.isLastKnown,
        googleMapsUrl: locationResult.googleMapsUrl,
        recipientPhones: recipientPhoneNumbers,
        status: AlertStatus.pending,
        statusMessage: 'Preparing alert dispatch...',
        isTest: isTest,
      );

      await DatabaseHelper.instance.insertSosAlert(sosAlert);

      // 5. Check if any recipients exist
      if (recipientPhoneNumbers.isEmpty) {
        sosAlert = sosAlert.copyWith(
          status: AlertStatus.failed,
          statusMessage:
              'No emergency contacts configured to receive SOS alerts.',
        );
        await DatabaseHelper.instance.updateSosAlert(sosAlert);

        return SosDispatchResult(
          success: false,
          message:
              'No emergency contacts selected for SOS alerts. Please add contacts.',
          alert: sosAlert,
        );
      }

      // 6. Deliver via SMS Intent / Messenger
      bool launchedMessenger = false;
      try {
        final smsUri = _buildSmsUri(recipientPhoneNumbers, fullMessage);
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
          launchedMessenger = true;
        } else {
          // Fallback share sheet
          await Share.share(
            fullMessage,
            subject: isTest ? 'SOS Test Alert' : 'EMERGENCY SOS ALERT',
          );
          launchedMessenger = true;
        }
      } catch (e) {
        debugPrint('EmergencyService: Could not launch SMS: $e');
        // Fallback to share sheet
        try {
          await Share.share(
            fullMessage,
            subject: isTest ? 'SOS Test Alert' : 'EMERGENCY SOS ALERT',
          );
          launchedMessenger = true;
        } catch (_) {}
      }

      if (launchedMessenger) {
        sosAlert = sosAlert.copyWith(
          status: AlertStatus.sent,
          statusMessage: isTest
              ? 'Test alert opened in messaging client.'
              : 'SOS alert dispatched to messenger for delivery.',
        );
      } else {
        sosAlert = sosAlert.copyWith(
          status: AlertStatus.failed,
          statusMessage:
              'Could not launch device messaging application or share dialog.',
        );
      }

      await DatabaseHelper.instance.updateSosAlert(sosAlert);

      return SosDispatchResult(
        success: launchedMessenger,
        message: launchedMessenger
            ? (isTest
                ? 'Test alert dispatched successfully.'
                : 'Emergency alert dispatched to contacts!')
            : 'Failed to launch messaging app. You can copy the alert or call directly.',
        alert: sosAlert,
        openedMessenger: launchedMessenger,
      );
    } catch (e) {
      debugPrint('EmergencyService: Error during SOS dispatch: $e');
      return SosDispatchResult(
        success: false,
        message: 'Error triggering SOS: ${e.toString()}',
        alert: SosAlert(
          id: 'error_${DateTime.now().millisecondsSinceEpoch}',
          userName: card.fullName,
          message: 'Error: $e',
          recipientPhones: [],
          status: AlertStatus.failed,
          statusMessage: e.toString(),
          isTest: isTest,
        ),
      );
    } finally {
      _isDispatching = false;
    }
  }

  /// Construct platform-compliant SMS URI
  Uri _buildSmsUri(List<String> recipients, String message) {
    final String addresses = recipients.join(';');
    return Uri(
      scheme: 'sms',
      path: addresses,
      queryParameters: <String, String>{
        'body': message,
      },
    );
  }

  // ==================== SHARE EMERGENCY CARD ====================

  /// Share Emergency Card details via system share sheet
  Future<void> shareEmergencyCard(EmergencyCard card) async {
    final text = card.toShareableSummary();
    await Share.share(
      text,
      subject: 'Emergency Medical Information - ${card.fullName}',
    );
  }

  // ==================== SHARE CURRENT LOCATION ====================

  /// Quick share of current GPS location
  Future<bool> shareCurrentLocation({EmergencyCard? card}) async {
    final loc = await LocationService.instance.getCurrentLocation();
    if (!loc.isSuccess || loc.googleMapsUrl == null) {
      return false;
    }

    final name = (card != null && card.fullName.isNotEmpty)
        ? card.fullName
        : 'My';
    final timeStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    String text;
    if (loc.isLastKnown) {
      text =
          '$name current location (last-known snapshot as of $timeStr):\n${loc.googleMapsUrl}\n⚠️ Note: Live GPS is currently weak/unavailable.';
    } else {
      text =
          '$name real-time GPS location (as of $timeStr):\n${loc.googleMapsUrl}';
    }

    await Share.share(
      text,
      subject: 'Location Share - $name',
    );
    return true;
  }
}
