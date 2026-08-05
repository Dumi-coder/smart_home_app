import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/device.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/floor_chip.dart';

/// Live Cameras tab. Cameras are grouped into "Exterior" (a pseudo-floor
/// with no floor document, see SeedData) plus one group per real floor.
/// Selecting a floor pill filters the thumbnail row; tapping a thumbnail
/// swaps the main viewer. The feed itself is a static demo image with a
/// pulsing LIVE indicator — there's no real RTSP/WebRTC stream wired up.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _service = FirestoreService();

  String _selectedGroupId = 'exterior';
  String _selectedGroupLabel = 'Exterior';
  Device? _selectedCamera;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _selectGroup(String id, String label) {
    setState(() {
      _selectedGroupId = id;
      _selectedGroupLabel = label;
      _selectedCamera = null; // auto-pick first camera once loaded
    });
  }

  void _selectCamera(Device camera) {
    setState(() => _selectedCamera = camera);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _service.streamFloors(),
          builder: (context, floorsSnap) {
            final floors = floorsSnap.data?.docs ?? [];

            return StreamBuilder<List<Device>>(
              stream: _service.streamCamerasForGroup(_selectedGroupId),
              builder: (context, camSnap) {
                final cameras = camSnap.data ?? [];
                if (_selectedCamera == null && cameras.isNotEmpty) {
                  // Auto-select first camera in the group after the frame,
                  // avoids calling setState mid-build.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _selectedCamera == null && cameras.isNotEmpty) {
                      setState(() => _selectedCamera = cameras.first);
                    }
                  });
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                  children: [
                    Text(
                      'Live Cameras',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 14),
                    _buildViewer(cameras),
                    const SizedBox(height: 16),
                    _buildFloorPills(floors),
                    const SizedBox(height: 16),
                    Text(
                      '$_selectedGroupLabel cameras',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (cameras.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No cameras in this group yet.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ...cameras.map((cam) => _ThumbnailTile(
                            camera: cam,
                            isSelected: _selectedCamera?.id == cam.id,
                            onTap: () => _selectCamera(cam),
                          )),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  MAIN VIEWER
  // ═══════════════════════════════════════════════
  Widget _buildViewer(List<Device> cameras) {
    final camera = _selectedCamera;
    final imageUrl = camera is CameraDevice && camera.snapshotUrl.isNotEmpty
        ? camera.snapshotUrl
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Demo feed image (or a dark placeholder if nothing selected)
            if (imageUrl != null)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.black87,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryActive),
                    ),
                  );
                },
                errorBuilder: (context, error, stack) => Container(
                  color: Colors.black87,
                  child: const Center(
                    child: Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 40),
                  ),
                ),
              )
            else
              Container(
                color: Colors.black87,
                child: const Center(
                  child: Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 40),
                ),
              ),
            // Darken gradient for legibility of overlays
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
            // Top-left LIVE · REC badges
            Positioned(
              top: 14,
              left: 14,
              child: Row(
                children: [
                  _pulsingBadge('LIVE', AppColors.statusOn),
                  const SizedBox(width: 8),
                  _pulsingBadge('REC', AppColors.statusError, dotOnly: false),
                ],
              ),
            ),
            // Top-right notification bell
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 18),
              ),
            ),
            // Bottom-left name + location
            if (camera != null)
              Positioned(
                left: 14,
                bottom: 14,
                right: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      camera.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (camera.room != null)
                      Text(
                        camera.room!,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                  ],
                ),
              ),
            // PTZ dpad + zoom + mic + snapshot
            Positioned(
              right: 14,
              bottom: 14,
              child: _buildPtzControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pulsingBadge(String label, Color color, {bool dotOnly = true}) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_pulseController),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPtzControls() {
    void notReal(String action) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$action (demo — no physical camera connected)'), duration: const Duration(seconds: 1)),
      );
    }

    Widget circleBtn(IconData icon, VoidCallback onTap, {double size = 34}) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: size * 0.5),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        circleBtn(Icons.keyboard_arrow_up, () => notReal('Zoom in')),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            circleBtn(Icons.chevron_left, () => notReal('Pan left')),
            const SizedBox(width: 6),
            circleBtn(Icons.circle, () => notReal('Pan'), size: 40),
            const SizedBox(width: 6),
            circleBtn(Icons.chevron_right, () => notReal('Pan right')),
          ],
        ),
        const SizedBox(height: 6),
        circleBtn(Icons.keyboard_arrow_down, () => notReal('Zoom out')),
        const SizedBox(height: 10),
        circleBtn(Icons.mic_none, () => notReal('Two-way audio')),
        const SizedBox(height: 8),
        circleBtn(Icons.camera_alt_outlined, () => notReal('Snapshot saved')),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  //  FLOOR PILLS
  // ═══════════════════════════════════════════════
  Widget _buildFloorPills(List<QueryDocumentSnapshot> floors) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FloorChip(
            label: 'Exterior',
            icon: Icons.deck_outlined,
            isSelected: _selectedGroupId == 'exterior',
            onTap: () => _selectGroup('exterior', 'Exterior'),
          ),
          const SizedBox(width: 10),
          ...floors.map((f) {
            final name = (f.data() as Map<String, dynamic>)['name'] ?? 'Floor';
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: FloorChip(
                label: name,
                icon: FloorChip.iconForFloor(name),
                isSelected: _selectedGroupId == f.id,
                onTap: () => _selectGroup(f.id, name),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ThumbnailTile extends StatelessWidget {
  final Device camera;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThumbnailTile({required this.camera, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = camera is CameraDevice ? (camera as CameraDevice).snapshotUrl : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: isSelected
              ? Border.all(color: AppColors.primaryActiveDark, width: 2)
              : Border.all(color: AppColors.divider, width: 1),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 64,
                height: 48,
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Container(color: AppColors.background),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(camera.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  if (camera.room != null)
                    Text(camera.room!, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: camera.status == DeviceStatus.on ? AppColors.statusOn : AppColors.statusOff,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
