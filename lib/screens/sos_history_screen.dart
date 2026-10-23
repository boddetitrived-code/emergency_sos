import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sos_alert.dart';
import '../state/emergency_state.dart';
import '../utils/app_theme.dart';

class SosHistoryScreen extends StatelessWidget {
  const SosHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: EmergencyState.instance,
      builder: (context, _) {
        final alerts = EmergencyState.instance.alerts;

        return Scaffold(
          appBar: AppBar(
            title: const Text('SOS Alert History'),
            actions: [
              if (alerts.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded),
                  tooltip: 'Clear History',
                  onPressed: () => _confirmClearHistory(context),
                ),
            ],
          ),
          body: alerts.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    return _buildAlertCard(context, alert, isDark);
                  },
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
                color: AppTheme.medicalBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 40,
                color: AppTheme.medicalBlue,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No SOS Alerts Logged',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'All emergency alerts and test dispatches are recorded here for your personal records.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(
      BuildContext context, SosAlert alert, bool isDark) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (alert.status) {
      case AlertStatus.sent:
        statusColor = AppTheme.successGreen;
        statusLabel = 'DISPATCHED';
        statusIcon = Icons.check_circle_rounded;
        break;
      case AlertStatus.failed:
        statusColor = AppTheme.sosRed;
        statusLabel = 'FAILED';
        statusIcon = Icons.cancel_rounded;
        break;
      case AlertStatus.pending:
        statusColor = AppTheme.warningOrange;
        statusLabel = 'PENDING';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case AlertStatus.cancelled:
        statusColor = AppTheme.textMuted;
        statusLabel = 'CANCELLED';
        statusIcon = Icons.not_interested_rounded;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (alert.isTest) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.warningOrange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'TEST',
                          style: TextStyle(
                            color: AppTheme.warningOrange,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(alert.timestamp),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Recipients: ${alert.recipientPhones.length} contact(s)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            if (alert.latitude != null && alert.longitude != null)
              Row(
                children: [
                  Icon(
                    alert.isLocationOutdated
                        ? Icons.history_rounded
                        : Icons.place_rounded,
                    size: 14,
                    color: alert.isLocationOutdated
                        ? AppTheme.warningOrange
                        : AppTheme.medicalBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${alert.latitude!.toStringAsFixed(4)}, ${alert.longitude!.toStringAsFixed(4)}' +
                        (alert.isLocationOutdated
                            ? ' (Last Known)'
                            : ' (Accurate GPS)'),
                    style: TextStyle(
                      fontSize: 12,
                      color: alert.isLocationOutdated
                          ? AppTheme.warningOrange
                          : null,
                    ),
                  ),
                ],
              ),
            if (alert.statusMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                alert.statusMessage!,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (alert.googleMapsUrl != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    icon: const Icon(Icons.map_rounded, size: 16),
                    label: const Text('View Map',
                        style: TextStyle(fontSize: 12)),
                    onPressed: () async {
                      final uri = Uri.parse(alert.googleMapsUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                  label: const Text('View Message',
                      style: TextStyle(fontSize: 12)),
                  onPressed: () => _showMessageDialog(context, alert),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageDialog(BuildContext context, SosAlert alert) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(alert.isTest ? 'Test Alert Content' : 'SOS Alert Content'),
        content: SingleChildScrollView(
          child: SelectableText(
            alert.message,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Copy'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: alert.message));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
          ),
          ElevatedButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear SOS History?'),
        content: const Text(
          'This will delete all past SOS and test alert logs. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.sosRed),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await EmergencyState.instance.clearAlertsHistory();
    }
  }
}
