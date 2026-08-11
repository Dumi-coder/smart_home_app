import 'package:flutter/material.dart';
import '../models/house_member.dart';
import '../theme/app_theme.dart';

class MemberTile extends StatelessWidget {
  final HouseMember member;

  const MemberTile({super.key, required this.member});

  Color get _roleColor {
    switch (member.role) {
      case 'Owner':
        return AppColors.primaryActiveDark;
      case 'Admin':
        return AppColors.accentCamera;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryActive.withValues(alpha: 0.25),
                child: Text(
                  member.name.isNotEmpty ? member.name[0] : '?',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              if (member.online)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.statusOn,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(
                  member.online ? 'Online' : 'Offline',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _roleColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              member.role,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _roleColor),
            ),
          ),
        ],
      ),
    );
  }
}
