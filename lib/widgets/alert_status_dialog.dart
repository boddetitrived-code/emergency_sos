import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/sos_alert.dart';
import '../services/emergency_service.dart';
import '../utils/app_theme.dart';

class AlertStatusDialog extends StatelessWidget {
  final SosAlert alert;
  final String? primaryContactPhone;

  const AlertStatusDialog({
    super.key,
    required this.alert,
    this.primaryContactPhone,
  });

  static Future<void> show(
    BuildContext context, {
    required SosAlert alert,
    String? primaryContactPhone,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertStatusDialog(
        alert: alert,
        primaryContactPhone: primaryContactPhone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color headerColor;
    IconData headerIcon;
    String statusTitle;

    switch (alert.status) {
      case AlertStatus.sent:
        headerColor = AppTheme.successGreen;
        headerIcon = Icons.check_circle_outline_rounded;
        statusTitle = alert.isTest ? 'Test Alert Dispatched' : 'SOS Alert Dispatched';
        break;
      case AlertStatus.failed:
        headerColor = AppTheme.sosRed;
        headerIcon = Icons.error_outline_rounded;
        statusTitle = 'Alert Dispatch Failed';
        break;
      case AlertStatus.pending:
        headerColor = AppTheme.warningOrange;
        headerIcon = Icons.hourglass_top_rounded;
        statusTitle = 'Alert In Progress';
        break;
      case AlertStatus.cancelled:
        headerColor = AppTheme.textMuted;
        headerIcon = Icons.cancel_outlined;
        statusTitle = 'Alert Cancelled';
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Icon Header
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: headerColor.withOpacity(isDark ? 0.2 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(headerIcon, color: headerColor, size: 36),
              ),
            ),
            const SizedBox(height: 14),

            // Title
            Center(
              child: Text(
                statusTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: headerColor,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Status message
            if (alert.statusMessage != null)
              Center(
                child: Text(
                  alert.statusMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            const SizedBox(height: 14),

            // Details card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : AppTheme.bgLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.contacts_rounded,
                          size: 16, color: AppTheme.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        'Recipients: ${alert.recipientPhones.length} contact(s)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        alert.isLocationOutdated
                            ? Icons.history_rounded
                            : Icons.location_on_rounded,
                        size: 16,
                        color: alert.isLocationOutdated
                            ? AppTheme.warningOrange
                            : AppTheme.medicalBlue,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          alert.latitude != null
                              ? 'GPS: ${alert.latitude!.toStringAsFixed(4)}, ${alert.longitude!.toStringAsFixed(4)} ' +
                                  (alert.isLocationOutdated
                                      ? '(Outdated cache)'
                                      : '(Live)')
                              : 'GPS: Not included',
                          style: TextStyle(
                            fontSize: 12,
                            color: alert.isLocationOutdated
                                ? AppTheme.warningOrange
                                : null,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Call Primary Contact Button
            if (primaryContactPhone != null &&
                primaryContactPhone!.trim().isNotEmpty) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.sosRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
                label: const Text('Call Primary Emergency Contact'),
                onPressed: () {
                  EmergencyService.instance.callContact(primaryContactPhone!);
                },
              ),
              const SizedBox(height: 8),
            ],

            // Fallback options: Copy message and Share sheet
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy Text',
                        style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: alert.message));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Emergency message copied to clipboard.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 16),
                    label:
                        const Text('Share via...', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      Share.share(
                        alert.message,
                        subject: alert.isTest
                            ? 'SOS Test Alert'
                            : 'EMERGENCY SOS ALERT',
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Close button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
