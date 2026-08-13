import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

/// Bottom sheet that lets the user set or clear a daily ON/OFF schedule
/// for a schedulable device (e.g. bulb).
///
/// Writes to Firestore via [FirestoreService.updateDeviceSchedule] /
/// [FirestoreService.clearDeviceSchedule].
class DeviceScheduleBottomSheet extends StatefulWidget {
  final String floorId;
  final String deviceId;
  final String deviceName;

  /// Pre-filled start time in "HH:mm" format, or null if no schedule.
  final String? initialStart;

  /// Pre-filled end time in "HH:mm" format, or null if no schedule.
  final String? initialEnd;

  const DeviceScheduleBottomSheet({
    super.key,
    required this.floorId,
    required this.deviceId,
    required this.deviceName,
    this.initialStart,
    this.initialEnd,
  });

  /// Helper: show the sheet.
  static Future<void> show(
    BuildContext context, {
    required String floorId,
    required String deviceId,
    required String deviceName,
    String? initialStart,
    String? initialEnd,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeviceScheduleBottomSheet(
        floorId: floorId,
        deviceId: deviceId,
        deviceName: deviceName,
        initialStart: initialStart,
        initialEnd: initialEnd,
      ),
    );
  }

  @override
  State<DeviceScheduleBottomSheet> createState() =>
      _DeviceScheduleBottomSheetState();
}

class _DeviceScheduleBottomSheetState
    extends State<DeviceScheduleBottomSheet> {
  final _service = FirestoreService();
  late TimeOfDay? _startTime;
  late TimeOfDay? _endTime;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _startTime = _parseTime(widget.initialStart);
    _endTime = _parseTime(widget.initialEnd);
  }

  /// Converts "HH:mm" → [TimeOfDay], returning null on any parse error.
  static TimeOfDay? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  /// Formats a [TimeOfDay] as a zero-padded "HH:mm" 24-hour string.
  static String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart
        ? (_startTime ?? const TimeOfDay(hour: 18, minute: 0))
        : (_endTime ?? const TimeOfDay(hour: 23, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.surface,
              hourMinuteColor: AppColors.background,
              hourMinuteTextColor: AppColors.textPrimary,
              dialBackgroundColor: AppColors.background,
              dialHandColor: AppColors.brass,
              dialTextColor: AppColors.textPrimary,
              entryModeIconColor: AppColors.textSecondary,
            ),
            colorScheme: ColorScheme.light(
              primary: AppColors.brass,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both ON and OFF times.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.updateDeviceSchedule(
        widget.floorId,
        widget.deviceId,
        _formatTime(_startTime!),
        _formatTime(_endTime!),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Schedule set: ${_formatTime(_startTime!)} → ${_formatTime(_endTime!)}',
            ),
            backgroundColor: AppColors.pine,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save schedule: $e'),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clear() async {
    setState(() => _saving = true);
    try {
      await _service.clearDeviceSchedule(widget.floorId, widget.deviceId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule cleared.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear schedule: $e'),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasExisting = widget.initialStart != null && widget.initialEnd != null;

    return Padding(
      // Push sheet up when the keyboard / time picker overlay is visible.
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.bottomSheet),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ──
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brass.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    color: AppColors.brass,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Set Schedule',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      widget.deviceName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Time pickers ──
            Row(
              children: [
                Expanded(
                  child: _TimePickerTile(
                    label: 'Turn ON',
                    icon: Icons.wb_sunny_outlined,
                    time: _startTime,
                    accentColor: AppColors.brass,
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimePickerTile(
                    label: 'Turn OFF',
                    icon: Icons.nights_stay_outlined,
                    time: _endTime,
                    accentColor: AppColors.pine,
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Duration hint ──
            if (_startTime != null && _endTime != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _DurationHint(start: _startTime!, end: _endTime!),
              ),

            const SizedBox(height: 16),

            // ── Save button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, color: Colors.white),
                label: Text(
                  _saving ? 'Saving…' : 'Save Schedule',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brass,
                  disabledBackgroundColor: AppColors.brass.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            // ── Clear button (only shown when a schedule already exists) ──
            if (hasExisting) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _clear,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColors.statusError,
                  ),
                  label: const Text(
                    'Clear Schedule',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.statusError,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: AppColors.statusError, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _TimePickerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final TimeOfDay? time;
  final Color accentColor;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.label,
    required this.icon,
    required this.time,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasTime = time != null;
    final timeStr = hasTime
        ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
        : '--:--';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: hasTime
              ? accentColor.withValues(alpha: 0.07)
              : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasTime
                ? accentColor.withValues(alpha: 0.40)
                : AppColors.divider,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 15,
                    color: hasTime ? accentColor : AppColors.textSecondary),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: hasTime ? accentColor : AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: hasTime ? AppColors.textPrimary : AppColors.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tap to change',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationHint extends StatelessWidget {
  final TimeOfDay start;
  final TimeOfDay end;

  const _DurationHint({required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    // Handle overnight schedules (end < start).
    final durationMinutes =
        endMinutes >= startMinutes
            ? endMinutes - startMinutes
            : (24 * 60 - startMinutes) + endMinutes;
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;

    final label = h > 0 && m > 0
        ? '${h}h ${m}m active'
        : h > 0
            ? '${h}h active'
            : '${m}m active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.brassPale,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 14, color: AppColors.brassDeep),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.brassDeep,
            ),
          ),
        ],
      ),
    );
  }
}
