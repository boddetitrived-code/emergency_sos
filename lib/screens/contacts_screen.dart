import 'package:flutter/material.dart';
import '../models/emergency_contact.dart';
import '../services/emergency_service.dart';
import '../state/emergency_state.dart';
import '../utils/app_theme.dart';
import '../widgets/alert_status_dialog.dart';
import 'contact_edit_dialog.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: EmergencyState.instance,
      builder: (context, _) {
        final contacts = EmergencyState.instance.contacts;
        final sosRecipients = EmergencyState.instance.sosRecipients;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Trusted Contacts'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_rounded),
                tooltip: 'Add Contact',
                onPressed: () => _addContact(context),
              ),
            ],
          ),
          body: contacts.isEmpty
              ? _buildEmptyState(context)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary Banner & Test All Button
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${contacts.length} Trusted Contacts',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${sosRecipients.length} receiving SOS alerts',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white60
                                            : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppTheme.warningOrange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                  ),
                                  icon: const Icon(Icons.notification_important_rounded,
                                      size: 16),
                                  label: const Text(
                                    'Test SOS',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  onPressed: sosRecipients.isEmpty
                                      ? null
                                      : () => _triggerTestAlert(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 4),
                            const Text(
                              'Test alerts verify SMS / messenger delivery and GPS coordinates without triggering real emergency services.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Contact Cards List
                    ...contacts.map((contact) => _buildContactCard(
                          context,
                          contact: contact,
                          isDark: isDark,
                        )),
                    const SizedBox(height: 80),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.medicalBlue,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Add Contact'),
            onPressed: () => _addContact(context),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.medicalBlue.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.group_add_outlined,
                size: 40,
                color: AppTheme.medicalBlue,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Emergency Contacts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add family members, friends, or doctors who should receive your SOS alerts and location during emergencies.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.medicalBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add First Emergency Contact'),
              onPressed: () => _addContact(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required EmergencyContact contact,
    required bool isDark,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar with relation initial
                CircleAvatar(
                  radius: 22,
                  backgroundColor: contact.isPrimary
                      ? AppTheme.sosRed.withOpacity(0.15)
                      : AppTheme.medicalBlue.withOpacity(0.15),
                  child: Icon(
                    contact.isPrimary
                        ? Icons.star_rounded
                        : Icons.person_outline_rounded,
                    color: contact.isPrimary
                        ? AppTheme.sosRed
                        : AppTheme.medicalBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              contact.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (contact.isPrimary)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.sosRed.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'PRIMARY',
                                style: TextStyle(
                                  color: AppTheme.sosRed,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${contact.relationship} • ${contact.phone}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                // Action Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _editContact(context, contact);
                    } else if (val == 'primary') {
                      EmergencyState.instance.setPrimaryContact(contact.id);
                    } else if (val == 'delete') {
                      _deleteContact(context, contact);
                    } else if (val == 'test') {
                      _triggerSingleContactTest(context, contact);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Details'),
                        ],
                      ),
                    ),
                    if (!contact.isPrimary)
                      const PopupMenuItem(
                        value: 'primary',
                        child: Row(
                          children: [
                            Icon(Icons.star_outline_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Set as Primary'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'test',
                      child: Row(
                        children: [
                          Icon(Icons.send_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Send Test Alert'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: AppTheme.sosRed),
                          SizedBox(width: 8),
                          Text('Delete Contact',
                              style: TextStyle(color: AppTheme.sosRed)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // SOS Recipient Toggle
                InkWell(
                  onTap: () {
                    EmergencyState.instance.toggleSosRecipient(
                        contact.id, !contact.isSosRecipient);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        Checkbox(
                          value: contact.isSosRecipient,
                          activeColor: AppTheme.medicalBlue,
                          onChanged: (val) {
                            if (val != null) {
                              EmergencyState.instance.toggleSosRecipient(
                                  contact.id, val);
                            }
                          },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Receive SOS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: contact.isSosRecipient
                                ? AppTheme.medicalBlue
                                : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Call Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.sosRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.call, size: 16),
                  label: const Text('Call', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    EmergencyService.instance.callContact(contact.phone);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addContact(BuildContext context) async {
    final contact = await ContactEditDialog.show(context);
    if (contact != null) {
      await EmergencyState.instance.addContact(contact);
    }
  }

  Future<void> _editContact(
      BuildContext context, EmergencyContact contact) async {
    final updated = await ContactEditDialog.show(context, contact: contact);
    if (updated != null) {
      await EmergencyState.instance.updateContact(updated);
    }
  }

  Future<void> _deleteContact(
      BuildContext context, EmergencyContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Contact?'),
        content: Text('Remove ${contact.name} from your trusted emergency contacts?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.sosRed),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await EmergencyState.instance.deleteContact(contact.id);
    }
  }

  Future<void> _triggerTestAlert(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.warningOrange),
            SizedBox(width: 8),
            Text('Send Test Alert?'),
          ],
        ),
        content: const Text(
          'This will compose a clearly marked test alert with your current GPS location to all selected SOS contacts.\n\nIt will NOT trigger an actual emergency response.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningOrange),
            child: const Text('Send Test Alert',
                style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final state = EmergencyState.instance;
      final result = await state.triggerSosAlert(isTest: true);

      if (!context.mounted) return;
      AlertStatusDialog.show(
        context,
        alert: result.alert,
        primaryContactPhone: state.primaryContact?.phone,
      );
    }
  }

  Future<void> _triggerSingleContactTest(
      BuildContext context, EmergencyContact contact) async {
    final state = EmergencyState.instance;
    // Dispatch test specifically for this contact
    final result = await EmergencyService.instance.triggerSosAlert(
      card: state.card,
      contacts: [contact.copyWith(isSosRecipient: true)],
      isTest: true,
    );

    if (!context.mounted) return;
    AlertStatusDialog.show(
      context,
      alert: result.alert,
      primaryContactPhone: contact.phone,
    );
  }
}
