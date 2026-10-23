import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/emergency_card.dart';
import '../models/emergency_contact.dart';
import '../models/live_tracking_session.dart';
import '../models/sos_alert.dart';
import '../services/database_helper.dart';
import '../services/emergency_service.dart';
import '../services/location_service.dart';

class EmergencyState extends ChangeNotifier {
  static final EmergencyState instance = EmergencyState._internal();
  EmergencyState._internal();

  EmergencyCard _card = EmergencyCard.empty();
  List<EmergencyContact> _contacts = [];
  List<SosAlert> _alerts = [];
  LocationResult? _lastLocationResult;
  bool _isLoading = true;
  bool _isLocating = false;
  bool _isInitialized = false;
  String? _errorMessage;

  // Settings
  int _countdownSeconds = 5;
  int _trackingDurationMinutes = 30;

  StreamSubscription<LiveTrackingSession>? _trackingSub;

  // Getters
  EmergencyCard get card => _card;
  List<EmergencyContact> get contacts => List.unmodifiable(_contacts);
  List<SosAlert> get alerts => List.unmodifiable(_alerts);
  LocationResult? get lastLocationResult => _lastLocationResult;
  bool get isLoading => _isLoading;
  bool get isLocating => _isLocating;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  int get countdownSeconds => _countdownSeconds;
  int get trackingDurationMinutes => _trackingDurationMinutes;

  EmergencyContact? get primaryContact {
    if (_contacts.isEmpty) return null;
    try {
      return _contacts.firstWhere((c) => c.isPrimary);
    } catch (_) {
      return _contacts.first;
    }
  }

  List<EmergencyContact> get sosRecipients =>
      _contacts.where((c) => c.isSosRecipient).toList();

  LiveTrackingSession get liveTrackingSession =>
      LocationService.instance.currentSession;

  /// Initialize state from persistent database
  Future<void> initialize({bool force = false}) async {
    if (_isInitialized && !force) {
      _isLoading = false;
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Load card
      final savedCard = await DatabaseHelper.instance.getEmergencyCard();
      if (savedCard != null) {
        _card = savedCard;
      }

      // 2. Load contacts
      _contacts = await DatabaseHelper.instance.getContacts();

      // 3. Load alerts history
      _alerts = await DatabaseHelper.instance.getSosAlerts();

      // 4. Load settings
      final countdownStr =
          await DatabaseHelper.instance.getSetting('countdown_seconds');
      if (countdownStr != null) {
        _countdownSeconds = int.tryParse(countdownStr) ?? 5;
      }

      final durationStr = await DatabaseHelper.instance
          .getSetting('tracking_duration_minutes');
      if (durationStr != null) {
        _trackingDurationMinutes = int.tryParse(durationStr) ?? 30;
      }

      // 5. Listen to live tracking changes
      _trackingSub?.cancel();
      _trackingSub = LocationService.instance.sessionStream.listen((session) {
        notifyListeners();
      });

      _isInitialized = true;

      // 6. Fetch initial location in background
      refreshLocation(showLoading: false);
    } catch (e) {
      _errorMessage = 'Failed to load emergency data: $e';
      debugPrint('EmergencyState: init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @visibleForTesting
  void resetForTest() {
    _card = EmergencyCard.empty();
    _contacts = [];
    _alerts = [];
    _lastLocationResult = null;
    _isLoading = false;
    _isLocating = false;
    _isInitialized = false;
  }

  // ==================== EMERGENCY CARD ACTIONS ====================

  Future<void> saveCard(EmergencyCard newCard) async {
    _card = newCard;
    await DatabaseHelper.instance.saveEmergencyCard(newCard);
    notifyListeners();
  }

  Future<void> deleteCard() async {
    _card = EmergencyCard.empty();
    await DatabaseHelper.instance.deleteEmergencyCard();
    notifyListeners();
  }

  // ==================== CONTACTS ACTIONS ====================

  Future<void> addContact(EmergencyContact contact) async {
    await DatabaseHelper.instance.insertContact(contact);
    _contacts = await DatabaseHelper.instance.getContacts();
    notifyListeners();
  }

  Future<void> updateContact(EmergencyContact contact) async {
    await DatabaseHelper.instance.updateContact(contact);
    _contacts = await DatabaseHelper.instance.getContacts();
    notifyListeners();
  }

  Future<void> deleteContact(String id) async {
    await DatabaseHelper.instance.deleteContact(id);
    _contacts = await DatabaseHelper.instance.getContacts();
    notifyListeners();
  }

  Future<void> setPrimaryContact(String id) async {
    await DatabaseHelper.instance.setPrimaryContact(id);
    _contacts = await DatabaseHelper.instance.getContacts();
    notifyListeners();
  }

  Future<void> toggleSosRecipient(String id, bool isRecipient) async {
    final contactIndex = _contacts.indexWhere((c) => c.id == id);
    if (contactIndex != -1) {
      final updated =
          _contacts[contactIndex].copyWith(isSosRecipient: isRecipient);
      await updateContact(updated);
    }
  }

  // ==================== SOS ALERTS ACTIONS ====================

  Future<SosDispatchResult> triggerSosAlert({
    bool isTest = false,
    String? customMessage,
  }) async {
    final result = await EmergencyService.instance.triggerSosAlert(
      card: _card,
      contacts: _contacts,
      isTest: isTest,
      customMessage: customMessage,
    );

    // Refresh alerts list
    _alerts = await DatabaseHelper.instance.getSosAlerts();
    notifyListeners();
    return result;
  }

  Future<void> clearAlertsHistory() async {
    await DatabaseHelper.instance.clearSosAlerts();
    _alerts = [];
    notifyListeners();
  }

  // ==================== LOCATION ACTIONS ====================

  Future<LocationResult> refreshLocation({bool showLoading = true}) async {
    if (showLoading) {
      _isLocating = true;
      notifyListeners();
    }

    try {
      _lastLocationResult =
          await LocationService.instance.getCurrentLocation();
    } catch (e) {
      _lastLocationResult =
          LocationResult.failure(errorMessage: e.toString());
    } finally {
      if (showLoading) {
        _isLocating = false;
      }
      notifyListeners();
    }

    return _lastLocationResult!;
  }

  Future<bool> startLiveTracking({Duration? duration}) async {
    final chosenDuration =
        duration ?? Duration(minutes: _trackingDurationMinutes);
    final success = await LocationService.instance.startLiveTracking(
      duration: chosenDuration,
      onUpdate: (loc) {
        _lastLocationResult = loc;
        notifyListeners();
      },
      onExpired: () {
        notifyListeners();
      },
    );
    notifyListeners();
    return success;
  }

  void stopLiveTracking() {
    LocationService.instance.stopLiveTracking();
    notifyListeners();
  }

  // ==================== SETTINGS ACTIONS ====================

  Future<void> updateCountdownSeconds(int seconds) async {
    _countdownSeconds = seconds;
    await DatabaseHelper.instance
        .setSetting('countdown_seconds', seconds.toString());
    notifyListeners();
  }

  Future<void> updateTrackingDurationMinutes(int minutes) async {
    _trackingDurationMinutes = minutes;
    await DatabaseHelper.instance
        .setSetting('tracking_duration_minutes', minutes.toString());
    notifyListeners();
  }

  @override
  void dispose() {
    _trackingSub?.cancel();
    super.dispose();
  }
}
