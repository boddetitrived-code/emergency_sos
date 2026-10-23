class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String relationship; // e.g., Parent, Spouse, Sibling, Friend, Doctor, Other
  final bool isPrimary;
  final bool isSosRecipient;
  final DateTime createdAt;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relationship = 'Contact',
    this.isPrimary = false,
    this.isSosRecipient = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? relationship,
    bool? isPrimary,
    bool? isSosRecipient,
    DateTime? createdAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      isSosRecipient: isSosRecipient ?? this.isSosRecipient,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'isPrimary': isPrimary ? 1 : 0,
      'isSosRecipient': isSosRecipient ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      relationship: map['relationship'] as String? ?? 'Contact',
      isPrimary: (map['isPrimary'] as int? ?? 0) == 1,
      isSosRecipient: (map['isSosRecipient'] as int? ?? 1) == 1,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Validates phone number format
  /// Returns null if valid, or an error string if invalid
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final trimmed = value.trim();
    // Allow leading +, digits, dashes, spaces, and parentheses
    final regex = RegExp(r'^\+?[0-9\s\-()]{7,20}$');
    if (!regex.hasMatch(trimmed)) {
      return 'Enter a valid phone number (at least 7 digits)';
    }
    // Count pure digits
    final digitCount = trimmed.replaceAll(RegExp(r'\D'), '').length;
    if (digitCount < 7 || digitCount > 15) {
      return 'Phone number must contain between 7 and 15 digits';
    }
    return null;
  }

  /// Sanitized phone string suitable for dialing (e.g. +123456789)
  String get sanitizedPhone => phone.replaceAll(RegExp(r'[^0-9+]'), '');
}
