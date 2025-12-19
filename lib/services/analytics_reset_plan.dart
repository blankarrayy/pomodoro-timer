
// Plan:
// 1. SupabaseAnalyticsRepository:
//    - Add `clearAllAnalytics()` method to delete all records for the current user.
//      `await _client.from('analytics_sessions').delete().eq('user_id', user.id);`
//
// 2. StatsStorage:
//    - Already has `clearAllStats()`. No change needed.
//
// 3. StatsScreen:
//    - Add a "Reset Statistics" button at the bottom of the CustomScrollView (SliverToBoxAdapter).
//    - On press:
//      - Show confirmation dialog.
//      - Call `StatsStorage.clearAllStats()`.
//      - Call `SupabaseAnalyticsRepository().clearAllAnalytics()`.
//      - Refresh the UI (invalidate providers).
//      - Show success/error snackbar.
//
// 4. StatsProvider:
//    - I might need to refresh `recentStatsProvider` and `todayStatsProvider` after deletion.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/stats_storage.dart';
// import '../providers/stats_provider.dart';

class SupabaseAnalyticsRepository {
   final SupabaseClient _client = Supabase.instance.client;
   
   // ... existing methods ...

   Future<void> clearAllAnalytics() async {
     final user = _client.auth.currentUser;
     if (user == null) return;
     
     try {
       await _client.from('analytics_sessions').delete().eq('user_id', user.id);
       print('All remote analytics cleared for user ${user.id}');
     } catch (e) {
       print('Error clearing remote analytics: $e');
       rethrow;
     }
   }
}
