import 'dart:convert';

enum AlertStatus {
  pending,
  sent,
  failed,
  cancelled,
}

class SosAlert {
  final String id;
  final DateTime timestamp;
  final String userName;
  final String message;
  final double? latitude;
  final double? longitude;
  final bool isLocationOutdated;
  final String? googleMapsUrl;
  final List<String> recipientPhones;
  final AlertStatus status;
  final String? statusMessage;
  final bool isTest;

  SosAlert({
    required this.id,
    DateTime? timestamp,
    required this.userName,
    required this.message,
    this.latitude,
    this.longitude,
    this.isLocationOutdated = false,
    this.googleMapsUrl,
    required this.recipientPhones,
    this.status = AlertStatus.pending,
    this.statusMessage,
    this.isTest = false,
  }) : timestamp = timestamp ?? DateTime.now();

  SosAlert copyWith({
    String? id,
    DateTime? timestamp,
    String? userName,
    String? message,
    double? latitude,
    double? longitude,
    bool? isLocationOutdated,
    String? googleMapsUrl,
    List<String>? recipientPhones,
    AlertStatus? status,
    String? statusMessage,
    bool? isTest,
  }) {
    return SosAlert(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      userName: userName ?? this.userName,
      message: message ?? this.message,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLocationOutdated: isLocationOutdated ?? this.isLocationOutdated,
      googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
      recipientPhones: recipientPhones ?? this.recipientPhones,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      isTest: isTest ?? this.isTest,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'userName': userName,
      'message': message,
      'latitude': latitude,
      'longitude': longitude,
      'isLocationOutdated': isLocationOutdated ? 1 : 0,
      'googleMapsUrl': googleMapsUrl,
      'recipientPhones': jsonEncode(recipientPhones),
      'status': status.name,
      'statusMessage': statusMessage,
      'isTest': isTest ? 1 : 0,
    };
  }

  factory SosAlert.fromMap(Map<String, dynamic> map) {
    List<String> recipients = [];
    if (map['recipientPhones'] != null) {
      try {
        final decoded = jsonDecode(map['recipientPhones'] as String);
        if (decoded is List) {
          recipients = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    AlertStatus alertStatus = AlertStatus.pending;
    if (map['status'] != null) {
      alertStatus = AlertStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AlertStatus.pending,
      );
    }

    return SosAlert(
      id: map['id'] as String,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      userName: map['userName'] as String? ?? 'User',
      message: map['message'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      isLocationOutdated: (map['isLocationOutdated'] as int? ?? 0) == 1,
      googleMapsUrl: map['googleMapsUrl'] as String?,
      recipientPhones: recipients,
      status: alertStatus,
      statusMessage: map['statusMessage'] as String?,
      isTest: (map['isTest'] as int? ?? 0) == 1,
    );
  }
}
