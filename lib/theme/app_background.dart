import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Ambient gradient background used behind every main screen.
///
/// A soft radial "glow" — a bright sky-blue highlight drifting in from
/// the top-left, settling into the cooler powder-blue base. Reads like
/// ambient light rather than a block of color.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.85, -1.05),
          radius: 1.6,
          colors: [
            Color(0xFFDCEBFA), // bright sky-blue glow
            Color(0xFFE6EEF5), // cool neutral mid-tone
            Color(0xFFEAF1F8), // settles into base powder-blue
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: child,
    );
  }
}