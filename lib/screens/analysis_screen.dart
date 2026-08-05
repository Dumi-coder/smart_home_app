import 'package:flutter/material.dart';
import '../models/energy_reading.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/energy_bar_chart.dart';
import '../widgets/energy_donut_chart.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

enum _RangeMode { week, month }

class _AnalysisScreenState extends State<AnalysisScreen> {
  final FirestoreService _service = FirestoreService();
  _RangeMode _mode = _RangeMode.week;

  static const List<Color> _roomColors = [
    AppColors.primaryActiveDark,
    Color(0xFF81C784),
    Color(0xFFFFB74D),
    Color(0xFF64B5F6),
    Color(0xFFBA68C8),
  ];

  static const List<String> _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const List<String> _monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<EnergyReading>>(
          stream: _service.streamEnergyUsage(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryActiveDark));
            }
            final readings = snap.data!;
            final now = DateTime.now();

            final todayTotal = readings
                .where((r) => _isSameDay(r.date, now))
                .fold<double>(0, (sum, r) => sum + r.kWh);

            final thisMonth = readings.where((r) => r.date.year == now.year && r.date.month == now.month);
            final monthlyTotal = thisMonth.fold<double>(0, (sum, r) => sum + r.kWh);

            final lastMonthDate = DateTime(now.year, now.month - 1, 1);
            final lastMonth = readings.where(
                (r) => r.date.year == lastMonthDate.year && r.date.month == lastMonthDate.month);
            final lastMonthTotal = lastMonth.fold<double>(0, (sum, r) => sum + r.kWh);
            final percentChange = lastMonthTotal > 0
                ? ((monthlyTotal - lastMonthTotal) / lastMonthTotal * 100)
                : 0.0;

            final barPoints = _mode == _RangeMode.week
                ? _weeklyBars(readings, now)
                : _monthlyBars(readings, now);

            final roomTotals = <String, double>{};
            for (final r in thisMonth.isEmpty ? readings : thisMonth) {
              roomTotals[r.room] = (roomTotals[r.room] ?? 0) + r.kWh;
            }
            final roomEntries = roomTotals.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            final deviceTotals = <String, double>{};
            for (final r in thisMonth.isEmpty ? readings : thisMonth) {
              deviceTotals[r.device] = (deviceTotals[r.device] ?? 0) + r.kWh;
            }
            final topConsumers = deviceTotals.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildTopStats(todayTotal, monthlyTotal, percentChange),
                const SizedBox(height: 16),
                _buildUsageOverview(barPoints),
                const SizedBox(height: 16),
                if (roomEntries.isNotEmpty) _buildRoomComparison(roomEntries),
                const SizedBox(height: 16),
                if (topConsumers.isNotEmpty) _buildTopConsumers(topConsumers),
              ],
            );
          },
        ),
      ),
    );
  }

  List<BarChartPoint> _weeklyBars(List<EnergyReading> readings, DateTime now) {
    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    return List.generate(7, (i) {
      final day = start.add(Duration(days: i));
      final total = readings
          .where((r) => _isSameDay(r.date, day))
          .fold<double>(0, (sum, r) => sum + r.kWh);
      return BarChartPoint(_weekdayLabels[day.weekday - 1], total);
    });
  }

  List<BarChartPoint> _monthlyBars(List<EnergyReading> readings, DateTime now) {
    // Last 4 weekly buckets (7-day sums going back 28 days).
    final points = <BarChartPoint>[];
    for (int w = 3; w >= 0; w--) {
      final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: (w * 7) + 6));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final total = readings
          .where((r) =>
              !r.date.isBefore(weekStart) && !r.date.isAfter(weekEnd))
          .fold<double>(0, (sum, r) => sum + r.kWh);
      points.add(BarChartPoint('${weekStart.day} ${_monthLabels[weekStart.month - 1]}', total));
    }
    return points;
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Energy Reports', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text(
              '${_monthLabels[now.month - 1]} ${now.year}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              const Icon(Icons.file_download_outlined, size: 15, color: AppColors.textPrimary),
              const SizedBox(width: 6),
              const Text('Export', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopStats(double today, double monthly, double percentChange) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.bolt,
            iconBg: AppColors.textPrimary,
            label: "Today's Usage",
            value: '${today.toStringAsFixed(1)}',
            unit: 'kWh · \$${(today * 0.15).toStringAsFixed(2)} est.',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: percentChange <= 0 ? Icons.trending_down : Icons.trending_up,
            iconBg: AppColors.background,
            iconColor: AppColors.textPrimary,
            label: 'Monthly Total',
            value: monthly.toStringAsFixed(0),
            unit: '${percentChange <= 0 ? '' : '+'}${percentChange.toStringAsFixed(0)}% vs last month',
            unitColor: percentChange <= 0 ? AppColors.primaryActiveDark : AppColors.statusError,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconBg,
    Color iconColor = Colors.white,
    required String label,
    required String value,
    required String unit,
    Color? unitColor,
  }) {
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(unit, style: TextStyle(fontSize: 11, color: unitColor ?? AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildUsageOverview(List<BarChartPoint> points) {
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
              const Text('Usage Overview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              _buildModeToggle(),
            ],
          ),
          const SizedBox(height: 16),
          EnergyBarChart(points: points),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          _toggleBtn('Week', _RangeMode.week),
          _toggleBtn('Month', _RangeMode.month),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, _RangeMode mode) {
    final isSelected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildRoomComparison(List<MapEntry<String, double>> roomEntries) {
    final total = roomEntries.fold<double>(0, (sum, e) => sum + e.value);
    final slices = List.generate(
      roomEntries.length,
      (i) => DonutSlice(roomEntries[i].key, roomEntries[i].value, _roomColors[i % _roomColors.length]),
    );

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
          const Text('Room Comparison', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              EnergyDonutChart(slices: slices),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: roomEntries.asMap().entries.map((entry) {
                    final i = entry.key;
                    final room = entry.value;
                    final pct = total > 0 ? (room.value / total * 100) : 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _roomColors[i % _roomColors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(room.key, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                          ),
                          Text(
                            '${pct.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopConsumers(List<MapEntry<String, double>> topConsumers) {
    final maxVal = topConsumers.first.value;
    final shown = topConsumers.take(5).toList();

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
              const Text('Top Consumers', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              Text('See all', style: TextStyle(fontSize: 12.5, color: AppColors.primaryActiveDark, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          ...shown.map((entry) {
            final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${entry.value.toStringAsFixed(1)} kWh', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: AppColors.background,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primaryActive),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
