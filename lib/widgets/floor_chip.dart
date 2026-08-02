import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A single floor chip for horizontal scroll selection.
class FloorChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const FloorChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.chipSelected : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: isSelected
              ? null
              : Border.all(color: AppColors.divider, width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.chipSelected.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primaryActive : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
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

  /// Returns an appropriate icon for a floor name.
  static IconData iconForFloor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ground')) return Icons.home_outlined;
    if (lower.contains('garage')) return Icons.directions_car_outlined;
    if (lower.contains('garden')) return Icons.park_outlined;
    if (lower.contains('roof') || lower.contains('terrace')) {
      return Icons.roofing_outlined;
    }
    if (lower.contains('basement')) return Icons.foundation_outlined;
    return Icons.grid_view_outlined;
  }
}
