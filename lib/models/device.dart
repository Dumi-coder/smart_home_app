import 'package:cloud_firestore/cloud_firestore.dart';

enum DeviceStatus { on, off, error, disconnected }

DeviceStatus statusFromString(String s) {
  switch (s) {
    case 'ON':
      return DeviceStatus.on;
    case 'OFF':
      return DeviceStatus.off;
    case 'ERROR':
      return DeviceStatus.error;
    default:
      return DeviceStatus.disconnected;
  }
}

String statusToString(DeviceStatus status) {
  switch (status) {
    case DeviceStatus.on:
      return 'ON';
    case DeviceStatus.off:
      return 'OFF';
    case DeviceStatus.error:
      return 'ERROR';
    case DeviceStatus.disconnected:
      return 'DISCONNECTED';
  }
}

/// Base class every device type extends.
abstract class Device {
  final String id;
  final String floorId;
  final String name;
  final String type; // "outlet" | "multiswitch" | "iron" | "bulb" | "camera"
  final double x;
  final double y;
  final DeviceStatus status;

  Device({
    required this.id,
    required this.floorId,
    required this.name,
    required this.type,
    required this.x,
    required this.y,
    required this.status,
  });

  /// Every subclass must know how to serialize its own extra fields.
  Map<String, dynamic> toMap();

  /// Factory that reads the "type" field and builds the correct subclass.
  factory Device.fromFirestore(String floorId, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final type = data['type'] as String;
    final status = statusFromString(data['status'] ?? 'DISCONNECTED');
    final id = doc.id;
    final name = data['name'] ?? 'Unnamed';
    final x = (data['x'] ?? 0).toDouble();
    final y = (data['y'] ?? 0).toDouble();

    switch (type) {
      case 'multiswitch':
        return MultiSwitchDevice(
          id: id,
          floorId: floorId,
          name: name,
          x: x,
          y: y,
          status: status,
          switches: (data['switches'] as List<dynamic>? ?? [])
              .map((s) => SwitchItem.fromMap(s as Map<String, dynamic>))
              .toList(),
        );
      case 'iron':
        return IronDevice(
          id: id,
          floorId: floorId,
          name: name,
          x: x,
          y: y,
          status: status,
          maxOnDurationMinutes: data['maxOnDurationMinutes'] ?? 15,
          turnedOnAt: data['turnedOnAt'] != null
              ? (data['turnedOnAt'] as Timestamp).toDate()
              : null,
        );
      case 'bulb':
        return BulbDevice(
          id: id,
          floorId: floorId,
          name: name,
          x: x,
          y: y,
          status: status,
          scheduleStart: data['scheduleStart'],
          scheduleEnd: data['scheduleEnd'],
        );
      case 'camera':
        return CameraDevice(
          id: id,
          floorId: floorId,
          name: name,
          x: x,
          y: y,
          status: status,
          snapshotUrl: data['snapshotUrl'] ?? '',
        );
      case 'outlet':
      default:
        return OutletDevice(
          id: id,
          floorId: floorId,
          name: name,
          x: x,
          y: y,
          status: status,
        );
    }
  }
}

// ---------------- Outlet ----------------
class OutletDevice extends Device {
  OutletDevice({
    required super.id,
    required super.floorId,
    required super.name,
    required super.x,
    required super.y,
    required super.status,
  }) : super(type: 'outlet');

  @override
  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type,
    'x': x,
    'y': y,
    'status': statusToString(status),
  };
}

// ---------------- Multi-switch ----------------
class SwitchItem {
  final String id;
  final String label;
  final bool state;

  SwitchItem({required this.id, required this.label, required this.state});

  factory SwitchItem.fromMap(Map<String, dynamic> map) => SwitchItem(
    id: map['id'],
    label: map['label'],
    state: map['state'] ?? false,
  );

  Map<String, dynamic> toMap() => {'id': id, 'label': label, 'state': state};
}

class MultiSwitchDevice extends Device {
  final List<SwitchItem> switches;

  MultiSwitchDevice({
    required super.id,
    required super.floorId,
    required super.name,
    required super.x,
    required super.y,
    required super.status,
    required this.switches,
  }) : super(type: 'multiswitch');

  @override
  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type,
    'x': x,
    'y': y,
    'status': statusToString(status),
    'switches': switches.map((s) => s.toMap()).toList(),
  };
}

// ---------------- Iron (safety-critical) ----------------
class IronDevice extends Device {
  final int maxOnDurationMinutes;
  final DateTime? turnedOnAt;

  IronDevice({
    required super.id,
    required super.floorId,
    required super.name,
    required super.x,
    required super.y,
    required super.status,
    required this.maxOnDurationMinutes,
    this.turnedOnAt,
  }) : super(type: 'iron');

  @override
  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type,
    'x': x,
    'y': y,
    'status': statusToString(status),
    'maxOnDurationMinutes': maxOnDurationMinutes,
    'turnedOnAt': turnedOnAt != null ? Timestamp.fromDate(turnedOnAt!) : null,
  };
}

// ---------------- Bulb (schedulable) ----------------
class BulbDevice extends Device {
  final String? scheduleStart; // e.g. "18:00"
  final String? scheduleEnd; // e.g. "23:00"

  BulbDevice({
    required super.id,
    required super.floorId,
    required super.name,
    required super.x,
    required super.y,
    required super.status,
    this.scheduleStart,
    this.scheduleEnd,
  }) : super(type: 'bulb');

  @override
  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type,
    'x': x,
    'y': y,
    'status': statusToString(status),
    'scheduleStart': scheduleStart,
    'scheduleEnd': scheduleEnd,
  };
}

// ---------------- Camera ----------------
class CameraDevice extends Device {
  final String snapshotUrl;

  CameraDevice({
    required super.id,
    required super.floorId,
    required super.name,
    required super.x,
    required super.y,
    required super.status,
    required this.snapshotUrl,
  }) : super(type: 'camera');

  @override
  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type,
    'x': x,
    'y': y,
    'status': statusToString(status),
    'snapshotUrl': snapshotUrl,
  };
}