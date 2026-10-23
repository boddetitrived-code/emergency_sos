import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/emergency_state.dart';
import '../utils/app_theme.dart';
import '../widgets/alert_status_dialog.dart';

class SosCountdownScreen extends StatefulWidget {
  final int countdownSeconds;

  const SosCountdownScreen({
    super.key,
    this.countdownSeconds = 5,
  });

  @override
  State<SosCountdownScreen> createState() => _SosCountdownScreenState();
}

class _SosCountdownScreenState extends State<SosCountdownScreen>
    with SingleTickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isDispatching = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.countdownSeconds;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
        HapticFeedback.mediumImpact();
      } else {
        _timer?.cancel();
        _dispatchSos();
      }
    });
  }

  Future<void> _dispatchSos() async {
    if (_isDispatching) return;
    setState(() {
      _isDispatching = true;
    });

    HapticFeedback.heavyImpact();

    final state = EmergencyState.instance;
    final result = await state.triggerSosAlert(isTest: false);

    if (!mounted) return;

    // Pop countdown screen
    Navigator.of(context).pop();

    // Show status modal
    final primary = state.primaryContact;
    AlertStatusDialog.show(
      context,
      alert: result.alert,
      primaryContactPhone: primary?.phone,
    );
  }

  void _cancelSos() {
    _timer?.cancel();
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double progress = widget.countdownSeconds > 0
        ? _remainingSeconds / widget.countdownSeconds
        : 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _cancelSos();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0B0B),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Header
                Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.sosRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.sosRed.withOpacity(0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_rounded,
                              color: AppTheme.sosRed, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'SOS ACTIVATION SEQUENCE',
                            style: TextStyle(
                              color: AppTheme.sosRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sending Emergency Alert In',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Center Countdown Circle
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radial Progress
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 10,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.sosRed),
                        ),
                      ),
                      // Countdown text & pulsing ring
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.sosRed.withOpacity(0.15 +
                                  (_pulseController.value * 0.15)),
                              border: Border.all(
                                color: AppTheme.sosRed,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: _isDispatching
                                  ? const Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          'DISPATCHING...',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      '$_remainingSeconds',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 72,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Bottom Action Buttons
                Column(
                  children: [
                    const Text(
                      'GPS location & medical details will be dispatched to your emergency contacts.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.close_rounded,
                            size: 26, color: Colors.black),
                        label: const Text(
                          'CANCEL SOS',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        onPressed: _isDispatching ? null : _cancelSos,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Bypass & Send Now
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.sosRed,
                          side: const BorderSide(
                              color: AppTheme.sosRed, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isDispatching ? null : _dispatchSos,
                        child: const Text(
                          'SEND IMMEDIATELY',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
