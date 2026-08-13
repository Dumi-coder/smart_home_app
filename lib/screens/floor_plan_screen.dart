import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/device.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/device_detail_sheet.dart';

/// Floor Plan screen — large, clearly labeled rooms + device names.
class FloorPlanScreen extends StatefulWidget {
  final String floorId;
  const FloorPlanScreen({super.key, required this.floorId});

  @override
  State<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends State<FloorPlanScreen> {
  final FirestoreService _service = FirestoreService();

  // ─── palette ───
  static const _onColor  = Color(0xFFB8CC40);
  static const _offColor = Color(0xFFCCCCCC);
  static const _errColor = Color(0xFFE85353);
  static const _dcColor  = Color(0xFFF5A623);
  static const _pageBg   = Color(0xFFF2F2F0);
  static const _roomFill = Color(0xFFFAFAF8);
  static const _roomBdr  = Color(0xFFD0D0CB);

  Color _dotColor(DeviceStatus s) {
    switch (s) {
      case DeviceStatus.on:           return _onColor;
      case DeviceStatus.off:          return _offColor;
      case DeviceStatus.error:        return _errColor;
      case DeviceStatus.disconnected: return _dcColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('floors')
            .doc(widget.floorId)
            .snapshots(),
        builder: (context, floorSnap) {
          if (!floorSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final fd = floorSnap.data!.data() as Map<String, dynamic>? ?? {};
          final floorName = fd['name'] ?? 'Floor Plan';
          final int gridW = fd['gridWidth'] ?? 10;
          final int gridH = fd['gridHeight'] ?? 10;
          final String imageUrl = fd['imageUrl'] ?? '';

          return StreamBuilder<QuerySnapshot>(
            stream: _service.streamRooms(widget.floorId),
            builder: (context, roomsSnap) {
              if (!roomsSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final rooms = roomsSnap.data!.docs
                  .map((d) =>
                      (d.data() as Map<String, dynamic>)['name'] as String)
                  .toList();

              return StreamBuilder<List<Device>>(
                stream: _service.streamDevices(widget.floorId),
                builder: (context, devSnap) {
                  if (!devSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final devices = devSnap.data!;

                  return SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Custom header with floor name ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back,
                                    color: AppColors.textPrimary),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      floorName,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${rooms.length} rooms • ${devices.length} devices',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Device count badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _onColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${devices.where((d) => d.status == DeviceStatus.on).length} ON',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF7A8A20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ── The floor plan grid ──
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: InteractiveViewer(
                              minScale: 0.4,
                              maxScale: 5.0,
                              boundaryMargin:
                                  const EdgeInsets.all(double.infinity),
                              child: Center(
                                child: AspectRatio(
                                  aspectRatio: gridW / gridH,
                                  child: LayoutBuilder(
                                    builder: (context, box) {
                                      final cellW = box.maxWidth / gridW;
                                      final cellH = box.maxHeight / gridH;

                                      return Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          // BG image or solid
                                          _bg(imageUrl),

                                          // Faint grid
                                          Positioned.fill(
                                            child: CustomPaint(
                                              painter: _GridPainter(
                                                  cols: gridW, rows: gridH),
                                            ),
                                          ),

                                          // Room rectangles
                                          ..._roomRects(
                                            rooms: rooms,
                                            devices: devices,
                                            gridW: gridW,
                                            gridH: gridH,
                                            cellW: cellW,
                                            cellH: cellH,
                                          ),

                                          // Invisible drop targets
                                          for (int gx = 0; gx < gridW; gx++)
                                            for (int gy = 0; gy < gridH; gy++)
                                              Positioned(
                                                left: gx * cellW,
                                                top: gy * cellH,
                                                width: cellW,
                                                height: cellH,
                                                child: DragTarget<Device>(
                                                  onAcceptWithDetails: (d) {
                                                    _service.updateDevice(
                                                      widget.floorId,
                                                      d.data.id,
                                                      {'x': gx, 'y': gy},
                                                    );
                                                  },
                                                  builder:
                                                      (_, cands, __) =>
                                                          Container(
                                                    color: cands.isNotEmpty
                                                        ? _onColor
                                                            .withValues(alpha: 0.25)
                                                        : Colors.transparent,
                                                  ),
                                                ),
                                              ),

                                          // Device dots with labels
                                          for (final dev in devices)
                                            _deviceWidget(
                                              dev, gridW, gridH, cellW, cellH),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ── Legend ──
                        Container(
                          margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _leg(_onColor, 'ON'),
                              const SizedBox(width: 16),
                              _leg(_offColor, 'OFF'),
                              const SizedBox(width: 16),
                              _leg(_errColor, 'ERROR'),
                              const SizedBox(width: 16),
                              _leg(_dcColor, 'DISCONNECTED'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Background
  // ─────────────────────────────────────────────
  Widget _bg(String url) {
    if (url.isNotEmpty) {
      return Positioned.fill(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _solidBg()),
        ),
      );
    }
    return Positioned.fill(child: _solidBg());
  }

  Widget _solidBg() => Container(
        decoration: BoxDecoration(
          color: _pageBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _roomBdr.withValues(alpha: 0.4)),
        ),
      );

  // ─────────────────────────────────────────────
  //  Room rectangles with BIG labels
  // ─────────────────────────────────────────────
  List<Widget> _roomRects({
    required List<String> rooms,
    required List<Device> devices,
    required int gridW,
    required int gridH,
    required double cellW,
    required double cellH,
  }) {
    final List<Widget> out = [];
    final zones = [...rooms, 'Unassigned'];
    int emptySlot = 0;

    for (final zone in zones) {
      final isUn = zone == 'Unassigned';
      final zDevs = devices
          .where((d) =>
              isUn ? (d.room == null || d.room!.isEmpty) : d.room == zone)
          .toList();

      int x0, y0, x1, y1;

      if (zDevs.isEmpty) {
        if (isUn) continue;
        // Place empty rooms in a 3×2 slot across the bottom
        x0 = (emptySlot * 3) % gridW;
        y0 = gridH - 2;
        x1 = min(x0 + 2, gridW - 1);
        y1 = gridH - 1;
        emptySlot++;
      } else {
        x0 = gridW;
        y0 = gridH;
        x1 = 0;
        y1 = 0;
        for (final d in zDevs) {
          final dx = d.x.toInt().clamp(0, gridW - 1);
          final dy = d.y.toInt().clamp(0, gridH - 1);
          if (dx < x0) x0 = dx;
          if (dy < y0) y0 = dy;
          if (dx > x1) x1 = dx;
          if (dy > y1) y1 = dy;
        }
      }

      final bdr = isUn ? _dcColor.withValues(alpha: 0.5) : _roomBdr;
      final fill = isUn ? _dcColor.withValues(alpha: 0.04) : _roomFill;

      out.add(
        Positioned(
          left: x0 * cellW - 4,
          top: y0 * cellH - 4,
          width: (x1 - x0 + 1) * cellW + 8,
          height: (y1 - y0 + 1) * cellH + 8,
          child: Container(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: bdr, width: 1.5),
            ),
            padding: const EdgeInsets.only(left: 10, top: 8),
            alignment: Alignment.topLeft,
            child: Text(
              zone.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: isUn ? _dcColor : Colors.black38,
              ),
            ),
          ),
        ),
      );
    }
    return out;
  }

  // ─────────────────────────────────────────────
  //  Device dot + name label
  // ─────────────────────────────────────────────
  Widget _deviceWidget(
      Device dev, int gridW, int gridH, double cellW, double cellH) {
    final gx = dev.x.toInt().clamp(0, gridW - 1);
    final gy = dev.y.toInt().clamp(0, gridH - 1);
    final dotSz = min(cellW, cellH) * 0.45;
    final color = _dotColor(dev.status);

    Widget dot = Container(
      width: dotSz,
      height: dotSz,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.35), blurRadius: 6, spreadRadius: 1),
        ],
      ),
    );

    Widget label = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            dev.name,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    Widget tappable = GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => DeviceDetailSheet(device: dev, service: _service),
        );
      },
      child: label,
    );

    return Positioned(
      left: gx * cellW,
      top: gy * cellH,
      width: cellW,
      height: cellH,
      child: Center(
        child: Draggable<Device>(
          data: dev,
          feedback: Material(color: Colors.transparent, child: label),
          childWhenDragging: Opacity(opacity: 0.2, child: label),
          child: tappable,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  Widget _leg(Color c, String t) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(t,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.black45)),
        ],
      );
}

// ═══════════════════════════════════════════════
//  Grid painter
// ═══════════════════════════════════════════════
class _GridPainter extends CustomPainter {
  final int cols, rows;
  _GridPainter({required this.cols, required this.rows});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;
    final cw = size.width / cols;
    final ch = size.height / rows;
    for (int i = 1; i < cols; i++) {
      canvas.drawLine(Offset(i * cw, 0), Offset(i * cw, size.height), p);
    }
    for (int i = 1; i < rows; i++) {
      canvas.drawLine(Offset(0, i * ch), Offset(size.width, i * ch), p);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter o) =>
      o.cols != cols || o.rows != rows;
}
