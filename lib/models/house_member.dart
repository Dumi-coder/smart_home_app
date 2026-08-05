import 'package:cloud_firestore/cloud_firestore.dart';

/// A member of the household, shown on the Profile screen.
class HouseMember {
  final String id;
  final String name;
  final String email;
  final String role; // "Owner" | "Admin" | "Guest"
  final bool online;
  final String? avatarUrl;

  HouseMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.online,
    this.avatarUrl,
  });

  factory HouseMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HouseMember(
      id: doc.id,
      name: data['name'] ?? 'Unnamed',
      email: data['email'] ?? '',
      role: data['role'] ?? 'Guest',
      online: data['online'] ?? false,
      avatarUrl: data['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role,
        'online': online,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      };
}
