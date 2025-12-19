import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../ui/app_theme.dart';

class StatsCard extends StatelessWidget {
  final int completedSessions;
  final int totalFocusTime;

  const StatsCard({
    super.key,
    required this.completedSessions,
    required this.totalFocusTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            label: 'Sessions',
            value: completedSessions.toString(),
            icon: Icons.check_circle_outline_rounded,
            color: AppTheme.secondary,
          ),
        ),
        Container(
          width: 1,
          height: 48,
          color: Colors.white.withOpacity(0.1),
        ),
        Expanded(
          child: _buildStatItem(
            label: 'Focus Time',
            value: '${totalFocusTime}m',
            icon: Icons.timer_outlined,
            color: AppTheme.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}