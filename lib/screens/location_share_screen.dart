import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/emergency_service.dart';
import '../state/emergency_state.dart';
import '../utils/app_theme.dart';
import '../widgets/location_status_card.dart';

class LocationShareScreen extends StatefulWidget {
  const LocationShareScreen({super.key});

  @override
  State<LocationShareScreen> createState() => _LocationShareScreenState();
}

class _LocationShareScreenState extends State<LocationShareScreen> {
  int _selectedDurationMinutes = 30;

  final List<int> _durations = [15, 30, 60, 120];

  @override
  void initState() {
    super.initState();
    _selectedDurationMinutes =
        EmergencyState.instance.trackingDurationMinutes;
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: EmergencyState.instance,
      builder: (context, _) {
        final state = EmergencyState.instance;
        final location = state.lastLocationResult;
        final isLocating = state.isLocating;
        final session = state.liveTrackingSession;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Location Sharing'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Current Location Card
              LocationStatusCard(
                location: location,
                isLocating: isLocating,
                onRefresh: () => state.refreshLocation(showLoading: true),
              ),
              const SizedBox(height: 16),

              // One-Tap Share Current Location Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.medicalBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.share_location_rounded, size: 22),
                label: const Text(
                  'Share Current Location Link',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                onPressed: (location != null && location.isSuccess)
                    ? () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final shared = await EmergencyService.instance
                            .shareCurrentLocation(card: state.card);
                        if (!shared && mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Could not share location.'),
                            ),
                          );
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 24),

              // Live Tracking Section Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: session.isActive
                                  ? AppTheme.successGreen.withOpacity(0.15)
                                  : AppTheme.medicalBlue.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              session.isActive
                                  ? Icons.sensors_rounded
                                  : Icons.timelapse_rounded,
                              color: session.isActive
                                  ? AppTheme.successGreen
                                  : AppTheme.medicalBlue,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.isActive
                                      ? 'Live Location Active'
                                      : 'Temporary Live Tracking',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  session.isActive
                                      ? 'Time Remaining: ${_formatDuration(session.remainingDuration)}'
                                      : 'Share updates periodically with trusted contacts',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: session.isActive
                                        ? AppTheme.successGreen
                                        : (isDark
                                            ? Colors.white60
                                            : Colors.black54),
                                    fontWeight: session.isActive
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      if (session.isActive) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.bgDark
                                : AppTheme.successLight.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.successGreen.withOpacity(0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_outline,
                                      size: 16, color: AppTheme.successGreen),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Active Tracking Session',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.successGreen,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Started at ${DateFormat('HH:mm').format(session.startedAt!)} • Stops automatically at ${DateFormat('HH:mm').format(session.expiresAt!)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stop Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.sosRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.stop_rounded, size: 20),
                            label: const Text('Stop Live Tracking'),
                            onPressed: () {
                              state.stopLiveTracking();
                            },
                          ),
                        ),
                      ] else ...[
                        // Duration Selector
                        const Text(
                          'Select Tracking Duration:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: _durations.map((mins) {
                            final isSelected =
                                _selectedDurationMinutes == mins;
                            return Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: ChoiceChip(
                                  label: Text(
                                    mins >= 60
                                        ? '${mins ~/ 60}h'
                                        : '${mins}m',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: isSelected ? Colors.white : null,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: AppTheme.medicalBlue,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedDurationMinutes = mins;
                                      });
                                      state.updateTrackingDurationMinutes(mins);
                                    }
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Start Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.medicalBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded,
                                size: 22),
                            label: Text(
                              'Start Live Tracking (${_selectedDurationMinutes >= 60 ? "${_selectedDurationMinutes ~/ 60} Hour" : "$_selectedDurationMinutes Min"})',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final started = await state.startLiveTracking(
                                duration:
                                    Duration(minutes: _selectedDurationMinutes),
                              );
                              if (!started && mounted) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Please grant GPS permission to enable live tracking.'),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Live tracking automatically stops when the timer expires to protect battery and privacy.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Privacy & Offline Notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.security_rounded,
                        size: 20, color: AppTheme.medicalBlue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Location details are strictly shared with your approved emergency contacts and are never uploaded to public servers.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
