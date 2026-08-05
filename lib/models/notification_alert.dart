import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertSeverity { critical, warning, info }

AlertSeverity severityFromString(String s) {
  switch (s) {
    case 'critical':
      return AlertSeverity.critical;
    case 'warning':
      return AlertSeverity.warning;
    default:
      return AlertSeverity.info;
  }
}

String severityToString(AlertSeverity severity) {
  switch (severity) {
    case AlertSeverity.critical:
      return 'critical';
    case AlertSeverity.warning:
      return 'warning';
    case AlertSeverity.info:
      return 'info';
  }
}

/// A single notification/alert row, backed by the top-level `alerts`
/// Firestore collection.
class NotificationAlert {
  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final String? room;
  final String? deviceId;
  final String icon; // key into NotificationIcons.iconFor
  final DateTime? timestamp;
  final bool acknowledged;

  NotificationAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    this.room,
    this.deviceId,
    required this.icon,
    this.timestamp,
    required this.acknowledged,
  });

  factory NotificationAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationAlert(
      id: doc.id,
      title: data['title'] ?? 'Alert',
      message: data['message'] ?? '',
      severity: severityFromString(data['severity'] ?? 'info'),
      room: data['room'] as String?,
      deviceId: data['deviceId'] as String?,
      icon: data['icon'] ?? 'info',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : null,
      acknowledged: data['acknowledged'] ?? false,
    );
  }

  /// Compact relative-time label, e.g. "2 min ago", "3 hr ago".
  String get relativeTime {
    if (timestamp == null) return 'Just now';
    final diff = DateTime.now().difference(timestamp!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} d ago';
  }
}
