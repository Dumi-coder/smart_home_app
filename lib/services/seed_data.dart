import 'package:cloud_firestore/cloud_firestore.dart';

class SeedData {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> seedDatabase() async {
    // 1. Create a floor
    final floorRef = await _db.collection('floors').add({
      'name': 'Ground Floor',
      'gridWidth': 10,
      'gridHeight': 10,
      'imageUrl': '',
    });
    final floorId = floorRef.id;

    final devicesRef = _db.collection('floors').doc(floorId).collection('devices');

    // 2. Outlet
    await devicesRef.add({
      'name': 'Living Room Outlet',
      'type': 'outlet',
      'x': 1,
      'y': 1,
      'status': 'OFF',
    });

    // 3. Multi-switch (gang box with 3 switches)
    await devicesRef.add({
      'name': 'Hallway Switch Panel',
      'type': 'multiswitch',
      'x': 3,
      'y': 2,
      'status': 'ON',
      'switches': [
        {'id': 'sw1', 'label': 'Ceiling Light', 'state': true},
        {'id': 'sw2', 'label': 'Fan', 'state': false},
        {'id': 'sw3', 'label': 'Porch Light', 'state': false},
      ],
    });

    // 4. Iron (safety-critical, with max duration)
    await devicesRef.add({
      'name': 'Clothing Iron',
      'type': 'iron',
      'x': 5,
      'y': 4,
      'status': 'OFF',
      'maxOnDurationMinutes': 15,
      'turnedOnAt': null,
    });

    // 5. Bulb (schedulable)
    await devicesRef.add({
      'name': 'Garden Bulb',
      'type': 'bulb',
      'x': 7,
      'y': 6,
      'status': 'OFF',
      'scheduleStart': '18:00',
      'scheduleEnd': '23:00',
    });

    // 6. Camera
    await devicesRef.add({
      'name': 'Front Door Camera',
      'type': 'camera',
      'x': 0,
      'y': 0,
      'status': 'ON',
      'snapshotUrl': 'https://picsum.photos/400/300',
    });

    // 7. A sample usage log
    await _db.collection('usageLogs').add({
      'deviceId': 'sample',
      'floorId': floorId,
      'event': 'ON',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 8. A sample alert
    await _db.collection('alerts').add({
      'deviceId': 'sample',
      'message': 'Iron auto-shutoff after exceeding max duration',
      'timestamp': FieldValue.serverTimestamp(),
      'acknowledged': false,
    });
  }
}