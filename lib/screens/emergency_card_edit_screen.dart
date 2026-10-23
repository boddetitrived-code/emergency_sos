import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/emergency_card.dart';
import '../models/emergency_contact.dart';
import '../state/emergency_state.dart';
import '../utils/app_theme.dart';

class EmergencyCardEditScreen extends StatefulWidget {
  final EmergencyCard? initialCard;

  const EmergencyCardEditScreen({super.key, this.initialCard});

  @override
  State<EmergencyCardEditScreen> createState() =>
      _EmergencyCardEditScreenState();
}

class _EmergencyCardEditScreenState extends State<EmergencyCardEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _conditionsController;
  late TextEditingController _allergiesController;
  late TextEditingController _medicationsController;
  late TextEditingController _contactNameController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _notesController;

  String? _photoPath;
  String _bloodGroup = 'Unknown';
  DateTime? _dateOfBirth;
  bool _showOnLockScreen = true;

  final List<String> _bloodGroups = [
    'Unknown',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  final List<String> _conditionSuggestions = [
    'Asthma',
    'Type 1 Diabetes',
    'Type 2 Diabetes',
    'Hypertension',
    'Heart Disease',
    'Epilepsy',
    'Pacemaker',
  ];

  final List<String> _allergySuggestions = [
    'Penicillin',
    'Peanuts',
    'Latex',
    'Sulfa drugs',
    'Shellfish',
    'Aspirin',
    'Bee stings',
  ];

  @override
  void initState() {
    super.initState();
    final card = widget.initialCard ?? EmergencyState.instance.card;

    _nameController = TextEditingController(text: card.fullName);
    _conditionsController =
        TextEditingController(text: card.medicalConditions);
    _allergiesController = TextEditingController(text: card.allergies);
    _medicationsController =
        TextEditingController(text: card.currentMedications);
    _contactNameController =
        TextEditingController(text: card.emergencyContactName);
    _contactPhoneController =
        TextEditingController(text: card.emergencyContactPhone);
    _notesController = TextEditingController(text: card.additionalNotes);

    _photoPath = card.photoPath;
    _bloodGroup = card.bloodGroup.isNotEmpty ? card.bloodGroup : 'Unknown';
    _dateOfBirth = card.dateOfBirth;
    _showOnLockScreen = card.showOnLockScreen;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _conditionsController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() {
          _photoPath = file.path;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick photo: $e')),
      );
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime initial = _dateOfBirth ?? DateTime(1995, 1, 1);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  void _addSuggestionToField(
      TextEditingController controller, String suggestion) {
    final current = controller.text.trim();
    if (current.isEmpty) {
      controller.text = suggestion;
    } else if (!current.toLowerCase().contains(suggestion.toLowerCase())) {
      controller.text = '$current, $suggestion';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final card = EmergencyCard(
      id: widget.initialCard?.id ?? 'default_user',
      fullName: _nameController.text.trim(),
      photoPath: _photoPath,
      bloodGroup: _bloodGroup,
      dateOfBirth: _dateOfBirth,
      medicalConditions: _conditionsController.text.trim(),
      allergies: _allergiesController.text.trim(),
      currentMedications: _medicationsController.text.trim(),
      emergencyContactName: _contactNameController.text.trim(),
      emergencyContactPhone: _contactPhoneController.text.trim(),
      additionalNotes: _notesController.text.trim(),
      showOnLockScreen: _showOnLockScreen,
      updatedAt: DateTime.now(),
    );

    await EmergencyState.instance.saveCard(card);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency card saved securely.'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialCard?.isNotEmpty == true
            ? 'Edit Emergency Card'
            : 'Create Emergency Card'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded, color: AppTheme.medicalBlue),
            tooltip: 'Save Card',
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // Profile Photo Picker
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: isDark
                        ? AppTheme.cardDark
                        : AppTheme.borderLight,
                    backgroundImage: (_photoPath != null &&
                            _photoPath!.isNotEmpty &&
                            !kIsWeb &&
                            File(_photoPath!).existsSync())
                        ? FileImage(File(_photoPath!)) as ImageProvider
                        : null,
                    child: (_photoPath == null ||
                            _photoPath!.isEmpty ||
                            (!kIsWeb && !File(_photoPath!).existsSync()))
                        ? const Icon(Icons.person_rounded,
                            size: 60, color: AppTheme.textMuted)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.medicalBlue,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 20),
                        tooltip: 'Change Photo',
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (ctx) => SafeArea(
                              child: Wrap(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.photo_camera),
                                    title: const Text('Take Photo'),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _pickPhoto(ImageSource.camera);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_library),
                                    title: const Text('Choose from Gallery'),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _pickPhoto(ImageSource.gallery);
                                    },
                                  ),
                                  if (_photoPath != null)
                                    ListTile(
                                      leading: const Icon(Icons.delete,
                                          color: AppTheme.sosRed),
                                      title: const Text('Remove Photo',
                                          style:
                                              TextStyle(color: AppTheme.sosRed)),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        setState(() {
                                          _photoPath = null;
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 1: Basic Information
            _buildSectionHeader('Personal Information', Icons.badge_outlined),
            const SizedBox(height: 10),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: Icon(Icons.person_outline),
                hintText: 'e.g. John Doe',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Blood Group & DOB Row
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    initialValue: _bloodGroup,
                    decoration: const InputDecoration(
                      labelText: 'Blood Group',
                      prefixIcon: Icon(Icons.bloodtype_outlined,
                          color: AppTheme.sosRed),
                    ),
                    items: _bloodGroups.map((bg) {
                      return DropdownMenuItem<String>(
                        value: bg,
                        child: Text(
                          bg,
                          style: TextStyle(
                            color: bg != 'Unknown' ? AppTheme.sosRed : null,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _bloodGroup = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: _selectDateOfBirth,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      child: Text(
                        _dateOfBirth != null
                            ? DateFormat('yyyy-MM-dd').format(_dateOfBirth!)
                            : 'Select date',
                        style: TextStyle(
                          color: _dateOfBirth == null ? AppTheme.textMuted : null,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section 2: Medical Information
            _buildSectionHeader(
                'Medical Profile', Icons.medical_services_outlined),
            const SizedBox(height: 10),

            // Emergency Medical Conditions
            TextFormField(
              controller: _conditionsController,
              decoration: const InputDecoration(
                labelText: 'Medical Conditions',
                prefixIcon: Icon(Icons.warning_amber_rounded,
                    color: AppTheme.warningOrange),
                hintText: 'e.g. Asthma, Diabetes, Hypertension',
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _conditionSuggestions.map((s) {
                return ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 11)),
                  onPressed: () =>
                      _addSuggestionToField(_conditionsController, s),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Allergies
            TextFormField(
              controller: _allergiesController,
              decoration: const InputDecoration(
                labelText: 'Allergies',
                prefixIcon: Icon(Icons.coronavirus_outlined,
                    color: AppTheme.sosRed),
                hintText: 'e.g. Penicillin, Peanuts, Latex',
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _allergySuggestions.map((s) {
                return ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 11)),
                  onPressed: () =>
                      _addSuggestionToField(_allergiesController, s),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Current Medications
            TextFormField(
              controller: _medicationsController,
              decoration: const InputDecoration(
                labelText: 'Current Medications',
                prefixIcon: Icon(Icons.medication_outlined,
                    color: AppTheme.medicalBlue),
                hintText: 'e.g. Albuterol Inhaler, Metformin 500mg',
              ),
            ),
            const SizedBox(height: 24),

            // Section 3: Emergency Contact Details
            _buildSectionHeader(
                'Primary Contact Details', Icons.contact_phone_outlined),
            const SizedBox(height: 10),

            TextFormField(
              controller: _contactNameController,
              decoration: const InputDecoration(
                labelText: 'Emergency Contact Name',
                prefixIcon: Icon(Icons.person_outline),
                hintText: 'e.g. Jane Doe (Wife)',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _contactPhoneController,
              decoration: const InputDecoration(
                labelText: 'Emergency Contact Phone',
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: 'e.g. +1 555-0199',
              ),
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  return EmergencyContact.validatePhoneNumber(v);
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Section 4: Additional Notes & Lock Screen Setting
            _buildSectionHeader(
                'Notes & Offline Access', Icons.note_alt_outlined),
            const SizedBox(height: 10),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Medical / First Responder Notes',
                prefixIcon: Icon(Icons.notes_rounded),
                hintText: 'e.g. Organ donor, hearing impaired, wheelchair user...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Show on Lock Screen toggle
            SwitchListTile(
              title: const Text('Show on Lock Screen / Offline Access'),
              subtitle: const Text(
                  'Make emergency information viewable even when offline or from emergency screen.'),
              value: _showOnLockScreen,
              activeThumbColor: AppTheme.medicalBlue,
              onChanged: (val) => setState(() => _showOnLockScreen = val),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
              ),
            ),
            const SizedBox(height: 28),

            // Save Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.medicalBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.save_rounded),
                label: const Text(
                  'SAVE EMERGENCY CARD',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: _save,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.medicalBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
