
// Plan:
// 1. SupabaseAnalyticsRepository:
//    - Change logic to `upsert` sessions instead of checking and inserting.
//    - Ensure (user_id, start_time) is a unique constraint in DB (I can't change DB schema here easily but upsert relies on it). 
//    - If constraint doesn't exist, I must improve the "check existing" logic to be robust. 
//      Wait, I can't guarantee DB constraints from here. 
//      Better approach: DELETE existing sessions for the day before inserting new ones?
//      OR: Fetch all, diff, and only insert true new ones.
//      The current logic *tries* to check existing start times. 
//      The issue might be `existingData` fetch is filtering by time range incorrectly or `toIso8601String()` mismatch.
//      safest fix given I can't touch DB schema: 
//      Fetch ALL sessions for the day. Delete them. Re-insert the current full set. 
//      This guarantees no duplicates and updates existing.
//      Actually, `delete().eq()...` then `insert()` is a valid strategy for "syncing a whole day".

// 2. TaskList Overflow:
//    - The error `RenderFlex overflowed by 8.0 pixels` likely happens in `_buildEmptyState` when the keyboard is up or screen is small.
//    - Wrap the Column in `_buildEmptyState` with `SingleChildScrollView` or `Center(child: ...)` with `MainAxisSize.min` and check constraints. 
//    - Actually, `TaskList` -> `Column` -> `Expanded` -> `TabBarView` -> `_buildEmptyState`.
//    - `_buildEmptyState` returns a `Center(child: Column(...))`.
//    - Converting to `ListView` (scrollable) is safer.

// 3. SettingsForm:
//    - Remove `Container` decoration from `_buildDurationField` and `_buildSwitchField`.
//    - Keep the inputs themselves (the pill) but remove the row background.
//    - Use `Divider` between items for separation if needed, or just whitespace.

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
      // Strategy: Delete existing records for this day and re-insert.
      // This is atomic enough for a single user device and robust against duplicates.
      await _client.from('analytics_sessions')
          .delete()
          .eq('user_id', user.id)
          .gte('start_time', startOfDay.toIso8601String())
          .lte('start_time', endOfDay.toIso8601String());

      final List<Map<String, dynamic>> records = [];
      
      for (int i = 0; i < stats.focusSessions.length; i++) {
        final duration = stats.focusSessions[i];
        // Deterministic start times
        final sessionTime = startOfDay.add(Duration(minutes: i * 30)); // Spread them out or keep sequential?
        // Using `i` minutes spreading is risky if they overlap? 
        // Logic was `Duration(minutes: i)`. If sessions are long, this is fake data anyway.
        // Let's stick to the previous logic but just re-insert.
        final sessionTimeReal = startOfDay.add(Duration(minutes: i)); // Fake start times
        
        records.add({
          'user_id': user.id,
          'start_time': sessionTimeReal.toIso8601String(),
          'end_time': sessionTimeReal.add(duration).toIso8601String(),
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

  // fetchDailyStats remains same...
}
