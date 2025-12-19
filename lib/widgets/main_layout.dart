import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'dart:ui';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/stats_screen.dart';
import '../ui/app_theme.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const StatsScreen(),
    const SettingsScreen(),
  ];

  bool _isDesktop() {
    return defaultTargetPlatform == TargetPlatform.windows ||
           defaultTargetPlatform == TargetPlatform.macOS ||
           defaultTargetPlatform == TargetPlatform.linux;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Allow background mesh to show
      body: Stack(
        children: [
          // Global Background Mesh
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.background,
              ),
              child: Stack(
                children: [
                  // Gradient Blob 1 (Top Left)
                  Positioned(
                    top: -100,
                    left: -100,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary.withOpacity(0.15),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                        child: Container(),
                      ),
                    ),
                  ),
                  // Gradient Blob 2 (Bottom Right)
                  Positioned(
                    bottom: -100,
                    right: -100,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.secondary.withOpacity(0.1),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                        child: Container(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Main Content
          Column(
            children: [
              if (_isDesktop())
                _buildWindowTitleBar(),
              Expanded(
                child: _screens[_currentIndex],
              ),
            ],
          ),

          // Floating Navigation Dock
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: _buildFloatingDock(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowTitleBar() {
    return WindowTitleBarBox(
      child: Row(
        children: [
          Expanded(
            child: MoveWindow(
              child: Container(
                padding: const EdgeInsets.only(left: 16),
                alignment: Alignment.centerLeft,
                child: Text(
                  'Focus Forge',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

    );
  }



  Widget _buildFloatingDock() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight.withOpacity(0.4),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDockItem(
                icon: Icons.timer_rounded,
                label: 'Focus',
                index: 0,
              ),
              const SizedBox(width: 8),
              _buildDockItem(
                icon: Icons.bar_chart_rounded,
                label: 'Stats',
                index: 1,
              ),
              const SizedBox(width: 8),
              _buildDockItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                index: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : AppTheme.textSecondary,
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}