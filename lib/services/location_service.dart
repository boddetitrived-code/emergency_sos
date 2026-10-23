import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/live_tracking_session.dart';

class LocationResult {
  final bool isSuccess;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final DateTime timestamp;
  final bool isLastKnown; // If true, location is potentially outdated
  final String? errorMessage;

  LocationResult.success({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    DateTime? timestamp,
    this.isLastKnown = false,
  })  : isSuccess = true,
        timestamp = timestamp ?? DateTime.now(),
        errorMessage = null;

  LocationResult.failure({
    required this.errorMessage,
    this.latitude,
    this.longitude,
    DateTime? timestamp,
  })  : isSuccess = false,
        accuracy = null,
        isLastKnown = false,
        timestamp = timestamp ?? DateTime.now();

  String? get googleMapsUrl {
    if (latitude == null || longitude == null) return null;
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }

  String get formattedCoordinates {
    if (latitude == null || longitude == null) return 'Unavailable';
    return '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}';
  }
}

class LocationService {
  static final LocationService instance = LocationService._internal();
  LocationService._internal();

  Timer? _trackingTimer;
  LiveTrackingSession _currentSession = LiveTrackingSession.initial;
  final _sessionStreamController =
      StreamController<LiveTrackingSession>.broadcast();

  Stream<LiveTrackingSession> get sessionStream =>
      _sessionStreamController.stream;
  LiveTrackingSession get currentSession => _currentSession;

  /// Check whether GPS service is enabled and permission is granted.
  Future<bool> checkPermission({bool request = true}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && request) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Retrieve current location with automatic fallback to last known location.
  Future<LocationResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Try last known as fallback
        return await _tryFallbackLocation(
          'Location services (GPS) are disabled on your device. Please turn on GPS.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return await _tryFallbackLocation(
            'Location permission was denied. Cannot determine GPS coordinates.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return await _tryFallbackLocation(
          'Location permissions are permanently denied. Please enable them in app settings.',
        );
      }

      // Try fetching current GPS position with timeout
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return LocationResult.success(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
        isLastKnown: false,
      );
    } catch (e) {
      debugPrint('LocationService: Error getting current location: $e');
      return await _tryFallbackLocation(
        'Could not obtain current GPS fix: ${e.toString()}',
      );
    }
  }

  /// Fallback to last known position if current GPS cannot be obtained
  Future<LocationResult> _tryFallbackLocation(String primaryReason) async {
    try {
      final Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return LocationResult.success(
          latitude: lastKnown.latitude,
          longitude: lastKnown.longitude,
          accuracy: lastKnown.accuracy,
          timestamp: lastKnown.timestamp,
          isLastKnown: true, // Clearly marked as potentially outdated
        );
      }
    } catch (e) {
      debugPrint('LocationService: Fallback error: $e');
    }

    return LocationResult.failure(
      errorMessage:
          '$primaryReason No cached or last known location is available.',
    );
  }

  // ==================== LIVE TRACKING ====================

  /// Start temporary live location sharing
  Future<bool> startLiveTracking({
    required Duration duration,
    required void Function(LocationResult result) onUpdate,
    required VoidCallback onExpired,
  }) async {
    stopLiveTracking();

    final hasPermission = await checkPermission(request: true);
    if (!hasPermission) {
      return false;
    }

    final now = DateTime.now();
    final expiresAt = now.add(duration);

    _currentSession = LiveTrackingSession(
      isActive: true,
      startedAt: now,
      duration: duration,
      expiresAt: expiresAt,
    );
    _sessionStreamController.add(_currentSession);

    // Initial fix
    final initialLoc = await getCurrentLocation();
    if (initialLoc.isSuccess) {
      _currentSession = _currentSession.copyWith(
        lastLatitude: initialLoc.latitude,
        lastLongitude: initialLoc.longitude,
        lastUpdatedAt: DateTime.now(),
      );
      _sessionStreamController.add(_currentSession);
      onUpdate(initialLoc);
    }

    // Periodic updates every 30 seconds
    _trackingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_currentSession.isExpired || !_currentSession.isActive) {
        stopLiveTracking();
        onExpired();
        return;
      }

      final loc = await getCurrentLocation();
      if (loc.isSuccess) {
        _currentSession = _currentSession.copyWith(
          lastLatitude: loc.latitude,
          lastLongitude: loc.longitude,
          lastUpdatedAt: DateTime.now(),
        );
        _sessionStreamController.add(_currentSession);
        onUpdate(loc);
      }
    });

    return true;
  }

  /// Stop live location sharing
  void stopLiveTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
    if (_currentSession.isActive) {
      _currentSession = _currentSession.copyWith(isActive: false);
      _sessionStreamController.add(_currentSession);
    }
  }

  void dispose() {
    _trackingTimer?.cancel();
    _sessionStreamController.close();
  }
}
