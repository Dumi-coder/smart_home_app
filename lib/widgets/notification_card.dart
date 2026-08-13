import 'package:flutter/material.dart';
import '../models/notification_alert.dart';
import '../theme/app_theme.dart';

class NotificationCard extends StatelessWidget {
  final NotificationAlert alert;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.alert,
    required this.onDismiss,
    required this.onTap,
  });

  Color get _accentColor {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return AppColors.statusError;
      case AlertSeverity.warning:
        return AppColors.brassDeep;
      case AlertSeverity.info:
        return AppColors.accentCamera;
    }
  }

  IconData get _icon {
    switch (alert.icon) {
      case 'smoke':
        return Icons.local_fire_department_outlined;
      case 'power':
        return Icons.power_settings_new;
      case 'motion':
        return Icons.remove_red_eye_outlined;
      case 'lock':
        return Icons.lock_outline;
      case 'wifi':
        return Icons.wifi_off_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String get _severityLabel {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return 'Critical';
      case AlertSeverity.warning:
        return 'Warning';
      case AlertSeverity.info:
        return 'Info';
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border(left: BorderSide(color: accent, width: 4)),
          boxShadow: const [
            BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, size: 20, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _severityLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (!alert.acknowledged)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alert.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.message,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (alert.room != null) ...[
                          Text(
                            alert.room!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('·', style: TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          alert.relativeTime,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
