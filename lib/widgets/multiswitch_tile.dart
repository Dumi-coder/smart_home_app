import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class MultiSwitchTile extends StatelessWidget {
  final MultiSwitchDevice device;
  final FirestoreService service;

  const MultiSwitchTile({
    super.key,
    required this.device,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final onCount = device.switches.where((s) => s.state == true).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentMultiswitch.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.dashboard_customize_outlined,
                    size: 16, color: AppColors.accentMultiswitch),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  device.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                ),
              ),
              Text(
                '$onCount/${device.switches.length} on',
                style: AppFonts.mono(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const Divider(color: AppColors.divider, height: 18),
          ...device.switches.map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.label,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                      ),
                    ),
                    Switch(
                      value: s.state,
                      onChanged: (val) {
                        service.toggleSubSwitch(
                          device.floorId,
                          device.id,
                          device.switches,
                          s.id,
                          val,
                        );
                      },
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
