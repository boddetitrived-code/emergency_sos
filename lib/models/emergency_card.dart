class EmergencyCard {
  final String id;
  final String fullName;
  final String? photoPath;
  final String bloodGroup; // A+, A-, B+, B-, AB+, AB-, O+, O-, Unknown
  final DateTime? dateOfBirth;
  final String medicalConditions;
  final String allergies;
  final String currentMedications;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String additionalNotes;
  final bool showOnLockScreen;
  final DateTime updatedAt;

  EmergencyCard({
    this.id = 'default_user',
    required this.fullName,
    this.photoPath,
    this.bloodGroup = 'Unknown',
    this.dateOfBirth,
    this.medicalConditions = '',
    this.allergies = '',
    this.currentMedications = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.additionalNotes = '',
    this.showOnLockScreen = true,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  bool get isEmpty => fullName.trim().isEmpty;
  bool get isNotEmpty => !isEmpty;

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age >= 0 ? age : null;
  }

  EmergencyCard copyWith({
    String? id,
    String? fullName,
    String? photoPath,
    String? bloodGroup,
    DateTime? dateOfBirth,
    String? medicalConditions,
    String? allergies,
    String? currentMedications,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? additionalNotes,
    bool? showOnLockScreen,
    DateTime? updatedAt,
  }) {
    return EmergencyCard(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      photoPath: photoPath ?? this.photoPath,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      allergies: allergies ?? this.allergies,
      currentMedications: currentMedications ?? this.currentMedications,
      emergencyContactName:
          emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      showOnLockScreen: showOnLockScreen ?? this.showOnLockScreen,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'photoPath': photoPath,
      'bloodGroup': bloodGroup,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'medicalConditions': medicalConditions,
      'allergies': allergies,
      'currentMedications': currentMedications,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'additionalNotes': additionalNotes,
      'showOnLockScreen': showOnLockScreen ? 1 : 0,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory EmergencyCard.fromMap(Map<String, dynamic> map) {
    return EmergencyCard(
      id: map['id'] as String? ?? 'default_user',
      fullName: map['fullName'] as String? ?? '',
      photoPath: map['photoPath'] as String?,
      bloodGroup: map['bloodGroup'] as String? ?? 'Unknown',
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.tryParse(map['dateOfBirth'] as String)
          : null,
      medicalConditions: map['medicalConditions'] as String? ?? '',
      allergies: map['allergies'] as String? ?? '',
      currentMedications: map['currentMedications'] as String? ?? '',
      emergencyContactName: map['emergencyContactName'] as String? ?? '',
      emergencyContactPhone: map['emergencyContactPhone'] as String? ?? '',
      additionalNotes: map['additionalNotes'] as String? ?? '',
      showOnLockScreen: (map['showOnLockScreen'] as int? ?? 1) == 1,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory EmergencyCard.empty() {
    return EmergencyCard(
      fullName: '',
      bloodGroup: 'Unknown',
    );
  }

  /// Formatted text representation for sharing with trusted people or emergency responders
  String toShareableSummary() {
    final buffer = StringBuffer();
    buffer.writeln('📋 EMERGENCY MEDICAL CARD');
    buffer.writeln('===========================');
    buffer.writeln('👤 Name: $fullName');
    if (age != null) {
      buffer.writeln('🎂 Age: $age yrs');
    }
    buffer.writeln('🩸 Blood Group: $bloodGroup');
    if (medicalConditions.trim().isNotEmpty) {
      buffer.writeln('⚠️ Conditions: $medicalConditions');
    }
    if (allergies.trim().isNotEmpty) {
      buffer.writeln('🚫 Allergies: $allergies');
    }
    if (currentMedications.trim().isNotEmpty) {
      buffer.writeln('💊 Medications: $currentMedications');
    }
    if (emergencyContactName.trim().isNotEmpty ||
        emergencyContactPhone.trim().isNotEmpty) {
      buffer.writeln(
          '📞 Emergency Contact: $emergencyContactName ($emergencyContactPhone)');
    }
    if (additionalNotes.trim().isNotEmpty) {
      buffer.writeln('📝 Notes: $additionalNotes');
    }
    buffer.writeln('===========================');
    buffer.writeln('Generated via Emergency Info & SOS App');
    return buffer.toString();
  }
}
