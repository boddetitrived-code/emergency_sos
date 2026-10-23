import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class BloodGroupBadge extends StatelessWidget {
  final String bloodGroup;
  final bool large;

  const BloodGroupBadge({
    super.key,
    required this.bloodGroup,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 10,
        vertical: large ? 10 : 5,
      ),
      decoration: BoxDecoration(
        color: AppTheme.sosRed.withOpacity(0.12),
        borderRadius: BorderRadius.circular(large ? 14 : 8),
        border: Border.all(
          color: AppTheme.sosRed.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bloodtype_rounded,
            color: AppTheme.sosRed,
            size: large ? 24 : 16,
          ),
          const SizedBox(width: 6),
          Text(
            bloodGroup.isNotEmpty ? bloodGroup : 'Unknown',
            style: TextStyle(
              color: AppTheme.sosRed,
              fontWeight: FontWeight.w800,
              fontSize: large ? 20 : 13,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  const TagChip({
    super.key,
    required this.label,
    this.icon,
    this.color = AppTheme.medicalBlue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
