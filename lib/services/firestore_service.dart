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
}