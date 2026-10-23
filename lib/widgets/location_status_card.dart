import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/location_service.dart';
import '../utils/app_theme.dart';

class LocationStatusCard extends StatelessWidget {
  final LocationResult? location;
  final bool isLocating;
  final VoidCallback onRefresh;

  const LocationStatusCard({
    super.key,
    required this.location,
    required this.isLocating,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool hasLocation = location != null && location!.isSuccess;
    final bool isOutdated = location != null && location!.isLastKnown;

    Color statusColor;
    String statusTitle;
    IconData statusIcon;

    if (isLocating) {
      statusColor = AppTheme.medicalBlue;
      statusTitle = 'Acquiring GPS Signal...';
      statusIcon = Icons.gps_not_fixed_rounded;
    } else if (hasLocation && !isOutdated) {
      statusColor = AppTheme.successGreen;
      statusTitle = 'GPS Active & Accurate';
      statusIcon = Icons.gps_fixed_rounded;
    } else if (hasLocation && isOutdated) {
      statusColor = AppTheme.warningOrange;
      statusTitle = 'Last Known GPS (Potentially Outdated)';
      statusIcon = Icons.history_toggle_off_rounded;
    } else {
      statusColor = AppTheme.sosRed;
      statusTitle = 'Location Unavailable';
      statusIcon = Icons.location_off_rounded;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(isDark ? 0.2 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusTitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                      if (hasLocation && location?.timestamp != null)
                        Text(
                          'Updated ${DateFormat('HH:mm:ss').format(location!.timestamp)}' +
                              (location!.accuracy != null
                                  ? ' (±${location!.accuracy!.toStringAsFixed(0)}m)'
                                  : ''),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: isLocating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Refresh Location',
                  onPressed: isLocating ? null : onRefresh,
                ),
              ],
            ),
            if (hasLocation) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.bgDark : AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        location!.formattedCoordinates,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (location!.googleMapsUrl != null)
                      InkWell(
                        onTap: () async {
                          final uri = Uri.parse(location!.googleMapsUrl!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text(
                            'Open Map',
                            style: TextStyle(
                              color: AppTheme.medicalBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (!hasLocation && !isLocating) ...[
              const SizedBox(height: 6),
              Text(
                location?.errorMessage ??
                    'Enable GPS or check permissions to share accurate coordinates.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.sosRed,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
