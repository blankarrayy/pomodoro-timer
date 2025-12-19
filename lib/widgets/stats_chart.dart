import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/session_stats.dart';
import '../ui/app_theme.dart';

class StatsChart extends StatelessWidget {
  final List<SessionStats> stats;
  final String period;

  const StatsChart({
    super.key,
    required this.stats,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    double maxY = 60;
    if (stats.isNotEmpty) {
      final maxMinutes = stats.map((s) => s.focusMinutes).reduce((a, b) => a > b ? a : b);
      if (maxMinutes > 60) maxY = maxMinutes.toDouble() * 1.2;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.bar_chart_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Last 7 Days',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 60,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppTheme.textSecondary.withOpacity(0.1),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 60,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${(value / 60).toStringAsFixed(0)}h',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value >= stats.length) return const SizedBox();
                      final date = stats[value.toInt()].date;
                      final today = DateTime.now();
                      
                      String label;
                      if (date.day == today.day && date.month == today.month) {
                        label = 'Today';
                      } else {
                        const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        label = weekdays[date.weekday - 1];
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          label,
                          style: GoogleFonts.inter(
                            color: value.toInt() == stats.length - 1 
                                ? AppTheme.primary 
                                : AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: value.toInt() == stats.length - 1 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: _generateSpots(),
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: AppTheme.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: AppTheme.background,
                        strokeWidth: 2,
                        strokeColor: AppTheme.primary,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primary.withOpacity(0.2),
                        AppTheme.primary.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppTheme.surfaceLight,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final minutes = spot.y.toInt();
                      final hours = minutes ~/ 60;
                      final mins = minutes % 60;
                      return LineTooltipItem(
                        '${hours}h ${mins}m',
                        GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
                handleBuiltInTouches: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<FlSpot> _generateSpots() {
    return List.generate(
      stats.length,
      (index) => FlSpot(
        index.toDouble(),
        stats[index].focusMinutes.toDouble(),
      ),
    );
  }
}