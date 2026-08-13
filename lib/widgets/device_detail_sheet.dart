import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_icons.dart';
import 'device_schedule_bottom_sheet.dart';

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
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: AppColors.textSecondary),
                onPressed: () {
                  final nameController = TextEditingController(text: device.name);
                  String selectedType = device.type;
                  showDialog(
                    context: context,
                    builder: (ctx) => StatefulBuilder(
                      builder: (context, setState) {
                        return AlertDialog(
                          title: const Text('Edit Device'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: nameController,
                                decoration: const InputDecoration(labelText: 'Device Name'),
                              ),
                              DropdownButton<String>(
                                value: selectedType,
                                items: ['outlet', 'bulb', 'iron', 'multiswitch', 'camera']
                                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => selectedType = val);
                                },
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () async {
                                if (nameController.text.trim().isNotEmpty) {
                                  await service.updateDevice(device.floorId, device.id, {
                                    'name': nameController.text.trim(),
                                    'type': selectedType,
                                  });
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                    Navigator.pop(context);
                                  }
                                }
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: AppColors.statusError),
                onPressed: () async {
                  await service.deleteDevice(device.floorId, device.id);
                  if (context.mounted) Navigator.pop(context);
                },
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

            const SizedBox(height: 20),

            // ── Schedule section ──
            _ScheduleSection(device: device as BulbDevice),
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

/// Inline schedule card shown inside [DeviceDetailSheet] for [BulbDevice]s.
class _ScheduleSection extends StatelessWidget {
  final BulbDevice device;

  const _ScheduleSection({required this.device});

  bool get _hasSchedule =>
      device.scheduleStart != null && device.scheduleEnd != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _hasSchedule
            ? AppColors.brass.withValues(alpha: 0.07)
            : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hasSchedule
              ? AppColors.brass.withValues(alpha: 0.35)
              : AppColors.divider,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 16,
                color: _hasSchedule ? AppColors.brass : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Daily Schedule',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color:
                      _hasSchedule ? AppColors.brassDeep : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              // Edit / Set button
              GestureDetector(
                onTap: () {
                  DeviceScheduleBottomSheet.show(
                    context,
                    floorId: device.floorId,
                    deviceId: device.id,
                    deviceName: device.name,
                    initialStart: device.scheduleStart,
                    initialEnd: device.scheduleEnd,
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.brass,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _hasSchedule ? Icons.edit_rounded : Icons.add_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _hasSchedule ? 'Edit' : 'Set Schedule',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Time display or empty state ──
          if (_hasSchedule) ...[
            Row(
              children: [
                Expanded(
                  child: _TimeCell(
                    icon: Icons.wb_sunny_outlined,
                    label: 'Turn ON',
                    time: device.scheduleStart!,
                    color: AppColors.brass,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: _TimeCell(
                    icon: Icons.nights_stay_outlined,
                    label: 'Turn OFF',
                    time: device.scheduleEnd!,
                    color: AppColors.pine,
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'No schedule set — tap "Set Schedule" to add one.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact time readout cell used inside [_ScheduleSection].
class _TimeCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final Color color;

  const _TimeCell({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          time,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

