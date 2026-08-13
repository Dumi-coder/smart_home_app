import 'package:cloud_firestore/cloud_firestore.dart';

/// One day's energy consumption sample for a device/room, backed by the
/// top-level `energyUsage` Firestore collection. Seeded with ~30 days of
/// data so the Analysis screen has something real to aggregate over.
class EnergyReading {
  final String id;
  final DateTime date;
  final String room;
  final String device;
  final double kWh;

  EnergyReading({
    required this.id,
    required this.date,
    required this.room,
    required this.device,
    required this.kWh,
  });

  factory EnergyReading.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EnergyReading(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      room: data['room'] ?? 'Unknown',
      device: data['device'] ?? 'Unknown',
      kWh: (data['kWh'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'room': room,
        'device': device,
        'kWh': kWh,
      };
}
