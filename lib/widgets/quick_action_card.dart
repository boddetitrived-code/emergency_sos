import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.12),
        highlightColor: color.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.22 : 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 22,
                    ),
                  ),
                  trailing ??
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark ? Colors.white30 : Colors.black26,
                        size: 20,
                      ),
                ],
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: isDark ? AppTheme.textLight : AppTheme.textDark,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color:
                      isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
