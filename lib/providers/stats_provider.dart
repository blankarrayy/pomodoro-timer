import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/stats_storage.dart';
import '../models/session_stats.dart';

// Provider for the selected time period
class SelectedPeriodNotifier extends Notifier<String> {
  @override
  String build() => 'daily';
  
  void setPeriod(String period) {
    state = period;
  }
}

final selectedPeriodProvider = NotifierProvider<SelectedPeriodNotifier, String>(() {
  return SelectedPeriodNotifier();
});

// Provider for all statistics data
final statsProvider = FutureProvider.family<SessionStats, String>((ref, period) async {
  return StatsStorage.loadStats(period);
});

final todayStatsProvider = FutureProvider<SessionStats>((ref) async {
  return StatsStorage.getTodayStats();
});

// Provider for the last 7 days of stats for the chart
final recentStatsProvider = FutureProvider<List<SessionStats>>((ref) async {
  final allStats = await StatsStorage.getAllStats();
  final now = DateTime.now();
  final last7Days = List.generate(7, (index) {
    final date = now.subtract(Duration(days: 6 - index));
    final dateStart = DateTime(date.year, date.month, date.day);
    
    return allStats.firstWhere(
      (s) => s.date.year == dateStart.year && 
             s.date.month == dateStart.month && 
             s.date.day == dateStart.day,
      orElse: () => SessionStats(
        date: dateStart,
        focusMinutes: 0,
        completedSessions: 0,
      ),
    );
  });
  return last7Days;
});

