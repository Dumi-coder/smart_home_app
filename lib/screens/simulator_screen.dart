import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/device.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class SimulatorScreen extends StatelessWidget {
  SimulatorScreen({super.key});

  final FirestoreService _service = FirestoreService();

  Color _statusColor(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.on:
        return AppColors.brass; // matches app theme signal color
      case DeviceStatus.off:
        return Colors.grey.shade400;
      case DeviceStatus.error:
        return Colors.redAccent;
      case DeviceStatus.disconnected:
        return Colors.orange.shade300;
    }
  }

  IconData _deviceIcon(String type) {
    switch (type) {
      case 'outlet':
        return Icons.power;
      case 'multiswitch':
        return Icons.dashboard_customize;
      case 'iron':
        return Icons.iron;
      case 'bulb':
        return Icons.lightbulb;
      case 'camera':
        return Icons.videocam;
      default:
        return Icons.device_unknown;
    }
  }

  Widget _deviceTile(Device device) {
    final color = _statusColor(device.status);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pineDeep,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.8), width: 2),
        boxShadow: device.status == DeviceStatus.on
            ? [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 12,
            spreadRadius: 1,
          )
        ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_deviceIcon(device.type), color: color, size: 32),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              device.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statusToString(device.status),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceGrid(List<Device> devices) {
    if (devices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'No devices in this group.',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: devices.length,
      itemBuilder: (context, i) => _deviceTile(devices[i]),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


  Widget _roomHeader(String room) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.meeting_room_outlined, color: Colors.white54, size: 16),
          const SizedBox(width: 6),
          Text(
            room,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Groups devices by their `room` field (falling back to "Unassigned"
  /// for devices with no room set) and renders one grid per room,
  /// each preceded by a room-name header.
  Widget _deviceGridByRoom(List<Device> devices) {
    if (devices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'No devices in this group.',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    final Map<String, List<Device>> byRoom = {};
    for (final device in devices) {
      final room = (device.room == null || device.room!.trim().isEmpty)
          ? 'Unassigned'
          : device.room!;
      byRoom.putIfAbsent(room, () => []).add(device);
    }

    final roomNames = byRoom.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: roomNames.map((room) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _roomHeader(room),
            _deviceGrid(byRoom[room]!),
          ],
        );
      }).toList(),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Hardware Simulator',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.streamFloors(),
        builder: (context, floorSnapshot) {
          if (!floorSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final floors = floorSnapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // ── Real floors ──
              ...floors.map((floorDoc) {
                final floorData = floorDoc.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(floorData['name'] ?? 'Unnamed Floor'),
                      const SizedBox(height: 8),
                      StreamBuilder<List<Device>>(
                        stream: _service.streamDevices(floorDoc.id),
                        builder: (context, deviceSnapshot) {
                          if (!deviceSnapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            );
                          }
                          return _deviceGridByRoom(deviceSnapshot.data!);
                        },
                      ),
                      const Divider(color: Colors.white24, height: 32),
                    ],
                  ),
                );
              }),

              // ── Exterior cameras (pseudo-floor, no floors doc) ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Exterior'),
                  const SizedBox(height: 8),
                  StreamBuilder<List<Device>>(
                    stream: _service.streamCamerasForGroup('exterior'),
                    builder: (context, camSnapshot) {
                      if (!camSnapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        );
                      }
                      return _deviceGridByRoom(camSnapshot.data!);
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}