import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/device.dart';
import '../models/notification_alert.dart';
import '../models/house_member.dart';
import '../models/energy_reading.dart';

/// Single access point for all Firestore reads/writes — screens never
/// talk to Firestore directly, they go through this service.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Stream caches to prevent duplicate Firestore listeners ──
  // We cache the raw `snapshots()` streams because Firestore natively
  // replays the latest value to new listeners. We then apply `.map()`
  // on demand so the UI updates instantly when switching views.
  final Map<String, Stream<QuerySnapshot>> _rawDeviceStreamCache = {};
  final Map<String, Stream<QuerySnapshot>> _roomStreamCache = {};
  Stream<List<Device>>? _allDevicesStream;
  Stream<QuerySnapshot>? _floorsStream;
  Stream<QuerySnapshot>? _unackAlertsRawStream;
  Stream<DocumentSnapshot>? _profileStream;
  Stream<DocumentSnapshot>? _preferencesStream;
  Stream<QuerySnapshot>? _notificationAlertsRawStream;
  Stream<QuerySnapshot>? _energyUsageRawStream;
  Stream<QuerySnapshot>? _houseMembersRawStream;
  Stream<QuerySnapshot>? _scenesRawStream;

  // ---------------- Floors ----------------

  /// Stream of all floors, live-updating (cached).
  Stream<QuerySnapshot> streamFloors() {
    _floorsStream ??= _db.collection('floors').snapshots();
    return _floorsStream!;
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

  Future<void> updateFloor(String floorId, String newName, {
    int? gridWidth,
    int? gridHeight,
    String? imageUrl,
  }) async {
    final updates = <String, dynamic>{'name': newName};
    if (gridWidth != null) updates['gridWidth'] = gridWidth;
    if (gridHeight != null) updates['gridHeight'] = gridHeight;
    if (imageUrl != null) updates['imageUrl'] = imageUrl;
    await _db.collection('floors').doc(floorId).update(updates);
  }

  Future<void> deleteFloor(String floorId) async {
    await _db.collection('floors').doc(floorId).delete();
  }

  // ---------------- Rooms ----------------

  Stream<QuerySnapshot> streamRooms(String floorId) {
    return _roomStreamCache.putIfAbsent(
      floorId,
      () => _db.collection('floors').doc(floorId).collection('rooms').snapshots(),
    );
  }

  Future<void> addRoom(String floorId, String name) async {
    await _db.collection('floors').doc(floorId).collection('rooms').add({'name': name});
  }

  Future<void> updateRoom(String floorId, String roomId, String newName) async {
    await _db.collection('floors').doc(floorId).collection('rooms').doc(roomId).update({'name': newName});
  }

  Future<void> deleteRoom(String floorId, String roomId) async {
    await _db.collection('floors').doc(floorId).collection('rooms').doc(roomId).delete();
  }

  // ---------------- Devices ----------------

  /// Stream of devices for a given floor, parsed into typed Device objects.
  Stream<List<Device>> streamDevices(String floorId) {
    final rawStream = _rawDeviceStreamCache.putIfAbsent(
      floorId,
      () => _db
          .collection('floors')
          .doc(floorId)
          .collection('devices')
          .snapshots(),
    );
    
    return rawStream.map((snapshot) => snapshot.docs
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

  Future<void> addDeviceRaw(String floorId, Map<String, dynamic> data) async {
    await _db
        .collection('floors')
        .doc(floorId)
        .collection('devices')
        .add(data);
  }

  Future<void> updateDevice(String floorId, String deviceId, Map<String, dynamic> updates) async {
    await _db
        .collection('floors')
        .doc(floorId)
        .collection('devices')
        .doc(deviceId)
        .update(updates);
  }

  Future<void> deleteDevice(String floorId, String deviceId) async {
    await _db
        .collection('floors')
        .doc(floorId)
        .collection('devices')
        .doc(deviceId)
        .delete();
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

  Stream<List<ChildSwitch>> streamChildSwitches(String floorId, String deviceId) {
    return _db
        .collection('floors')
        .doc(floorId)
        .collection('devices')
        .doc(deviceId)
        .collection('switches')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChildSwitch.fromFirestore(doc))
            .toList());
  }

/// Updates one channel of a multi-switch and recomputes the parent
/// device's aggregate status (ERROR > DISCONNECTED > ON > OFF).
  Future<void> toggleSubSwitch(
      String floorId, String deviceId, String switchId, bool turnOn) async {
    final ref = _db
        .collection('floors')
        .doc(floorId)
        .collection('devices')
        .doc(deviceId)
        .collection('switches')
        .doc(switchId);

    await ref.update({
      'status': turnOn ? 'ON' : 'OFF',
      'updated_at': FieldValue.serverTimestamp(),
    });

    // Log usage event for the specific switch.
    await _db.collection('usageLogs').add({
      'deviceId': switchId, // specific switch ID
      'floorId': floorId,
      'event': turnOn ? 'ON' : 'OFF',
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    // We should also recalculate parent status if possible, 
    // but the instruction says "For a multi-switch panel, calculate the parent status logically from its child switches where appropriate."
    // Let's do a quick recalculation of parent status.
    final switchesSnap = await _db
        .collection('floors')
        .doc(floorId)
        .collection('devices')
        .doc(deviceId)
        .collection('switches')
        .get();
        
    int onCount = 0;
    int total = switchesSnap.docs.length;
    for (var doc in switchesSnap.docs) {
      if (doc.data()['status'] == 'ON') onCount++;
    }
    
    String parentStatus = 'OFF';
    if (onCount > 0 && onCount < total) {
      parentStatus = 'ON'; // Or we could use a custom status, but we must preserve ON/OFF.
    } else if (onCount == total && total > 0) {
      parentStatus = 'ON';
    }
    
    await updateDeviceStatus(floorId, deviceId, statusFromString(parentStatus));
  }

  /// Update an arbitrary status for a child switch (e.g. for ERROR/DISCONNECTED simulation).
  Future<void> updateChildSwitchStatus(
      String floorId, String deviceId, String switchId, String status) async {
    final ref = _db
        .collection('floors')
        .doc(floorId)
        .collection('devices')
        .doc(deviceId)
        .collection('switches')
        .doc(switchId);

    await ref.update({
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    });

    // Recalculate parent status
    final switchesSnap = await _db
        .collection('floors')
        .doc(floorId)
        .collection('devices')
        .doc(deviceId)
        .collection('switches')
        .get();
        
    int onCount = 0;
    int errorCount = 0;
    int disconnectedCount = 0;
    int total = switchesSnap.docs.length;
    
    for (var doc in switchesSnap.docs) {
      final s = doc.data()['status'];
      if (s == 'ON') onCount++;
      if (s == 'ERROR') errorCount++;
      if (s == 'DISCONNECTED') disconnectedCount++;
    }
    
    String parentStatus = 'OFF';
    if (errorCount > 0) {
      parentStatus = 'ERROR';
    } else if (disconnectedCount == total && total > 0) {
      parentStatus = 'DISCONNECTED';
    } else if (onCount > 0) {
      parentStatus = 'ON';
    }
    
    await updateDeviceStatus(floorId, deviceId, statusFromString(parentStatus));
  }

  /// Create a MULTI_SWITCH with a set of child switches.
  Future<void> addMultiSwitch(
    String floorId, 
    Device device, 
    int numSwitches, 
    List<String> switchNames
  ) async {
    final devRef = await _db
        .collection('floors')
        .doc(floorId)
        .collection('devices')
        .add(device.toMap());
        
    final switchesRef = devRef.collection('switches');
    final batch = _db.batch();
    
    for (int i = 0; i < numSwitches; i++) {
      final docRef = switchesRef.doc();
      batch.set(docRef, {
        'device_id': devRef.id,
        'switch_number': i + 1,
        'name': i < switchNames.length ? switchNames[i] : 'Switch ${i + 1}',
        'status': 'OFF',
        'enabled': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Create a MULTI_SWITCH and link each channel to an existing device by ID.
  /// [channelDeviceIds] maps channel index → device ID (nullable if unassigned).
  Future<void> addMultiSwitchWithDevices(
    String floorId,
    Device device,
    int numSwitches,
    List<String?> channelDeviceIds,
  ) async {
    // First, look up the names of the selected devices
    final devicesCol = _db.collection('floors').doc(floorId).collection('devices');

    // Create the parent multi-switch document
    final devRef = await devicesCol.add(device.toMap());

    final switchesRef = devRef.collection('switches');
    final batch = _db.batch();

    for (int i = 0; i < numSwitches; i++) {
      final deviceId = i < channelDeviceIds.length ? channelDeviceIds[i] : null;
      String channelName = 'Switch ${i + 1}';
      String? connectedDeviceId;
      String? connectedDeviceName;

      // If a device was assigned, look up its name
      if (deviceId != null) {
        final deviceDoc = await devicesCol.doc(deviceId).get();
        if (deviceDoc.exists) {
          final data = deviceDoc.data() as Map<String, dynamic>;
          channelName = data['name'] ?? 'Switch ${i + 1}';
          connectedDeviceId = deviceId;
          connectedDeviceName = channelName;
        }
      }

      final docRef = switchesRef.doc();
      batch.set(docRef, {
        'device_id': devRef.id,
        'switch_number': i + 1,
        'name': channelName,
        'status': 'OFF',
        'enabled': true,
        if (connectedDeviceId != null) 'connected_device_id': connectedDeviceId,
        if (connectedDeviceName != null) 'connected_device_name': connectedDeviceName,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // ---------------- Usage logs / reporting ----------------

  Stream<QuerySnapshot> streamUsageLogs(String deviceId) {
    // Usage logs are per-device and rarely shared, no cache needed.
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

  /// Invalidate all cached streams. Call this if the underlying data
  /// structure changes (e.g. a floor is added/deleted) so new listeners
  /// are created on next access.
  void invalidateCache() {
    _rawDeviceStreamCache.clear();
    _roomStreamCache.clear();
    _allDevicesStream = null;
    _floorsStream = null;
    _unackAlertsRawStream = null;
    _profileStream = null;
    _preferencesStream = null;
    _notificationAlertsRawStream = null;
    _energyUsageRawStream = null;
    _houseMembersRawStream = null;
    _scenesRawStream = null;
  }

  // ────────────────────────────────────────────────
  //  NEW: helpers added for the Home Screen redesign
  // ────────────────────────────────────────────────

  /// Stream of ALL devices across every floor (cached).
  /// Uses a stable approach: listens to floors once, then maintains
  /// per-floor device subscriptions without tearing them down on every
  /// floors emission.
  Stream<List<Device>> streamAllDevices() {
    _allDevicesStream ??= _createAllDevicesStream();
    return _allDevicesStream!;
  }

  Stream<List<Device>> _createAllDevicesStream() {
    final controller = StreamController<List<Device>>.broadcast();
    final Map<String, List<Device>> floorDevices = {};
    final Map<String, StreamSubscription> floorSubs = {};
    StreamSubscription<QuerySnapshot>? floorsSub;

    void emit() {
      controller.add(floorDevices.values.expand((v) => v).toList());
    }

    floorsSub = _db.collection('floors').snapshots().listen((floorsSnap) {
      final currentFloorIds = floorsSnap.docs.map((d) => d.id).toSet();

      // Remove subscriptions for deleted floors.
      final removedIds = floorSubs.keys.toSet().difference(currentFloorIds);
      for (final id in removedIds) {
        floorSubs[id]?.cancel();
        floorSubs.remove(id);
        floorDevices.remove(id);
      }

      // Add subscriptions for new floors.
      for (final floorDoc in floorsSnap.docs) {
        final fid = floorDoc.id;
        if (!floorSubs.containsKey(fid)) {
          floorSubs[fid] = _db
              .collection('floors')
              .doc(fid)
              .collection('devices')
              .snapshots()
              .listen((devSnap) {
            floorDevices[fid] = devSnap.docs
                .map((d) => Device.fromFirestore(fid, d))
                .toList();
            emit();
          });
        }
      }

      // If floors were removed, re-emit.
      if (removedIds.isNotEmpty) emit();
    });

    controller.onCancel = () {
      floorsSub?.cancel();
      for (final sub in floorSubs.values) {
        sub.cancel();
      }
      floorSubs.clear();
      floorDevices.clear();
    };

    return controller.stream;
  }

  /// Count of alerts where acknowledged == false.
  Stream<int> streamUnacknowledgedAlertCount() {
    _unackAlertsRawStream ??= _db
        .collection('alerts')
        .where('acknowledged', isEqualTo: false)
        .snapshots();
        
    return _unackAlertsRawStream!.map((snap) => snap.docs.length);
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

  // ────────────────────────────────────────────────
  //  NOTIFICATIONS / ALERTS
  // ────────────────────────────────────────────────

  /// Typed stream of every alert, newest first.
  Stream<List<NotificationAlert>> streamNotificationAlerts() {
    _notificationAlertsRawStream ??= _db
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .snapshots();
        
    return _notificationAlertsRawStream!.map((snap) =>
        snap.docs.map((d) => NotificationAlert.fromFirestore(d)).toList());
  }

  Future<void> markAlertRead(String alertId) async {
    await _db.collection('alerts').doc(alertId).update({'acknowledged': true});
  }

  Future<void> markAllAlertsRead() async {
    final snap =
        await _db.collection('alerts').where('acknowledged', isEqualTo: false).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'acknowledged': true});
    }
    await batch.commit();
  }

  Future<void> dismissAlert(String alertId) async {
    await _db.collection('alerts').doc(alertId).delete();
  }

  Future<void> addAlert({
    required String title,
    required String message,
    required AlertSeverity severity,
    String? room,
    String? deviceId,
    String icon = 'info',
  }) async {
    await _db.collection('alerts').add({
      'title': title,
      'message': message,
      'severity': severityToString(severity),
      if (room != null) 'room': room,
      if (deviceId != null) 'deviceId': deviceId,
      'icon': icon,
      'timestamp': FieldValue.serverTimestamp(),
      'acknowledged': false,
    });
  }

  // ────────────────────────────────────────────────
  //  ENERGY USAGE / ANALYSIS
  // ────────────────────────────────────────────────

  /// Stream of every energy reading, used by the Analysis screen to compute
  /// today/week/month totals, room breakdowns and top consumers client-side.
  Stream<List<EnergyReading>> streamEnergyUsage() {
    _energyUsageRawStream ??= _db
        .collection('energyUsage')
        .orderBy('date', descending: true)
        .snapshots();
        
    return _energyUsageRawStream!.map((snap) =>
        snap.docs.map((d) => EnergyReading.fromFirestore(d)).toList());
  }

  Future<void> addEnergyReading(EnergyReading reading) async {
    await _db.collection('energyUsage').add(reading.toMap());
  }

  // ────────────────────────────────────────────────
  //  HOUSE MEMBERS / PROFILE
  // ────────────────────────────────────────────────

  Stream<List<HouseMember>> streamHouseMembers() {
    _houseMembersRawStream ??= _db.collection('houseMembers').snapshots();
    return _houseMembersRawStream!.map(
        (snap) => snap.docs.map((d) => HouseMember.fromFirestore(d)).toList());
  }

  Future<void> addHouseMember(HouseMember member) async {
    await _db.collection('houseMembers').add(member.toMap());
  }

  /// Count of saved scenes, shown as a stat on the Profile screen.
  Stream<int> streamSceneCount() {
    _scenesRawStream ??= _db.collection('scenes').snapshots();
    return _scenesRawStream!.map((s) => s.docs.length);
  }

  /// Count of distinct rooms across every floor, shown as a stat on the
  /// Profile screen.
  Future<int> countDistinctRooms() async {
    final floorsSnap = await _db.collection('floors').get();
    int total = 0;
    for (final floor in floorsSnap.docs) {
      final roomsSnap =
          await _db.collection('floors').doc(floor.id).collection('rooms').get();
      total += roomsSnap.docs.length;
    }
    return total;
  }

  /// Single user preferences document (dark mode / push notifications /
  /// Firebase sync toggles) shown on the Profile screen.
  DocumentReference get preferencesDoc =>
      _db.collection('settings').doc('preferences');

  Stream<DocumentSnapshot> streamPreferences() {
    _preferencesStream ??= preferencesDoc.snapshots();
    return _preferencesStream!;
  }

  Future<void> setPreference(String key, bool value) async {
    await preferencesDoc.set({key: value}, SetOptions(merge: true));
  }

  // ────────────────────────────────────────────────
  //  USER PROFILE (stored in Firestore, no auth required)
  // ────────────────────────────────────────────────

  DocumentReference get profileDoc =>
      _db.collection('settings').doc('profile');

  Stream<DocumentSnapshot> streamProfile() {
    _profileStream ??= profileDoc.snapshots();
    return _profileStream!;
  }

  Future<void> updateProfile({String? name, String? email}) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (email != null) updates['email'] = email;
    if (updates.isNotEmpty) {
      await profileDoc.set(updates, SetOptions(merge: true));
    }
  }

  // ────────────────────────────────────────────────
  //  CAMERAS
  // ────────────────────────────────────────────────

  /// Cameras grouped under a pseudo-floor id, e.g. "exterior" for outdoor
  /// cameras that aren't tied to any real floor document.
  Stream<List<Device>> streamCamerasForGroup(String floorId) {
    return _db
        .collection('floors')
        .doc(floorId)
        .collection('devices')
        .where('type', isEqualTo: 'camera')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Device.fromFirestore(floorId, d)).toList());
  }

  /// Returns a stream of the floor's imageUrl field.
  /// Returns null if the floor document doesn't exist or has no imageUrl.
  Stream<String?> streamFloorImageUrl(String floorId) {
    return _db
        .collection('floors')
        .doc(floorId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      final url = data['imageUrl'] as String?;
      return (url != null && url.isNotEmpty) ? url : null;
    });
  }

  // ────────────────────────────────────────────────
  //  DEVICE SCHEDULING
  // ────────────────────────────────────────────────

  /// Sets (or replaces) a daily schedule for a bulb/device.
  /// [scheduleStart] and [scheduleEnd] must be 24-hour strings, e.g. "18:15".
  Future<void> updateDeviceSchedule(
    String floorId,
    String deviceId,
    String scheduleStart,
    String scheduleEnd,
  ) async {
    await _db
        .collection('floors')
        .doc(floorId)
        .collection('devices')
        .doc(deviceId)
        .update({
      'scheduleStart': scheduleStart,
      'scheduleEnd': scheduleEnd,
    });
  }

  /// Removes the schedule fields from a device document entirely.
  Future<void> clearDeviceSchedule(String floorId, String deviceId) async {
    await _db
        .collection('floors')
        .doc(floorId)
        .collection('devices')
        .doc(deviceId)
        .update({
      'scheduleStart': FieldValue.delete(),
      'scheduleEnd': FieldValue.delete(),
    });
  }
}