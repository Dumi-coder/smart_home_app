import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A single bar in the chart: [label] under the axis, [value] in kWh.
class BarChartPoint {
  final String label;
  final double value;
  const BarChartPoint(this.label, this.value);
}

/// Lightweight bar chart, hand-painted with CustomPainter so the project
/// doesn't need an extra charting dependency. Tap a bar to see its value.
class EnergyBarChart extends StatefulWidget {
  final List<BarChartPoint> points;
  final double height;

  const EnergyBarChart({super.key, required this.points, this.height = 160});

  @override
  State<EnergyBarChart> createState() => _EnergyBarChartState();
}

class _EnergyBarChartState extends State<EnergyBarChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text('No data yet', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final maxValue = widget.points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final niceMax = maxValue <= 0 ? 1.0 : (maxValue * 1.25);

    return LayoutBuilder(
      builder: (context, constraints) {
        final barAreaHeight = widget.height - 24;
        final barWidth = constraints.maxWidth / (widget.points.length * 2);

        return SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              // Grid lines
              Positioned.fill(
                bottom: 24,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (i) => Container(height: 1, color: AppColors.divider)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(widget.points.length, (i) {
                  final point = widget.points[i];
                  final isSelected = _selected == i;
                  final barHeight = (point.value / niceMax) * barAreaHeight;

                  return GestureDetector(
                    onTap: () => setState(() => _selected = isSelected ? null : i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isSelected)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.textPrimary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${point.value.toStringAsFixed(1)} kWh',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          width: barWidth.clamp(10, 28),
                          height: barHeight <= 0 ? 2 : barHeight,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryActiveDark : AppColors.primaryActive,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: barWidth.clamp(10, 28) + 10,
                          child: Text(
                            point.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
