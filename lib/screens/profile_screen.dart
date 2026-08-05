import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/device.dart';
import '../models/house_member.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/member_tile.dart';
import '../widgets/preference_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _service = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          children: [
            Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            _buildProfileCard(),
            const SizedBox(height: 16),
            _buildHouseMembers(),
            const SizedBox(height: 16),
            _buildPreferences(),
            const SizedBox(height: 16),
            _buildSecurity(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  PROFILE CARD + STATS
  // ═══════════════════════════════════════════════
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryActive.withValues(alpha: 0.3),
                  border: Border.all(color: AppColors.primaryActive, width: 2),
                ),
                child: const Center(child: Icon(Icons.person, size: 30, color: AppColors.textPrimary)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Alex Morgan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const Text('alex.morgan@email.com', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryActive.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Owner', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 6),
                        const Text('· Home Hub v2.4', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<List<Device>>(
                  stream: _service.streamAllDevices(),
                  builder: (context, snap) => _statColumn('${snap.data?.length ?? 0}', 'Devices'),
                ),
              ),
              Expanded(
                child: FutureBuilder<int>(
                  future: _service.countDistinctRooms(),
                  builder: (context, snap) => _statColumn('${snap.data ?? 0}', 'Rooms'),
                ),
              ),
              Expanded(
                child: StreamBuilder<int>(
                  stream: _service.streamSceneCount(),
                  builder: (context, snap) => _statColumn('${snap.data ?? 0}', 'Scenes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  //  HOUSE MEMBERS
  // ═══════════════════════════════════════════════
  Widget _buildHouseMembers() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('House Members', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: () => _showAddMemberDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: AppColors.chipSelected, shape: BoxShape.circle),
                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          StreamBuilder<List<HouseMember>>(
            stream: _service.streamHouseMembers(),
            builder: (context, snap) {
              final members = snap.data ?? [];
              if (members.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No members yet.', style: TextStyle(color: AppColors.textSecondary)),
                );
              }
              return Column(children: members.map((m) => MemberTile(member: m)).toList());
            },
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String role = 'Guest';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add House Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: ['Admin', 'Guest']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => role = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  await _service.addHouseMember(HouseMember(
                    id: '',
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    role: role,
                    online: false,
                  ));
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  PREFERENCES
  // ═══════════════════════════════════════════════
  Widget _buildPreferences() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PREFERENCES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          StreamBuilder<DocumentSnapshot>(
            stream: _service.streamPreferences(),
            builder: (context, snap) {
              final data = snap.data?.data() as Map<String, dynamic>?;
              final darkMode = data?['darkMode'] ?? false;
              final pushNotifications = data?['pushNotifications'] ?? true;
              final firebaseSync = data?['firebaseSync'] ?? true;

              return Column(
                children: [
                  PreferenceTile(
                    icon: darkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    title: 'Dark Mode',
                    subtitle: darkMode ? 'Dark theme active' : 'Light theme active',
                    value: darkMode,
                    onChanged: (v) => _service.setPreference('darkMode', v),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  PreferenceTile(
                    icon: Icons.notifications_none,
                    title: 'Push Notifications',
                    subtitle: 'Alerts, automations, reminders',
                    value: pushNotifications,
                    onChanged: (v) => _service.setPreference('pushNotifications', v),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  PreferenceTile(
                    icon: Icons.wifi,
                    title: 'Firebase Sync',
                    subtitle: 'Real-time sync enabled',
                    value: firebaseSync,
                    onChanged: (v) => _service.setPreference('firebaseSync', v),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  SECURITY
  // ═══════════════════════════════════════════════
  Widget _buildSecurity() {
    Widget row(IconData icon, String label, {VoidCallback? onTap}) {
      return InkWell(
        onTap: onTap ??
            () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Not wired up yet — placeholder action'), duration: Duration(seconds: 1)),
                ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SECURITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          row(Icons.dialpad_outlined, 'Change PIN'),
          const Divider(height: 1, color: AppColors.divider),
          row(Icons.verified_user_outlined, 'Two-Factor Authentication'),
          const Divider(height: 1, color: AppColors.divider),
          row(Icons.vpn_key_outlined, 'Manage House Access'),
          const Divider(height: 1, color: AppColors.divider),
          row(Icons.logout, 'Sign Out'),
        ],
      ),
    );
  }
}
