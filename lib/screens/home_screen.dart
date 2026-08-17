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
import '../widgets/multiswitch_tile.dart';
import 'all_devices_screen.dart';
import 'simulator_screen.dart';
import 'floor_plan_screen.dart';
import 'notifications_screen.dart';
import '../theme/app_background.dart';
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
      backgroundColor: Colors.transparent,
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
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _selectedFloorId = floors.first.id;
                  });
                }
              });
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryActiveDark,
                ),
              );
            }

            return CustomScrollView(
              slivers: [
                // ── Header ──
                SliverToBoxAdapter(child: _buildHeader()),
                // ── Active devices banner ──
                SliverToBoxAdapter(child: _buildActiveDevicesBanner()),
                // ── Floor chips ──
                SliverToBoxAdapter(child: _buildFloorChips(floors)),
                // ── Device count + view toggle + device grid ──
                if (_selectedFloorId != null)
                  StreamBuilder<List<Device>>(
                    stream: _service.streamDevices(_selectedFloorId!),
                    builder: (context, deviceSnap) {
                      if (deviceSnap.hasError) {
                        return SliverToBoxAdapter(
                          child: Center(child: Text('Error: ${deviceSnap.error}')),
                        );
                      }
                      if (!deviceSnap.hasData) {
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

                      final allFloorDevices = deviceSnap.data!;
                      
                      return SliverMainAxisGroup(
                        slivers: [
                          // Device count row
                          SliverToBoxAdapter(child: _buildDeviceCountRow(allFloorDevices.length)),
                          // Quick actions
                          SliverToBoxAdapter(child: _buildQuickActions()),
                          // Room chips
                          SliverToBoxAdapter(child: _buildRoomChips()),
                          // Device grid
                          _buildDeviceGridFromData(deviceSnap),
                        ],
                      );
                    },
                  )
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
      floatingActionButton: _selectedFloorId != null
          ? FloatingActionButton(
        onPressed: () => _showAddDeviceDialog(context),
        backgroundColor: AppColors.primaryActive,
        child: const Icon(Icons.add, color: AppColors.textOnDark),
      )
          : null,
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
              gradient: RadialGradient(
                colors: [
                  AppColors.brass.withValues(alpha: 0.35),
                  AppColors.brass.withValues(alpha: 0.18),
                ],
              ),
              border: Border.all(color: AppColors.brass, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brass.withValues(alpha: 0.30),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.person, color: AppColors.pineDeep, size: 26),
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
                StreamBuilder<DocumentSnapshot>(
                  stream: _service.streamProfile(),
                  builder: (context, profileSnap) {
                    final data = profileSnap.data?.data() as Map<String, dynamic>?;
                    final name = (data?['name'] as String?)?.split(' ').first ?? 'Dumindu';
                    return Text(
                      name,
                      style: AppFonts.display(fontSize: 21, fontWeight: FontWeight.w600),
                    );
                  },
                ),
              ],
            ),
          ),
          // Action icons
          // Notification bell with badge
          StreamBuilder<int>(
            stream: _service.streamUnacknowledgedAlertCount(),
            builder: (context, alertSnap) {
              final count = alertSnap.data ?? 0;
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppBackground(child: NotificationsScreen()),
                    ),
                  );
                },
                child: Stack(
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
              ),
            );
          },
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SimulatorScreen()),
              );
            },
            child: _headerIcon(Icons.developer_board_outlined),
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

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllDevicesScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.pineDeep, AppColors.pine],
                ),
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.pineDeep.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.brass,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brass.withValues(alpha: 0.7),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$activeCount device${activeCount == 1 ? '' : 's'} active',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnDark,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Manage',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brass,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.brass,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
          itemCount: floors.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            if (index == floors.length) {
              return FloorChip(
                label: 'Add Floor',
                icon: Icons.add,
                isSelected: false,
                onTap: () => _showManageFloorDialog(context, null, null),
              );
            }
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
              onLongPress: () => _showManageFloorDialog(context, doc.id, data),
            );
          },
        ),
      ),
    );
  }


  // ═══════════════════════════════════════════════
  //  DEVICE COUNT ROW
  // ═══════════════════════════════════════════════
  Widget _buildDeviceCountRow(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
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
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FloorPlanScreen(floorId: _selectedFloorId!),
                ),
              );
            },
            child: Container(
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
                  Icon(Icons.map_outlined,
                      size: 16, color: AppColors.textPrimary),
                  SizedBox(width: 6),
                  Text('Floor Plan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
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
              iconColor: AppColors.brassDeep,
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
              iconColor: AppColors.accentCamera,
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
      child: StreamBuilder<QuerySnapshot>(
        stream: _service.streamRooms(_selectedFloorId!),
        builder: (context, snap) {
          final roomDocs = snap.data?.docs ?? [];
          final rooms = ['All', ...roomDocs.map((d) => (d.data() as Map<String, dynamic>)['name'] as String)];

          return SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: rooms.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == rooms.length) {
                  return RoomChip(
                    label: 'Add Room',
                    icon: Icons.add,
                    isSelected: false,
                    onTap: () => _showManageRoomDialog(context, null, null),
                  );
                }
                final room = rooms[index];
                String? roomId;
                if (room != 'All') {
                  roomId = roomDocs[index - 1].id;
                }
                return RoomChip(
                  label: room,
                  icon: room == 'All' ? null : RoomChip.iconForRoom(room),
                  isSelected: _selectedRoom == room,
                  onTap: () {
                    setState(() => _selectedRoom = room);
                  },
                  onLongPress: room == 'All' ? null : () => _showManageRoomDialog(context, roomId, room),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  DEVICE GRID (from shared snapshot data)
  // ═══════════════════════════════════════════════
  Widget _buildDeviceGridFromData(AsyncSnapshot<List<Device>> snap) {
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

    final multiSwitches = devices.whereType<MultiSwitchDevice>().toList();
    final otherDevices = devices.where((d) => d is! MultiSwitchDevice).toList();

    return SliverMainAxisGroup(
      slivers: [
        // Multi-switch tiles rendered full-width above the grid
        if (multiSwitches.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final device = multiSwitches[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MultiSwitchTile(device: device, service: _service),
                );
              },
              childCount: multiSwitches.length,
            ),
          ),
        // Regular devices in a 2-column grid
        if (otherDevices.isNotEmpty)
          SliverPadding(
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
                  final device = otherDevices[index];
                  return DeviceCard(
                    device: device,
                    onToggle: () => _service.toggleDevice(
                      device.floorId,
                      device.id,
                      device.status != DeviceStatus.on,
                    ),
                    onTap: () => _showDeviceDetail(device),
                  );
                },
                childCount: otherDevices.length,
              ),
            ),
          ),
      ],
    );
  }

  void _showDeviceDetail(Device device) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeviceDetailSheet(
        device: device,
        service: _service,
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════
  // ═══════════════════════════════════════════════
  //  MANAGE DIALOGS
  // ═══════════════════════════════════════════════
  void _showManageFloorDialog(BuildContext context, String? floorId, Map<String, dynamic>? currentData) {
    final nameController = TextEditingController(text: currentData?['name'] as String?);
    final widthController = TextEditingController(text: currentData != null ? (currentData['gridWidth']?.toString() ?? '10') : '10');
    final heightController = TextEditingController(text: currentData != null ? (currentData['gridHeight']?.toString() ?? '10') : '10');
    final imageController = TextEditingController(text: currentData?['imageUrl'] as String?);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(floorId == null ? 'Add Floor' : 'Edit Floor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Floor name (e.g. Ground Floor)', labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widthController,
                      decoration: const InputDecoration(hintText: '10', labelText: 'Grid Width'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: heightController,
                      decoration: const InputDecoration(hintText: '10', labelText: 'Grid Height'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(hintText: 'https://...', labelText: 'Floor Plan Image URL (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          if (floorId != null)
            TextButton(
              onPressed: () async {
                await _service.deleteFloor(floorId);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Delete', style: TextStyle(color: AppColors.statusError)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final w = int.tryParse(widthController.text.trim()) ?? 10;
                final h = int.tryParse(heightController.text.trim()) ?? 10;
                final img = imageController.text.trim();
                
                if (floorId == null) {
                  await _service.addFloor(
                    name: nameController.text.trim(),
                    gridWidth: w,
                    gridHeight: h,
                    imageUrl: img,
                  );
                } else {
                  await _service.updateFloor(
                    floorId,
                    nameController.text.trim(),
                    gridWidth: w,
                    gridHeight: h,
                    imageUrl: img,
                  );
                }
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(floorId == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _showManageRoomDialog(BuildContext context, String? roomId, String? currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(roomId == null ? 'Add Room' : 'Edit Room'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Room name (e.g. Living Room)'),
        ),
        actions: [
          if (roomId != null)
            TextButton(
              onPressed: () async {
                await _service.deleteRoom(_selectedFloorId!, roomId);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Delete', style: TextStyle(color: AppColors.statusError)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                if (roomId == null) {
                  await _service.addRoom(_selectedFloorId!, controller.text.trim());
                } else {
                  await _service.updateRoom(_selectedFloorId!, roomId, controller.text.trim());
                }
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(roomId == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _showAddDeviceDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedType = 'outlet';
    int numSwitches = 2; // For MULTI_SWITCH
    // Each channel stores the ID of the device it controls (or null)
    final List<String?> selectedDeviceIds = List.filled(5, null);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          // Determine which room to filter devices by
          final String? currentRoom = _selectedRoom == 'All' ? null : _selectedRoom;

          return AlertDialog(
            title: const Text('Add Device'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Device Name (e.g. Kitchen Switch Panel)'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Device Type'),
                      items: ['outlet', 'bulb', 'iron', 'MULTI_SWITCH', 'camera', 'fan', 'ac']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase())))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedType = val);
                      },
                    ),
                    if (selectedType == 'MULTI_SWITCH') ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: numSwitches,
                        decoration: const InputDecoration(labelText: 'Number of Channels'),
                        items: [2, 3, 5]
                            .map((n) => DropdownMenuItem(value: n, child: Text('$n Switches')))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => numSwitches = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      // Fetch existing devices from this floor to populate channel dropdowns
                      StreamBuilder<List<Device>>(
                        stream: _service.streamDevices(_selectedFloorId!),
                        builder: (context, devSnap) {
                          if (!devSnap.hasData) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          // Filter to devices in this room (exclude other multi-switches)
                          var roomDevices = devSnap.data!
                              .where((d) => d.type != 'MULTI_SWITCH')
                              .toList();
                          if (currentRoom != null) {
                            roomDevices = roomDevices
                                .where((d) => d.room == currentRoom)
                                .toList();
                          }

                          if (roomDevices.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Text(
                                currentRoom != null
                                    ? 'No devices found in "$currentRoom".\nAdd devices to this room first.'
                                    : 'No devices on this floor yet.\nAdd devices first, then create a switch panel.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  currentRoom != null
                                      ? 'Assign devices from "$currentRoom":'
                                      : 'Assign devices from this floor:',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              for (int i = 0; i < numSwitches; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: DropdownButtonFormField<String>(
                                    value: selectedDeviceIds[i],
                                    decoration: InputDecoration(
                                      labelText: 'Channel ${i + 1}',
                                      prefixIcon: Icon(
                                        Icons.electrical_services,
                                        size: 18,
                                        color: selectedDeviceIds[i] != null
                                            ? AppColors.primaryActiveDark
                                            : AppColors.textSecondary,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    isExpanded: true,
                                    items: [
                                      const DropdownMenuItem<String>(
                                        value: null,
                                        child: Text('— Not assigned —',
                                            style: TextStyle(color: AppColors.textSecondary)),
                                      ),
                                      ...roomDevices.map((d) => DropdownMenuItem<String>(
                                        value: d.id,
                                        child: Row(
                                          children: [
                                            Icon(
                                              _iconForType(d.type),
                                              size: 16,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                d.name,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              d.type.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                    ],
                                    onChanged: (val) {
                                      setState(() => selectedDeviceIds[i] = val);
                                    },
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isNotEmpty) {
                    String? assignedRoom = _selectedRoom == 'All' ? null : _selectedRoom;
                    
                    if (selectedType == 'MULTI_SWITCH') {
                      final device = MultiSwitchDevice(
                        id: '', // Will be generated
                        floorId: _selectedFloorId!,
                        name: nameController.text.trim(),
                        x: 0,
                        y: 0,
                        status: DeviceStatus.off,
                        room: assignedRoom,
                      );
                      
                      // Build switch names from the selected device names
                      final channelIds = selectedDeviceIds.take(numSwitches).toList();
                      
                      await _service.addMultiSwitchWithDevices(
                        _selectedFloorId!,
                        device,
                        numSwitches,
                        channelIds,
                      );
                    } else {
                      final map = {
                        'name': nameController.text.trim(),
                        'type': selectedType,
                        'x': 0,
                        'y': 0,
                        'status': 'OFF',
                        if (assignedRoom != null) 'room': assignedRoom,
                      };
                      if (selectedType == 'iron') {
                        map['maxOnDurationMinutes'] = 15;
                      }
                      await _service.addDeviceRaw(_selectedFloorId!, map);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'bulb': return Icons.lightbulb_outline;
      case 'outlet': return Icons.power_outlined;
      case 'iron': return Icons.iron_outlined;
      case 'camera': return Icons.videocam_outlined;
      case 'fan': return Icons.air;
      case 'ac': return Icons.ac_unit;
      default: return Icons.devices_other;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}