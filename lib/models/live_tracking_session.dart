class LiveTrackingSession {
  final bool isActive;
  final DateTime? startedAt;
  final Duration duration;
  final DateTime? expiresAt;
  final double? lastLatitude;
  final double? lastLongitude;
  final DateTime? lastUpdatedAt;

  const LiveTrackingSession({
    this.isActive = false,
    this.startedAt,
    this.duration = const Duration(minutes: 30),
    this.expiresAt,
    this.lastLatitude,
    this.lastLongitude,
    this.lastUpdatedAt,
  });

  bool get isExpired {
    if (!isActive || expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  Duration get remainingDuration {
    if (!isActive || expiresAt == null) return Duration.zero;
    final diff = expiresAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  LiveTrackingSession copyWith({
    bool? isActive,
    DateTime? startedAt,
    Duration? duration,
    DateTime? expiresAt,
    double? lastLatitude,
    double? lastLongitude,
    DateTime? lastUpdatedAt,
  }) {
    return LiveTrackingSession(
      isActive: isActive ?? this.isActive,
      startedAt: startedAt ?? this.startedAt,
      duration: duration ?? this.duration,
      expiresAt: expiresAt ?? this.expiresAt,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  static const LiveTrackingSession initial = LiveTrackingSession();
}
