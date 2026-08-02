import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/device.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------- Floors ----------------

  /// Stream of all floors, live-updating.
  Stream<QuerySnapshot> streamFloors() {
    return _db.collection('floors').snapshots();
  }

  Future<void> addFloor({
    required String name,
    int gridWidth = 10,
    int gridHeight = 10,
    String imageUrl = '',
  }) async {
    await _db.collection('floors').add({
      'name': name,
      'gridWidth': gridWidth,
      'gridHeight': gridHeight,
      'imageUrl': imageUrl,
    });
  }

  Future<void> deleteFloor(String floorId) async {
    await _db.collection('floors').doc(floorId).delete();
  }

  // ---------------- Devices ----------------

  /// Stream of devices for a given floor, parsed into typed Device objects.
  Stream<List<Device>> streamDevices(String floorId) {
    return _db
        .collection('floors')
        .doc(floorId)
        .collection('devices')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Device.fromFirestore(floorId, doc))
        .toList());
  }

  Future<void> addDevice(String floorId, Device device) async {
    await _db
        .collection('floors')
        .doc(floorId)
        .collection('devices')
        .add(device.toMap());
  }

  Future<void> updateDeviceStatus(
      String floorId, String deviceId, DeviceStatus status) async {
    await _db
        .collection('floors')
        .doc(floorId)
        .collection('devices')
        .doc(deviceId)
        .update({'status': statusToString(status)});
  }

  /// Toggle a simple ON/OFF device (outlet, bulb). Also stamps turnedOnAt
  /// for devices that need duration tracking (e.g. iron) when turning ON.
  Future<void> toggleDevice(
      String floorId, String deviceId, bool turnOn) async {
    final ref = _db
        .collection('floors')
        .doc(floorId)
        .collection('devices')
        .doc(deviceId);

    final updates = <String, dynamic>{
      'status': turnOn ? 'ON' : 'OFF',
    };

    if (turnOn) {
      updates['turnedOnAt'] = FieldValue.serverTimestamp();
    } else {
      updates['turnedOnAt'] = null;
    }

    await ref.update(updates);

    // Log usage event.
    await _db.collection('usageLogs').add({
      'deviceId': deviceId,
      'floorId': floorId,
      'event': turnOn ? 'ON' : 'OFF',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Toggle a single switch within a multi-switch unit.
  Future<void> toggleSubSwitch(String floorId, String deviceId,
      List<SwitchItem> switches, String switchId, bool newState) async {
    final updatedSwitches = switches.map((s) {
      if (s.id == switchId) {
        return SwitchItem(id: s.id, label: s.label, state: newState);
      }
      return s;
    }).toList();

    await _db
        .collection('floors')
        .doc(floorId)
        .collection('devices')
        .doc(deviceId)
        .update({'switches': updatedSwitches.map((s) => s.toMap()).toList()});
  }

  // ---------------- Usage logs / reporting ----------------

  Stream<QuerySnapshot> streamUsageLogs(String deviceId) {
    return _db
        .collection('usageLogs')
        .where('deviceId', isEqualTo: deviceId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ---------------- Alerts ----------------

  Stream<QuerySnapshot> streamAlerts() {
    return _db
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ────────────────────────────────────────────────
  //  NEW: helpers added for the Home Screen redesign
  // ────────────────────────────────────────────────

  /// Stream of ALL devices across every floor.
  /// Fetches floors first, then merges device streams.
  Stream<List<Device>> streamAllDevices() {
    return _db.collection('floors').snapshots().asyncExpand((floorsSnap) {
      if (floorsSnap.docs.isEmpty) return Stream.value(<Device>[]);

      final streams = floorsSnap.docs.map((floorDoc) {
        return _db
            .collection('floors')
            .doc(floorDoc.id)
            .collection('devices')
            .snapshots()
            .map((snap) => snap.docs
                .map((d) => Device.fromFirestore(floorDoc.id, d))
                .toList());
      }).toList();

      // Combine all per-floor streams into one merged list.
      return _combineStreams(streams);
    });
  }

  /// Combine multiple device-list streams into a single stream.
  Stream<List<Device>> _combineStreams(List<Stream<List<Device>>> streams) {
    if (streams.isEmpty) return Stream.value([]);
    if (streams.length == 1) return streams.first;

    final latestValues = List<List<Device>?>.filled(streams.length, null);
    // ignore: close_sinks
    final controller = StreamController<List<Device>>.broadcast();
    final subscriptions = <StreamSubscription>[];

    for (int i = 0; i < streams.length; i++) {
      final index = i;
      subscriptions.add(streams[index].listen((data) {
        latestValues[index] = data;
        // Emit combined list once every stream has delivered at least once.
        if (latestValues.every((v) => v != null)) {
          controller
              .add(latestValues.expand((v) => v!).toList());
        }
      }));
    }

    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
    };

    return controller.stream;
  }

  /// Count of alerts where acknowledged == false.
  Stream<int> streamUnacknowledgedAlertCount() {
    return _db
        .collection('alerts')
        .where('acknowledged', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Batch-toggle all devices of a given type (e.g. 'bulb') across all floors.
  Future<void> toggleAllDevicesByType(String type, bool turnOn) async {
    final floorsSnap = await _db.collection('floors').get();
    final batch = _db.batch();

    for (final floor in floorsSnap.docs) {
      final devicesSnap = await _db
          .collection('floors')
          .doc(floor.id)
          .collection('devices')
          .where('type', isEqualTo: type)
          .get();
      for (final dev in devicesSnap.docs) {
        batch.update(dev.reference, {
          'status': turnOn ? 'ON' : 'OFF',
          'turnedOnAt': turnOn ? FieldValue.serverTimestamp() : null,
        });
      }
    }
    await batch.commit();
  }

  /// Turn OFF every device on every floor.
  Future<void> turnOffAllDevices() async {
    final floorsSnap = await _db.collection('floors').get();
    final batch = _db.batch();

    for (final floor in floorsSnap.docs) {
      final devicesSnap = await _db
          .collection('floors')
          .doc(floor.id)
          .collection('devices')
          .get();
      for (final dev in devicesSnap.docs) {
        batch.update(dev.reference, {
          'status': 'OFF',
          'turnedOnAt': null,
        });
      }
    }
    await batch.commit();
  }
}