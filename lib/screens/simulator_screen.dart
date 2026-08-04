import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/device.dart';
import '../services/firestore_service.dart';

class SimulatorScreen extends StatelessWidget {
  SimulatorScreen({super.key});

  final FirestoreService _service = FirestoreService();

  Color _statusColor(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.on:
        return const Color(0xFFD4E157); // lime green, matches app theme
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // dark "hardware panel" look
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
          if (floors.isEmpty) {
            return const Center(
              child: Text(
                'No floors to simulate yet.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }
          return ListView.builder(
            itemCount: floors.length,
            itemBuilder: (context, floorIndex) {
              final floorDoc = floors[floorIndex];
              final floorData = floorDoc.data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      floorData['name'] ?? 'Unnamed Floor',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                        final devices = deviceSnapshot.data!;
                        if (devices.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'No devices on this floor.',
                              style: TextStyle(color: Colors.white38),
                            ),
                          );
                        }
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: devices.length,
                          itemBuilder: (context, i) {
                            final device = devices[i];
                            final color = _statusColor(device.status);
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF262626),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: color.withOpacity(0.8),
                                  width: 2,
                                ),
                                boxShadow: device.status == DeviceStatus.on
                                    ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  )
                                ]
                                    : [],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _deviceIcon(device.type),
                                    color: color,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: Text(
                                      device.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
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
                          },
                        );
                      },
                    ),
                    const Divider(color: Colors.white24, height: 32),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}