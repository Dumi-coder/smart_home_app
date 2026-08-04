import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A single room chip for horizontal scroll selection.
class RoomChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const RoomChip({
    super.key,
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.chipSelected : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: isSelected
              ? null
              : Border.all(color: AppColors.divider, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? AppColors.primaryActive : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns an appropriate icon for a room name.
  static IconData iconForRoom(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('living')) return Icons.weekend_outlined;
    if (lower.contains('kitchen')) return Icons.kitchen_outlined;
    if (lower.contains('bed')) return Icons.bed_outlined;
    if (lower.contains('bath')) return Icons.bathtub_outlined;
    if (lower.contains('hall')) return Icons.meeting_room_outlined;
    if (lower.contains('office') || lower.contains('study')) {
      return Icons.computer_outlined;
    }
    if (lower.contains('garage')) return Icons.garage_outlined;
    return Icons.room_outlined;
  }
}
