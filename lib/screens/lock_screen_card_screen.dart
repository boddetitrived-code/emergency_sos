import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/emergency_card.dart';
import '../services/emergency_service.dart';
import '../utils/app_theme.dart';
import '../widgets/medical_badge.dart';

class LockScreenCardScreen extends StatelessWidget {
  final EmergencyCard card;

  const LockScreenCardScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1D),
        foregroundColor: Colors.white,
        title: const Text('EMERGENCY MEDICAL INFO'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // ICE Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.sosRed,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medical_services_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'IN CASE OF EMERGENCY (I.C.E.)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Profile & Blood Group Section
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF141C2E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white12,
                        backgroundImage: (card.photoPath != null &&
                                card.photoPath!.isNotEmpty &&
                                !kIsWeb &&
                                File(card.photoPath!).existsSync())
                            ? FileImage(File(card.photoPath!)) as ImageProvider
                            : null,
                        child: (card.photoPath == null ||
                                card.photoPath!.isEmpty ||
                                (!kIsWeb && !File(card.photoPath!).existsSync()))
                            ? const Icon(Icons.person,
                                size: 48, color: Colors.white60)
                            : null,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.fullName.isNotEmpty
                                  ? card.fullName
                                  : 'Emergency Patient',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (card.age != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Age: ${card.age} yrs (${DateFormat('yyyy-MM-dd').format(card.dateOfBirth!)})',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'BLOOD GROUP:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      BloodGroupBadge(bloodGroup: card.bloodGroup, large: true),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Allergies High-Contrast Warning
            if (card.allergies.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E1014),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.sosRed.withOpacity(0.5), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: AppTheme.sosRed, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'ALLERGIES / CONTRAINDICATIONS',
                          style: TextStyle(
                            color: AppTheme.sosRed,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      card.allergies,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Conditions
            if (card.medicalConditions.isNotEmpty) ...[
              _buildDarkCard(
                title: 'MEDICAL CONDITIONS',
                icon: Icons.healing_rounded,
                iconColor: AppTheme.warningOrange,
                content: card.medicalConditions,
              ),
              const SizedBox(height: 14),
            ],

            // Medications
            if (card.currentMedications.isNotEmpty) ...[
              _buildDarkCard(
                title: 'CURRENT MEDICATIONS',
                icon: Icons.medication_rounded,
                iconColor: AppTheme.medicalBlue,
                content: card.currentMedications,
              ),
              const SizedBox(height: 14),
            ],

            // Emergency Contact & Direct Call
            if (card.emergencyContactName.isNotEmpty ||
                card.emergencyContactPhone.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141C2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EMERGENCY CONTACT',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                                    : 'Emergency Contact',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (card.emergencyContactPhone.isNotEmpty)
                                Text(
                                  card.emergencyContactPhone,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
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
                                  horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.call, size: 20),
                            label: const Text(
                              'CALL',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
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
              const SizedBox(height: 14),
            ],

            // Notes
            if (card.additionalNotes.isNotEmpty) ...[
              _buildDarkCard(
                title: 'ADDITIONAL NOTES',
                icon: Icons.notes_rounded,
                iconColor: Colors.white70,
                content: card.additionalNotes,
              ),
              const SizedBox(height: 14),
            ],

            // Offline access notice
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Accessible 100% offline without cellular data or Wi-Fi.',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141C2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
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
                  color: iconColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
