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
      'room': 'Living Room',
    });

    // 3. Multi-switch (gang box with 3 switches)
    await devicesRef.add({
      'name': 'Hallway Switch Panel',
      'type': 'multiswitch',
      'x': 3,
      'y': 2,
      'status': 'ON',
      'room': 'Living Room',
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
      'room': 'Bedroom',
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
      'room': 'Kitchen',
      'scheduleStart': '18:00',
      'scheduleEnd': '23:00',
    });

    // 6. Indoor camera, attached to the Ground Floor
    await devicesRef.add({
      'name': 'Kitchen Camera',
      'type': 'camera',
      'x': 0,
      'y': 0,
      'status': 'ON',
      'room': 'Kitchen',
      'snapshotUrl': 'https://picsum.photos/seed/kitchencam/800/450',
    });

    // 7. Exterior cameras — live under floors/exterior/devices, a
    // pseudo-floor with no floor document, so it never shows up as a
    // floor tab on the Home screen, only in the Camera tab's pill list.
    final exteriorRef =
        _db.collection('floors').doc('exterior').collection('devices');

    await exteriorRef.add({
      'name': 'Entrance',
      'type': 'camera',
      'x': 0,
      'y': 0,
      'status': 'ON',
      'room': 'Exterior · Front Door',
      'snapshotUrl': 'https://picsum.photos/seed/entrancecam/800/450',
    });
    await exteriorRef.add({
      'name': 'Backyard',
      'type': 'camera',
      'x': 0,
      'y': 0,
      'status': 'ON',
      'room': 'Exterior · Backyard',
      'snapshotUrl': 'https://picsum.photos/seed/backyardcam/800/450',
    });
    await exteriorRef.add({
      'name': 'Driveway',
      'type': 'camera',
      'x': 0,
      'y': 0,
      'status': 'ON',
      'room': 'Exterior · Driveway',
      'snapshotUrl': 'https://picsum.photos/seed/drivewaycam/800/450',
    });

    // 8. A sample usage log
    await _db.collection('usageLogs').add({
      'deviceId': 'sample',
      'floorId': floorId,
      'event': 'ON',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 9. Notifications / alerts — matches the Figma notification list.
    final now = DateTime.now();
    await _db.collection('alerts').add({
      'title': 'Smoke Detected',
      'message':
          'Smoke sensor triggered in the Kitchen. All appliances have been switched off automatically.',
      'severity': 'critical',
      'room': 'Kitchen',
      'icon': 'smoke',
      'timestamp': Timestamp.fromDate(now.subtract(const Duration(minutes: 2))),
      'acknowledged': false,
    });
    await _db.collection('alerts').add({
      'title': 'Iron Auto-Off',
      'message':
          'Clothing iron exceeded the 15-minute safety limit and was turned OFF by the system.',
      'severity': 'warning',
      'room': 'Bedroom',
      'icon': 'power',
      'timestamp': Timestamp.fromDate(now.subtract(const Duration(minutes: 18))),
      'acknowledged': false,
    });
    await _db.collection('alerts').add({
      'title': 'Motion Detected',
      'message':
          'Unexpected motion detected near the Front Door. Camera recording has started.',
      'severity': 'critical',
      'room': 'Entrance',
      'icon': 'motion',
      'timestamp': Timestamp.fromDate(now.subtract(const Duration(minutes: 34))),
      'acknowledged': false,
    });
    await _db.collection('alerts').add({
      'title': 'Front Door Unlocked',
      'message': 'The front door was unlocked remotely by Alex at 09:14 AM.',
      'severity': 'info',
      'room': 'Entrance',
      'icon': 'lock',
      'timestamp': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
      'acknowledged': true,
    });
    await _db.collection('alerts').add({
      'title': 'Wi-Fi Signal Weak',
      'message': 'Hallway Switch Panel is reporting a weak Wi-Fi signal.',
      'severity': 'warning',
      'room': 'Living Room',
      'icon': 'wifi',
      'timestamp': Timestamp.fromDate(now.subtract(const Duration(hours: 5))),
      'acknowledged': true,
    });

    // 10. Energy usage — ~30 days of readings across rooms/devices so the
    // Analysis screen has real data to aggregate (today / week / month /
    // room comparison / top consumers).
    final rooms = <String, List<String>>{
      'Living Room': ['Air Conditioner', 'TV', 'Hallway Switch Panel'],
      'Kitchen': ['Fridge', 'Kitchen Camera', 'Garden Bulb'],
      'Bedroom': ['Clothing Iron', 'Bedroom AC'],
      'Bathroom': ['Water Heater'],
      'Garage': ['EV Charger'],
    };
    // Roughly matches the Figma room-comparison split: Living 34%,
    // Kitchen 28%, Bedroom 22%, Bathroom 10%, Garage 6%.
    final roomWeights = <String, double>{
      'Living Room': 0.34,
      'Kitchen': 0.28,
      'Bedroom': 0.22,
      'Bathroom': 0.10,
      'Garage': 0.06,
    };

    final batch = _db.batch();
    final energyRef = _db.collection('energyUsage');
    for (int daysAgo = 29; daysAgo >= 0; daysAgo--) {
      final date = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: daysAgo));
      // Slight weekly wave so the weekly bar chart isn't flat.
      final weekdayFactor = 0.85 + (date.weekday % 7) * 0.05;
      for (final room in rooms.keys) {
        final devices = rooms[room]!;
        final roomDailyTotal = 6.0 * roomWeights[room]! * weekdayFactor;
        for (final device in devices) {
          final share = roomDailyTotal / devices.length;
          final doc = energyRef.doc();
          batch.set(doc, {
            'date': Timestamp.fromDate(date),
            'room': room,
            'device': device,
            'kWh': double.parse(share.toStringAsFixed(2)),
          });
        }
      }
    }
    await batch.commit();

    // 11. House members
    await _db.collection('houseMembers').add({
      'name': 'Alex Morgan',
      'email': 'alex.morgan@email.com',
      'role': 'Owner',
      'online': true,
      'avatarUrl': '',
    });
    await _db.collection('houseMembers').add({
      'name': 'Jamie Lee',
      'email': 'jamie.lee@email.com',
      'role': 'Admin',
      'online': true,
      'avatarUrl': '',
    });
    await _db.collection('houseMembers').add({
      'name': 'Sam Rivera',
      'email': 'sam.rivera@email.com',
      'role': 'Guest',
      'online': false,
      'avatarUrl': '',
    });

    // 12. Scenes (just used for the Profile screen's "Scenes" stat)
    await _db.collection('scenes').add({'name': 'Good Morning'});
    await _db.collection('scenes').add({'name': 'Movie Night'});
    await _db.collection('scenes').add({'name': 'Away Mode'});
    await _db.collection('scenes').add({'name': 'Bedtime'});

    // 13. Default preferences
    await _db.collection('settings').doc('preferences').set({
      'darkMode': false,
      'pushNotifications': true,
      'firebaseSync': true,
    });
  }
}
