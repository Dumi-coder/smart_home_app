import 'package:flutter/material.dart';
import '../models/device.dart';
import '../theme/app_theme.dart';
import '../theme/app_icons.dart';

/// A 2-column grid card for a single device, matching the Figma spec.
class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onToggle;
  final VoidCallback? onTap;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onToggle,
    this.onTap,
  });

  bool get _isOn => device.status == DeviceStatus.on;

  @override
  Widget build(BuildContext context) {
    final subStatus = DeviceIcons.subStatusFor(device);
    final accentColor = DeviceIcons.accentFor(device.type);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: _isOn
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              Color.lerp(AppColors.surface, accentColor, 0.06)!,
            ],
          )
              : null,
          color: _isOn ? null : AppColors.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: _isOn
              ? Border.all(
              color: accentColor.withValues(alpha: 0.45), width: 1.5)
              : Border.all(color: AppColors.divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: _isOn
                  ? accentColor.withValues(alpha: 0.20)
                  : AppColors.cardShadow,
              blurRadius: _isOn ? 18 : 6,
              offset: const Offset(0, 6),
              spreadRadius: _isOn ? -4 : 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: device icon + power button ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Device icon with colored glow badge
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _isOn
                        ? RadialGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.32),
                        accentColor.withValues(alpha: 0.16),
                      ],
                    )
                        : null,
                    color: _isOn ? null : AppColors.background,
                    boxShadow: _isOn
                        ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.30),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                    ]
                        : null,
                  ),
                  child: Icon(
                    DeviceIcons.iconFor(device.type),
                    size: 22,
                    color: _isOn ? accentColor : AppColors.textSecondary,
                  ),
                ),
                // Power toggle button
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isOn ? accentColor : AppColors.background,
                      shape: BoxShape.circle,
                      border: _isOn
                          ? null
                          : Border.all(color: AppColors.divider, width: 1),
                      boxShadow: _isOn
                          ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.45),
                          blurRadius: 8,
                          spreadRadius: -1,
                        ),
                      ]
                          : null,
                    ),
                    child: Icon(
                      Icons.power_settings_new,
                      size: 18,
                      color: _isOn ? AppColors.ink : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // ── Device name ──
            Text(
              device.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 2),

            // ── Sub-status (e.g. "Max 30m", "1/2 on") ──
            if (subStatus != null)
              Text(
                subStatus,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: device.type == 'iron' && _isOn
                      ? AppColors.statusError
                      : AppColors.textSecondary,
                ),
              ),

            const SizedBox(height: 4),

            // ── ON/OFF status text ──
            Text(
              statusToString(device.status),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _isOn ? AppColors.primaryActiveDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}