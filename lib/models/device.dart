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
  final String type; // "outlet" | "MULTI_SWITCH" | "iron" | "bulb" | "camera" | "fan" | "ac"
  final double x;
  final double y;
  final DeviceStatus status;
  final String? room;

  Device({
    required this.id,
    required this.floorId,
    required this.name,
    required this.type,
    required this.x,
    required this.y,
    required this.status,
    this.room,
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
    final room = data['room'] as String?;

    switch (type) {
      case 'MULTI_SWITCH':
        return MultiSwitchDevice(
          id: id,
          floorId: floorId,
          name: name,
          x: x,
          y: y,
          status: status,
          room: room,
        );
      case 'iron':
        return IronDevice(
          id: id,
          floorId: floorId,
          name: name,
          x: x,
          y: y,
          status: status,
          room: room,
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
          room: room,
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
          room: room,
          snapshotUrl: data['snapshotUrl'] ?? '',
        );
      case 'fan':
        return FanDevice(
          id: id,
          floorId: floorId,
          name: name,
          x: x,
          y: y,
          status: status,
          room: room,
        );
      case 'ac':
        return AcDevice(
          id: id,
          floorId: floorId,
          name: name,
          x: x,
          y: y,
          status: status,
          room: room,
          temperature: (data['temperature'] ?? 24).toDouble(),
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
          room: room,
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
    super.room,
  }) : super(type: 'outlet');

  @override
  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type,
    'x': x,
    'y': y,
    'status': statusToString(status),
    if (room != null) 'room': room,
  };
}

// ---------------- Multi-switch ----------------
class ChildSwitch {
  final String id;
  final String deviceId;
  final int switchNumber;
  final String name;
  final String status;
  final bool enabled;
  final String? connectedDeviceId;
  final String? connectedDeviceName;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  ChildSwitch({
    required this.id,
    required this.deviceId,
    required this.switchNumber,
    required this.name,
    required this.status,
    required this.enabled,
    this.connectedDeviceId,
    this.connectedDeviceName,
    this.createdAt,
    this.updatedAt,
  });

  factory ChildSwitch.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChildSwitch(
      id: doc.id,
      deviceId: data['device_id'] ?? '',
      switchNumber: data['switch_number'] ?? 1,
      name: data['name'] ?? 'Unnamed',
      status: data['status'] ?? 'OFF',
      enabled: data['enabled'] ?? true,
      connectedDeviceId: data['connected_device_id'] as String?,
      connectedDeviceName: data['connected_device_name'] as String?,
      createdAt: data['created_at'] is Timestamp ? data['created_at'] as Timestamp : null,
      updatedAt: data['updated_at'] is Timestamp ? data['updated_at'] as Timestamp : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'device_id': deviceId,
    'switch_number': switchNumber,
    'name': name,
    'status': status,
    'enabled': enabled,
    if (connectedDeviceId != null) 'connected_device_id': connectedDeviceId,
    if (connectedDeviceName != null) 'connected_device_name': connectedDeviceName,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

// ---------------- Fan ----------------
class FanDevice extends Device {
  FanDevice({
    required super.id,
    required super.floorId,
    required super.name,
    required super.x,
    required super.y,
    required super.status,
    super.room,
  }) : super(type: 'fan');

  @override
  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type,
    'x': x,
    'y': y,
    'status': statusToString(status),
    if (room != null) 'room': room,
  };
}

// ---------------- AC ----------------
class AcDevice extends Device {
  final double temperature;

  AcDevice({
    required super.id,
    required super.floorId,
    required super.name,
    required super.x,
    required super.y,
    required super.status,
    super.room,
    this.temperature = 24.0,
  }) : super(type: 'ac');

  @override
  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type,
    'x': x,
    'y': y,
    'status': statusToString(status),
    'temperature': temperature,
    if (room != null) 'room': room,
  };
}

class MultiSwitchDevice extends Device {
  MultiSwitchDevice({
    required super.id,
    required super.floorId,
    required super.name,
    required super.x,
    required super.y,
    required super.status,
    super.room,
  }) : super(type: 'MULTI_SWITCH');

  @override
  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type,
    'x': x,
    'y': y,
    'status': statusToString(status),
    if (room != null) 'room': room,
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
    super.room,
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
    if (room != null) 'room': room,
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
    super.room,
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
    if (room != null) 'room': room,
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
    super.room,
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
    if (room != null) 'room': room,
  };
}