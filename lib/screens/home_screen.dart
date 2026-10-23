import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/emergency_service.dart';
import '../state/emergency_state.dart';
import '../utils/app_theme.dart';
import '../widgets/location_status_card.dart';
import '../widgets/medical_badge.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/sos_button.dart';
import 'contacts_screen.dart';
import 'emergency_card_edit_screen.dart';
import 'emergency_card_screen.dart';
import 'location_share_screen.dart';
import 'lock_screen_card_screen.dart';
import 'sos_countdown_screen.dart';
import 'sos_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize state on launch
    EmergencyState.instance.initialize();
  }

  void _openSosCountdown() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SosCountdownScreen(
          countdownSeconds: EmergencyState.instance.countdownSeconds,
        ),
      ),
    );
  }

  void _callPrimaryContact() {
    final primary = EmergencyState.instance.primaryContact;
    if (primary != null && primary.phone.trim().isNotEmpty) {
      EmergencyService.instance.callContact(primary.phone);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'No primary emergency contact set. Please add a contact.'),
          action: SnackBarAction(
            label: 'Add',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactsScreen()),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: EmergencyState.instance,
      builder: (context, _) {
        final state = EmergencyState.instance;

        if (state.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.sosRed),
                  SizedBox(height: 16),
                  Text('Loading Emergency Profile...'),
                ],
              ),
            ),
          );
        }

        final screens = [
          _buildMainSosView(context, state),
          const EmergencyCardScreen(),
          const ContactsScreen(),
          const SosHistoryScreen(),
        ];

        return Scaffold(
          body: screens[_currentIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) {
              setState(() {
                _currentIndex = idx;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.emergency_outlined),
                selectedIcon:
                    Icon(Icons.emergency_rounded, color: AppTheme.sosRed),
                label: 'SOS Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.badge_outlined),
                selectedIcon:
                    Icon(Icons.badge_rounded, color: AppTheme.medicalBlue),
                label: 'Info Card',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon:
                    Icon(Icons.people_rounded, color: AppTheme.medicalBlue),
                label: 'Contacts',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_rounded),
                selectedIcon:
                    Icon(Icons.history_rounded, color: AppTheme.medicalBlue),
                label: 'History',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainSosView(BuildContext context, EmergencyState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = state.card;
    final primary = state.primaryContact;
    final session = state.liveTrackingSession;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EMERGENCY SOS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.screen_lock_portrait_rounded),
            tooltip: 'Offline Emergency View',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LockScreenCardScreen(card: card),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => _openSettingsDialog(context, state),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              // 1. Prominent User Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: isDark
                            ? AppTheme.cardDark
                            : AppTheme.borderLight,
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
                                size: 30, color: AppTheme.textMuted)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.fullName.isNotEmpty
                                  ? card.fullName
                                  : 'Setup Emergency Card',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            if (primary != null)
                              Text(
                                'Primary: ${primary.name} (${primary.relationship})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            else
                              const Text(
                                'No primary contact configured',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.sosRed,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (card.bloodGroup.isNotEmpty &&
                          card.bloodGroup != 'Unknown') ...[
                        BloodGroupBadge(bloodGroup: card.bloodGroup),
                      ] else ...[
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const EmergencyCardEditScreen(),
                              ),
                            );
                          },
                          child: const Text('Edit',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Active Live Tracking Banner (if active)
              if (session.isActive) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.successGreen.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sensors_rounded,
                          color: AppTheme.successGreen, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Live Tracking Active (${session.remainingDuration.inMinutes}m left)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.successGreen,
                          ),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.sosRed,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => state.stopLiveTracking(),
                        child: const Text('Stop',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 3. Center SOS Button (One-Hand Friendly)
              const SizedBox(height: 12),
              SosButton(
                onTap: _openSosCountdown,
              ),
              const SizedBox(height: 8),
              const Text(
                'Pressing SOS activates a 5s countdown before dispatching GPS location.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 20),

              // 4. Quick Actions
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.phone_forwarded_rounded,
                        title: 'Call Contact',
                        subtitle:
                            primary != null ? primary.name : 'Primary ICE',
                        color: AppTheme.sosRed,
                        onTap: _callPrimaryContact,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.notification_important_rounded,
                        title: 'Send SOS',
                        subtitle: 'Alert Contacts',
                        color: AppTheme.sosRedDark,
                        onTap: _openSosCountdown,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.share_location_rounded,
                        title: 'Share Location',
                        subtitle: 'Live Tracking',
                        color: AppTheme.medicalBlue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LocationShareScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.medical_information_rounded,
                        title: 'Medical Card',
                        subtitle: 'Offline View',
                        color: AppTheme.successGreen,
                        onTap: () {
                          setState(() {
                            _currentIndex = 1;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 5. GPS Location Status Card
              LocationStatusCard(
                location: state.lastLocationResult,
                isLocating: state.isLocating,
                onRefresh: () => state.refreshLocation(showLoading: true),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  void _openSettingsDialog(BuildContext context, EmergencyState state) {
    int countdown = state.countdownSeconds;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('SOS Preferences'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Countdown Duration (seconds)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Short countdown to prevent accidental activation.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [3, 5, 10].map((sec) {
                    final isSel = countdown == sec;
                    return ChoiceChip(
                      label: Text('${sec}s'),
                      selected: isSel,
                      selectedColor: AppTheme.sosRed,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : null,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setDialogState(() {
                            countdown = sec;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Offline Storage & Privacy',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'All sensitive medical records and contacts are stored strictly on your local device SQLite database.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(ctx),
              ),
              ElevatedButton(
                child: const Text('Save'),
                onPressed: () async {
                  await state.updateCountdownSeconds(countdown);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
