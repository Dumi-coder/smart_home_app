import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/device.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/device_detail_sheet.dart';

class AllDevicesScreen extends StatefulWidget {
  const AllDevicesScreen({super.key});

  @override
  State<AllDevicesScreen> createState() => _AllDevicesScreenState();
}

class _AllDevicesScreenState extends State<AllDevicesScreen> {
  final FirestoreService _service = FirestoreService();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Lights',
    'HVAC',
    'Sensors',
    'Outlets',
    'Cameras'
  ];

  bool _matchesCategory(Device d) {
    if (_selectedCategory == 'All') return true;
    if (_selectedCategory == 'Lights' && d.type == 'bulb') return true;
    if (_selectedCategory == 'HVAC' && d.type == 'iron') return true;
    if (_selectedCategory == 'Sensors' && d.type == 'sensor') return true;
    if (_selectedCategory == 'Outlets' &&
        (d.type == 'outlet' || d.type == 'multiswitch')) return true;
    if (_selectedCategory == 'Cameras' && d.type == 'camera') return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All Devices',
            style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.streamFloors(),
        builder: (context, floorSnap) {
          if (!floorSnap.hasData) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryActiveDark));
          }
          final floors = {
            for (var doc in floorSnap.data!.docs)
              doc.id: (doc.data() as Map<String, dynamic>)['name'] as String
          };

          return StreamBuilder<List<Device>>(
            stream: _service.streamAllDevices(),
            builder: (context, deviceSnap) {
              if (!deviceSnap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryActiveDark));
              }

              var devices = deviceSnap.data!
                  .where((d) => _matchesCategory(d))
                  .toList();

              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                devices = devices
                    .where((d) =>
                        d.name.toLowerCase().contains(q) ||
                        (d.room?.toLowerCase().contains(q) ?? false))
                    .toList();
              }

              final activeCount =
                  devices.where((d) => d.status == DeviceStatus.on).length;

              return Column(
                children: [
                  // Status summary
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${devices.length} Devices • $activeCount Active',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search devices or rooms...',
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Categories
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _categories.length,
                      itemBuilder: (context, i) {
                        final cat = _categories[i];
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setState(() => _selectedCategory = cat);
                            },
                            selectedColor: AppColors.primaryActive,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            backgroundColor: AppColors.surface,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Device list
                  Expanded(
                    child: ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final d = devices[index];
                        final floorName =
                            floors[d.floorId] ?? 'Unknown Floor';
                        final location = d.room != null
                            ? '${d.room} • $floorName'
                            : floorName;
                        final isOn = d.status == DeviceStatus.on;

                        IconData icon;
                        Color iconColor;
                        if (d is OutletDevice) {
                          icon = Icons.power;
                          iconColor = AppColors.brass;
                        } else if (d is BulbDevice) {
                          icon = Icons.lightbulb_outline;
                          iconColor = AppColors.primaryActive;
                        } else if (d is IronDevice) {
                          icon = Icons.iron;
                          iconColor = AppColors.statusError;
                        } else if (d is MultiSwitchDevice) {
                          icon = Icons.toggle_on_outlined;
                          iconColor = AppColors.pineDeep;
                        } else if (d is CameraDevice) {
                          icon = Icons.videocam_outlined;
                          iconColor = AppColors.accentCamera;
                        } else {
                          icon = Icons.device_unknown;
                          iconColor = Colors.grey;
                        }

                        return ListTile(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => DeviceDetailSheet(
                                device: d,
                                service: _service,
                              ),
                            );
                          },
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isOn
                                  ? iconColor.withValues(alpha: 0.15)
                                  : AppColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon,
                                color: isOn
                                    ? iconColor
                                    : AppColors.textSecondary),
                          ),
                          title: Text(d.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          subtitle: Text(location,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                          trailing: Switch(
                            value: isOn,
                            activeColor: iconColor,
                            onChanged: (val) {
                              _service.toggleDevice(d.floorId, d.id, val);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Go to Home to add devices')),
          );
        },
        backgroundColor: AppColors.primaryActive,
        child: const Icon(Icons.add, color: AppColors.textOnDark),
      ),
    );
  }
}
