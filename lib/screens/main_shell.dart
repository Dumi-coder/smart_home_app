import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_background.dart';
import 'home_screen.dart';
import 'camera_screen.dart';
import 'analysis_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

/// Main app shell with floating pill-shaped bottom navigation bar.
/// Holds 5 tabs: Home, Cameras, Analytics, Notifications, Profile.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CameraScreen(),
    AnalysisScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      extendBody: true,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.navBarBackground,
        borderRadius: BorderRadius.circular(AppRadius.navBar),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_filled, 'Home', 0),
          _navItem(Icons.videocam_outlined, 'Cameras', 1),
          _navItem(Icons.bar_chart_rounded, 'Analytics', 2),
          _navItem(Icons.notifications_outlined, 'Alerts', 3),
          _navItem(Icons.person_outline, 'Profile', 4),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 10,
        ),
        decoration: isActive
            ? BoxDecoration(
          color: AppColors.navBarActiveIcon.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive
                  ? AppColors.navBarActiveIcon
                  : AppColors.navBarInactiveIcon,
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.navBarActiveIcon,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}