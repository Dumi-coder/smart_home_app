import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class MultiSwitchTile extends StatefulWidget {
  final MultiSwitchDevice device;
  final FirestoreService service;

  const MultiSwitchTile({
    super.key,
    required this.device,
    required this.service,
  });

  @override
  State<MultiSwitchTile> createState() => _MultiSwitchTileState();
}

class _MultiSwitchTileState extends State<MultiSwitchTile> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChildSwitch>>(
      stream: widget.service.streamChildSwitches(widget.device.floorId, widget.device.id),
      builder: (context, snapshot) {
        final switches = snapshot.data ?? [];
        final onCount = switches.where((s) => s.status == 'ON').length;
        final channelCount = switches.length;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              // Header
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: _expanded
                    ? const BorderRadius.vertical(top: Radius.circular(AppRadius.card))
                    : BorderRadius.circular(AppRadius.card),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentMultiswitch.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.dashboard_customize_outlined,
                            size: 20, color: AppColors.accentMultiswitch),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.device.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Multi-Switch • $channelCount Channels',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$onCount/$channelCount on',
                        style: AppFonts.mono(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Expanded content
              if (_expanded) ...[
                const Divider(color: AppColors.divider, height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    children: [
                      if (snapshot.hasError)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Error loading channels: ${snapshot.error}',
                            style: const TextStyle(color: AppColors.statusError, fontSize: 13),
                          ),
                        ),
                      if (switches.isEmpty && snapshot.connectionState != ConnectionState.waiting && !snapshot.hasError)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No channels configured.', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      ...switches.map((s) {
                        final isError = s.status == 'ERROR';
                        final isDisconnected = s.status == 'DISCONNECTED';
                        final isOn = s.status == 'ON';
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Text(
                                '${s.switchNumber}',
                                style: AppFonts.mono(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                isOn ? Icons.lightbulb : Icons.lightbulb_outline,
                                size: 16,
                                color: isOn ? AppColors.accentMultiswitch : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.name,
                                      style: TextStyle(
                                        fontSize: 14, 
                                        fontWeight: FontWeight.w500, 
                                        color: isError ? AppColors.statusError : AppColors.textPrimary,
                                        decoration: !s.enabled ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    if (s.connectedDeviceName != null && s.connectedDeviceName != s.name)
                                      Text(
                                        '→ ${s.connectedDeviceName}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isError || isDisconnected)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text(
                                    s.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isError ? AppColors.statusError : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              Switch(
                                value: isOn,
                                activeColor: AppColors.accentMultiswitch,
                                onChanged: (s.enabled && !isError && !isDisconnected)
                                    ? (val) {
                                        widget.service.toggleSubSwitch(
                                          widget.device.floorId,
                                          widget.device.id,
                                          s.id,
                                          val,
                                        );
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      // Device Settings Button
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Device Settings'),
                                content: const Text('Are you sure you want to delete this Multi-Switch panel?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await widget.service.deleteDevice(
                                        widget.device.floorId,
                                        widget.device.id,
                                      );
                                      if (ctx.mounted) Navigator.pop(ctx);
                                    },
                                    child: const Text('Delete', style: TextStyle(color: AppColors.statusError)),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.settings, size: 16, color: AppColors.textSecondary),
                          label: const Text(
                            'Device Settings',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

