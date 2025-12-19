import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/session_stats.dart';

class SupabaseAnalyticsRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> syncDailyStats(SessionStats stats) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final dateStr = stats.date.toIso8601String().split('T')[0];
    final startOfDay = DateTime.parse(dateStr).toUtc();
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));

    try {
      // Strategy: Delete existing records for this day to perform a clean sync
      // This prevents duplicates if sync is retried or if local data changes
      await _client.from('analytics_sessions')
          .delete()
          .eq('user_id', user.id)
          .gte('start_time', startOfDay.toIso8601String())
          .lte('start_time', endOfDay.toIso8601String());

      final List<Map<String, dynamic>> records = [];
      
      for (int i = 0; i < stats.focusSessions.length; i++) {
        final duration = stats.focusSessions[i];
        // Deterministic start time for each session for distinctiveness
        // We space them out by 1 second + index to ensure uniqueness even if durations are 0
        final sessionTime = startOfDay.add(Duration(seconds: i));
        
        records.add({
          'user_id': user.id,
          'start_time': sessionTime.toIso8601String(),
          'end_time': sessionTime.add(duration).toIso8601String(),
          'duration': duration.inSeconds,
          'focus_mode': 'focus',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      if (records.isNotEmpty) {
        await _client.from('analytics_sessions').insert(records);
        print('Synced ${records.length} analytics sessions for $dateStr');
      }
      
    } catch (e) {
      print('Error syncing analytics for $dateStr: $e');
    }
  }

  Future<void> clearAllAnalytics() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.from('analytics_sessions').delete().eq('user_id', user.id);
      print('All remote analytics cleared for user ${user.id}');
    } catch (e) {
      print('Error clearing remote analytics: $e');
      // Rethrow so UI knows it failed
      rethrow; 
    }
  }

  Future<SessionStats> fetchDailyStats(DateTime date) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return SessionStats(date: date, focusMinutes: 0, completedSessions: 0);
    }

    final dateStr = date.toIso8601String().split('T')[0];
    final startOfDay = DateTime.parse(dateStr).toUtc();
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));

    try {
      final response = await _client.from('analytics_sessions')
          .select()
          .eq('user_id', user.id)
          .gte('start_time', startOfDay.toIso8601String())
          .lte('start_time', endOfDay.toIso8601String());

      final sessions = response as List;
      final focusSessions = sessions.map((s) => Duration(seconds: s['duration'] as int)).toList();
      final totalMinutes = focusSessions.fold(0, (sum, dur) => sum + dur.inMinutes);

      return SessionStats(
        date: date,
        focusMinutes: totalMinutes,
        completedSessions: sessions.length,
        focusSessions: focusSessions,
      );
    } catch (e) {
      print('Error fetching remote analytics: $e');
      return SessionStats(date: date, focusMinutes: 0, completedSessions: 0);
    }
  }
}
