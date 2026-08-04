import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/firestore_service.dart';

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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
              child: Text(
                device.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ...device.switches.map((s) => SwitchListTile(
              title: Text(s.label),
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
            )),
          ],
        ),
      ),
    );
  }
}