import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/emergency_card.dart';
import '../services/emergency_service.dart';
import '../state/emergency_state.dart';
import '../utils/app_theme.dart';
import '../widgets/medical_badge.dart';
import 'emergency_card_edit_screen.dart';
import 'lock_screen_card_screen.dart';

class EmergencyCardScreen extends StatelessWidget {
  const EmergencyCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: EmergencyState.instance,
      builder: (context, _) {
        final card = EmergencyState.instance.card;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Emergency Information Card'),
            actions: [
              if (card.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  tooltip: 'Share Card',
                  onPressed: () {
                    EmergencyService.instance.shareEmergencyCard(card);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'Edit Card',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EmergencyCardEditScreen(initialCard: card),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          body: card.isEmpty
              ? _buildEmptyState(context)
              : _buildCardView(context, card, isDark),
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
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.medicalBlue.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medical_information_outlined,
                size: 46,
                color: AppTheme.medicalBlue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Emergency Card Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your emergency info card so first responders and contacts can access critical medical data when needed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
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
              label: const Text('Create Emergency Card'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EmergencyCardEditScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardView(
      BuildContext context, EmergencyCard card, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Offline badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.successGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.successGreen.withOpacity(0.3),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.offline_pin_rounded,
                  color: AppTheme.successGreen, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Saved locally & available 100% offline without internet.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Main Profile Header Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor:
                      isDark ? AppTheme.cardDark : AppTheme.borderLight,
                  backgroundImage: (card.photoPath != null &&
                          card.photoPath!.isNotEmpty &&
                          !kIsWeb &&
                          File(card.photoPath!).existsSync())
                      ? FileImage(File(card.photoPath!)) as ImageProvider
                      : null,
                  child: (card.photoPath == null ||
                          card.photoPath!.isEmpty ||
                          (!kIsWeb && !File(card.photoPath!).existsSync()))
                      ? const Icon(Icons.person_rounded,
                          size: 44, color: AppTheme.textMuted)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (card.age != null)
                        Text(
                          'Age: ${card.age} yrs (${DateFormat('yyyy-MM-dd').format(card.dateOfBirth!)})',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      const SizedBox(height: 8),
                      BloodGroupBadge(bloodGroup: card.bloodGroup),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Medical Conditions
        if (card.medicalConditions.isNotEmpty)
          _buildInfoSection(
            title: 'Medical Conditions',
            icon: Icons.warning_amber_rounded,
            iconColor: AppTheme.warningOrange,
            content: card.medicalConditions,
            isDark: isDark,
          ),

        // Allergies
        if (card.allergies.isNotEmpty)
          _buildInfoSection(
            title: 'Allergies & Reactions',
            icon: Icons.coronavirus_outlined,
            iconColor: AppTheme.sosRed,
            content: card.allergies,
            isDark: isDark,
            isAlert: true,
          ),

        // Medications
        if (card.currentMedications.isNotEmpty)
          _buildInfoSection(
            title: 'Current Medications',
            icon: Icons.medication_outlined,
            iconColor: AppTheme.medicalBlue,
            content: card.currentMedications,
            isDark: isDark,
          ),

        // Emergency Contact Tile
        if (card.emergencyContactName.isNotEmpty ||
            card.emergencyContactPhone.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.phone_in_talk_rounded,
                          color: AppTheme.sosRed, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Primary Emergency Contact',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.emergencyContactName.isNotEmpty
                                  ? card.emergencyContactName
                                  : 'Contact',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (card.emergencyContactPhone.isNotEmpty)
                              Text(
                                card.emergencyContactPhone,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (card.emergencyContactPhone.isNotEmpty)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.sosRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          icon: const Icon(Icons.call, size: 18),
                          label: const Text('Call'),
                          onPressed: () {
                            EmergencyService.instance
                                .callContact(card.emergencyContactPhone);
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),

        // Additional Notes
        if (card.additionalNotes.isNotEmpty)
          _buildInfoSection(
            title: 'Additional Notes',
            icon: Icons.notes_rounded,
            iconColor: AppTheme.textMuted,
            content: card.additionalNotes,
            isDark: isDark,
          ),

        // Lock Screen Access Banner
        Card(
          color: isDark ? AppTheme.cardDark : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.medicalBlue.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.screen_lock_portrait_rounded,
                      color: AppTheme.medicalBlue, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lock Screen / Offline View',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        card.showOnLockScreen
                            ? 'Enabled for instant responder access'
                            : 'Disabled',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LockScreenCardScreen(card: card),
                      ),
                    );
                  },
                  child: const Text('Preview'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Action Buttons Row
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.medicalBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.share_rounded, size: 20),
                label: const Text('Share Card'),
                onPressed: () {
                  EmergencyService.instance.shareEmergencyCard(card);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.edit_rounded, size: 20),
                label: const Text('Edit Card'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EmergencyCardEditScreen(initialCard: card),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Delete Card Button
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: AppTheme.sosRed),
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          label: const Text('Delete Emergency Card'),
          onPressed: () => _confirmDelete(context),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
    required bool isDark,
    bool isAlert = false,
  }) {
    return Card(
      color: isAlert ? (isDark ? const Color(0xFF281111) : const Color(0xFFFFF1F2)) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isAlert ? AppTheme.sosRed.withOpacity(0.3) : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isAlert ? AppTheme.sosRed : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Emergency Card?'),
        content: const Text(
          'Are you sure you want to remove your emergency medical information? This cannot be undone.',
        ),
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
      await EmergencyState.instance.deleteCard();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency card deleted.')),
      );
    }
  }
}
