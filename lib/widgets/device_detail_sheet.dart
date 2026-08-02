import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_icons.dart';

/// Bottom sheet showing device details with toggle and brightness placeholder.
class DeviceDetailSheet extends StatelessWidget {
  final Device device;
  final FirestoreService service;

  const DeviceDetailSheet({
    super.key,
    required this.device,
    required this.service,
  });

  bool get _isOn => device.status == DeviceStatus.on;

  @override
  Widget build(BuildContext context) {
    final accentColor = DeviceIcons.accentFor(device.type);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header: icon + name + close button ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isOn
                      ? accentColor.withValues(alpha: 0.2)
                      : AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  DeviceIcons.iconFor(device.type),
                  size: 28,
                  color: _isOn ? accentColor : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (device.room != null)
                      Text(
                        device.room!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Icon(Icons.close, size: 18),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Status chips ──
          Row(
            children: [
              _StatusChip(
                label: _isOn ? 'ON' : 'OFF',
                color: _isOn ? AppColors.primaryActiveDark : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label: device.status == DeviceStatus.disconnected
                    ? 'Disconnected'
                    : 'Connected',
                color: device.status == DeviceStatus.disconnected
                    ? AppColors.statusDisconnected
                    : AppColors.textSecondary,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Toggle button ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                service.toggleDevice(
                    device.floorId, device.id, !_isOn);
                Navigator.pop(context);
              },
              icon: Icon(
                Icons.power_settings_new,
                color: _isOn ? AppColors.textOnDark : AppColors.textOnDark,
              ),
              label: Text(
                _isOn ? 'Turn Off' : 'Turn On',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textOnDark,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isOn ? AppColors.chipSelected : AppColors.primaryActiveDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                elevation: 0,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Brightness slider (visual placeholder) ──
          if (device.type == 'bulb') ...[
            Row(
              children: [
                const Text(
                  'Brightness',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '80%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Icon(Icons.remove, size: 16),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.primaryActive,
                      inactiveTrackColor: AppColors.divider,
                      thumbColor: AppColors.primaryActiveDark,
                      overlayColor:
                          AppColors.primaryActive.withValues(alpha: 0.2),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: 0.8,
                      onChanged: (_) {
                        // Placeholder — no brightness field in schema yet
                      },
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Icon(Icons.add, size: 16),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
