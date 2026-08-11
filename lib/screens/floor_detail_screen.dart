import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/multiswitch_tile.dart';

class FloorDetailScreen extends StatelessWidget {
  final String floorId;
  final String floorName;

  FloorDetailScreen({super.key, required this.floorId, required this.floorName});

  final FirestoreService _service = FirestoreService();

  void _addOutletDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Outlet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Device name (e.g. Living Room Outlet)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final device = OutletDevice(
                  id: '',
                  floorId: floorId,
                  name: controller.text.trim(),
                  x: 0,
                  y: 0,
                  status: DeviceStatus.off,
                );
                await _service.addDevice(floorId, device);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(DeviceStatus status) => AppColors.colorForStatus(statusToString(status));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(floorName)),
      body: StreamBuilder<List<Device>>(
        stream: _service.streamDevices(floorId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.brass),
            );
          }
          final devices = snapshot.data!;
          if (devices.isEmpty) {
            return const Center(
              child: Text(
                'No devices yet. Tap + to add one.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];

              if (device is MultiSwitchDevice) {
                return MultiSwitchTile(device: device, service: _service);
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.divider, width: 1),
                  boxShadow: const [
                    BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _statusColor(device.status).withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.power, color: _statusColor(device.status), size: 18),
                  ),
                  title: Text(
                    device.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    '${device.type} · ${statusToString(device.status)}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                  ),
                  trailing: (device is OutletDevice)
                      ? Switch(
                          value: device.status == DeviceStatus.on,
                          onChanged: (val) {
                            _service.toggleDevice(floorId, device.id, val);
                          },
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOutletDialog(context),
        backgroundColor: AppColors.brass,
        foregroundColor: AppColors.ink,
        child: const Icon(Icons.add),
      ),
    );
  }
}