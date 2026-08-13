import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Maps device `type` strings to icons and accent colors.
class DeviceIcons {
  DeviceIcons._();

  static IconData iconFor(String type) {
    switch (type) {
      case 'bulb':
        return Icons.lightbulb_outline;
      case 'outlet':
        return Icons.power_outlined;
      case 'multiswitch':
        return Icons.toggle_on_outlined;
      case 'iron':
        return Icons.iron_outlined;
      case 'camera':
      case 'fan':
        return Icons.air;
      case 'ac':
        return Icons.ac_unit;
      default:
        return Icons.devices_other;
    }
  }

  static Color accentFor(String type) {
    switch (type) {
      case 'bulb':
        return AppColors.accentBulb;
      case 'outlet':
        return AppColors.accentOutlet;
      case 'MULTI_SWITCH':
        return AppColors.accentMultiswitch;
      case 'iron':
        return AppColors.accentIron;
      case 'camera':
      case 'fan':
        return AppColors.accentBulb; // Reusing an accent for now
      case 'ac':
        return AppColors.primaryActive; // Reusing an accent for now
      default:
        return AppColors.statusOff;
    }
  }

  /// A human-readable label for the device type.
  static String labelFor(String type) {
    switch (type) {
      case 'bulb':
        return 'Light';
      case 'outlet':
        return 'Outlet';
      case 'multiswitch':
        return 'Switch';
      case 'iron':
        return 'Iron';
      case 'camera':
      case 'fan':
        return 'Fan';
      case 'ac':
        return 'AC';
      default:
        return 'Device';
    }
  }

  /// Returns a brief sub-status string for device-type-specific metadata.
  /// Falls back to null if no meaningful sub-status is available.
  static String? subStatusFor(dynamic device) {
    // Import-free check using runtime type name to avoid circular imports.
    final typeName = device.runtimeType.toString();

    if (typeName == 'IronDevice') {
      return 'Max ${device.maxOnDurationMinutes}m';
    }
    if (typeName == 'BulbDevice') {
      if (device.scheduleStart != null && device.scheduleEnd != null) {
        return '${device.scheduleStart} – ${device.scheduleEnd}';
      }
    }
    if (typeName == 'MultiSwitchDevice') {
      // Sub-status is handled within the MultiSwitchTile itself
      return null;
    }
    return null;
  }
}
