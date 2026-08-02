import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/device.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

import '../widgets/floor_chip.dart';
import '../widgets/room_chip.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/device_card.dart';
import '../widgets/device_detail_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _service = FirestoreService();

  String? _selectedFloorId;

  String _selectedRoom = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _service.streamFloors(),
          builder: (context, floorsSnapshot) {
            if (floorsSnapshot.hasError) {
              return Center(child: Text('Error: ${floorsSnapshot.error}'));
            }
            if (!floorsSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryActiveDark,
                ),
              );
            }

            final floors = floorsSnapshot.data!.docs;

            // Auto-select first floor if none selected
            if (_selectedFloorId == null && floors.isNotEmpty) {
              _selectedFloorId = floors.first.id;
            }

            return CustomScrollView(
              slivers: [
                // ── Header ──
                SliverToBoxAdapter(child: _buildHeader()),
                // ── Active devices banner ──
                SliverToBoxAdapter(child: _buildActiveDevicesBanner()),
                // ── Floor chips ──
                SliverToBoxAdapter(child: _buildFloorChips(floors)),
                // ── Device count + view toggle ──
                if (_selectedFloorId != null)
                  SliverToBoxAdapter(
                    child: _buildDeviceCountRow(),
                  ),
                // ── Quick actions ──
                SliverToBoxAdapter(child: _buildQuickActions()),
                // ── Room chips ──
                if (_selectedFloorId != null)
                  SliverToBoxAdapter(child: _buildRoomChips()),
                // ── Device grid ──
                if (_selectedFloorId != null)
                  _buildDeviceGrid()
                else
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No floors yet.\nAdd a floor to get started.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Bottom padding for nav bar
                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════════
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Profile avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryActive.withValues(alpha: 0.3),
              border: Border.all(color: AppColors.primaryActive, width: 2),
            ),
            child: const Center(
              child: Icon(Icons.person, color: AppColors.textPrimary, size: 26),
            ),
          ),
          const SizedBox(width: 12),
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Text(
                  'Alex',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Action icons
          _headerIcon(Icons.calendar_today_outlined),
          const SizedBox(width: 8),
          _headerIcon(Icons.smart_toy_outlined),
          const SizedBox(width: 8),
          // Notification bell with badge
          StreamBuilder<int>(
            stream: _service.streamUnacknowledgedAlertCount(),
            builder: (context, alertSnap) {
              final count = alertSnap.data ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  _headerIcon(Icons.notifications_outlined),
                  if (count > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.statusError,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Icon(icon, size: 20, color: AppColors.textPrimary),
    );
  }

  // ═══════════════════════════════════════════════
  //  ACTIVE DEVICES BANNER
  // ═══════════════════════════════════════════════
  Widget _buildActiveDevicesBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: StreamBuilder<List<Device>>(
        stream: _service.streamAllDevices(),
        builder: (context, snap) {
          final allDevices = snap.data ?? [];
          final activeCount =
              allDevices.where((d) => d.status == DeviceStatus.on).length;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryActive,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$activeCount device${activeCount == 1 ? '' : 's'} active',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Manage',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.settings_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  FLOOR CHIPS
  // ═══════════════════════════════════════════════
  Widget _buildFloorChips(List<QueryDocumentSnapshot> floors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: floors.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final doc = floors[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Unnamed';
            final isSelected = doc.id == _selectedFloorId;

            return FloorChip(
              label: name,
              icon: FloorChip.iconForFloor(name),
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedFloorId = doc.id;
                  _selectedRoom = 'All';
                });
              },
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  DEVICE COUNT ROW
  // ═══════════════════════════════════════════════
  Widget _buildDeviceCountRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: StreamBuilder<List<Device>>(
        stream: _service.streamDevices(_selectedFloorId!),
        builder: (context, snap) {
          final count = snap.data?.length ?? 0;
          return Row(
            children: [
              Text(
                '$count device${count == 1 ? '' : 's'} on floor',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.view_list_outlined,
                        size: 16, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Icon(Icons.grid_view_rounded,
                        size: 16, color: AppColors.textPrimary),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  QUICK ACTIONS
  // ═══════════════════════════════════════════════
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: QuickActionCard(
              icon: Icons.lightbulb_outline,
              label: 'All Lights',
              backgroundColor: AppColors.quickActionLights,
              iconColor: const Color(0xFFF9A825),
              onTap: () => _service.toggleAllDevicesByType('bulb', true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: QuickActionCard(
              icon: Icons.power_settings_new,
              label: 'Turn Off All',
              backgroundColor: AppColors.quickActionTurnOff,
              iconColor: AppColors.statusError,
              onTap: () => _service.turnOffAllDevices(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: QuickActionCard(
              icon: Icons.lock_outline,
              label: 'Lock House',
              backgroundColor: AppColors.quickActionLock,
              iconColor: const Color(0xFF1565C0),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lock House — coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  ROOM CHIPS
  // ═══════════════════════════════════════════════
  Widget _buildRoomChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: StreamBuilder<List<Device>>(
        stream: _service.streamDevices(_selectedFloorId!),
        builder: (context, snap) {
          final devices = snap.data ?? [];
          // Extract unique room names
          final rooms = <String>{'All'};
          for (final d in devices) {
            if (d.room != null && d.room!.isNotEmpty) {
              rooms.add(d.room!);
            }
          }
          // If there's only "All" (no rooms defined), don't show chips
          if (rooms.length <= 1) return const SizedBox.shrink();

          return SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: rooms.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final room = rooms.elementAt(index);
                return RoomChip(
                  label: room,
                  icon: room == 'All' ? null : RoomChip.iconForRoom(room),
                  isSelected: _selectedRoom == room,
                  onTap: () {
                    setState(() => _selectedRoom = room);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  DEVICE GRID
  // ═══════════════════════════════════════════════
  Widget _buildDeviceGrid() {
    return StreamBuilder<List<Device>>(
      stream: _service.streamDevices(_selectedFloorId!),
      builder: (context, snap) {
        if (snap.hasError) {
          return SliverToBoxAdapter(
            child: Center(child: Text('Error: ${snap.error}')),
          );
        }
        if (!snap.hasData) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: AppColors.primaryActiveDark,
                ),
              ),
            ),
          );
        }

        var devices = snap.data!;

        // Filter by room
        if (_selectedRoom != 'All') {
          devices = devices.where((d) => d.room == _selectedRoom).toList();
        }

        if (devices.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No devices in this view.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.92,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final device = devices[index];
                return DeviceCard(
                  device: device,
                  onToggle: () {
                    _service.toggleDevice(
                      device.floorId,
                      device.id,
                      device.status != DeviceStatus.on,
                    );
                  },
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => DeviceDetailSheet(
                        device: device,
                        service: _service,
                      ),
                    );
                  },
                );
              },
              childCount: devices.length,
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}
