import 'package:flutter/material.dart';
import '../models/emergency_contact.dart';
import '../utils/app_theme.dart';

class ContactEditDialog extends StatefulWidget {
  final EmergencyContact? contact;

  const ContactEditDialog({super.key, this.contact});

  static Future<EmergencyContact?> show(BuildContext context,
      {EmergencyContact? contact}) {
    return showDialog<EmergencyContact>(
      context: context,
      builder: (ctx) => ContactEditDialog(contact: contact),
    );
  }

  @override
  State<ContactEditDialog> createState() => _ContactEditDialogState();
}

class _ContactEditDialogState extends State<ContactEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String _relationship = 'Family';
  bool _isPrimary = false;
  bool _isSosRecipient = true;

  final List<String> _relationships = [
    'Family',
    'Parent',
    'Spouse',
    'Partner',
    'Child',
    'Sibling',
    'Friend',
    'Doctor',
    'Neighbor',
    'Colleague',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.contact;
    _nameController = TextEditingController(text: c?.name ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _relationship = c?.relationship ?? 'Family';
    if (!_relationships.contains(_relationship)) {
      _relationships.add(_relationship);
    }
    _isPrimary = c?.isPrimary ?? false;
    _isSosRecipient = c?.isSosRecipient ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final contact = EmergencyContact(
      id: widget.contact?.id ?? 'contact_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      relationship: _relationship,
      isPrimary: _isPrimary,
      isSosRecipient: _isSosRecipient,
      createdAt: widget.contact?.createdAt ?? DateTime.now(),
    );

    Navigator.of(context).pop(contact);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.contact != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Emergency Contact' : 'Add Emergency Contact'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Contact Name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Contact name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '+1 555-0100',
                ),
                keyboardType: TextInputType.phone,
                validator: EmergencyContact.validatePhoneNumber,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _relationship,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  prefixIcon: Icon(Icons.people_outline),
                ),
                items: _relationships.map((rel) {
                  return DropdownMenuItem(value: rel, child: Text(rel));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _relationship = val);
                },
              ),
              const SizedBox(height: 14),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Primary Emergency Contact',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Direct 1-tap call destination on home screen',
                    style: TextStyle(fontSize: 12)),
                value: _isPrimary,
                activeThumbColor: AppTheme.sosRed,
                onChanged: (val) => setState(() => _isPrimary = val),
              ),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Receive SOS Alerts',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Include in GPS emergency broadcasts',
                    style: TextStyle(fontSize: 12)),
                value: _isSosRecipient,
                activeThumbColor: AppTheme.medicalBlue,
                onChanged: (val) => setState(() => _isSosRecipient = val),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.medicalBlue,
            foregroundColor: Colors.white,
          ),
          onPressed: _save,
          child: Text(isEditing ? 'Save Changes' : 'Add Contact'),
        ),
      ],
    );
  }
}
