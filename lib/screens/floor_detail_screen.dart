import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/firestore_service.dart';

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

  Color _statusColor(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.on:
        return Colors.green;
      case DeviceStatus.off:
        return Colors.grey;
      case DeviceStatus.error:
        return Colors.red;
      case DeviceStatus.disconnected:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(floorName)),
      body: StreamBuilder<List<Device>>(
        stream: _service.streamDevices(floorId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final devices = snapshot.data!;
          if (devices.isEmpty) {
            return const Center(child: Text('No devices yet. Tap + to add one.'));
          }
          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Icon(Icons.power, color: _statusColor(device.status)),
                  title: Text(device.name),
                  subtitle: Text('${device.type} • ${statusToString(device.status)}'),
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
        child: const Icon(Icons.add),
      ),
    );
  }
}