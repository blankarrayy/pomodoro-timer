import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/session_stats.dart';
import '../services/stats_storage.dart';
import '../services/supabase_analytics_repository.dart';
import '../widgets/stats_display.dart';
import '../widgets/stats_chart.dart';
import '../providers/stats_provider.dart';
import '../ui/app_theme.dart';
import '../screens/stats_screen.dart'; // Import for StatsHistoryList if it's in the same file or I'll move it.
// Actually StatsHistoryList is inside stats_screen.dart at the bottom. I need to keep it or extract it.
// I can implement it inside this file as well.

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentStatsAsync = ref.watch(recentStatsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          
          // Breathable Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Analytics',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Track your focus journey',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Overview Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                'Overview', // Or "Today's Progress" to match StatsDisplay internal text
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),

          // Stats Display (Today)
          // I will use a simplified version of StatsDisplay logic here or just the widget if valid
          // But StatsDisplay layout is a bit boxy. Let's rely on breathable layout.
          SliverToBoxAdapter(
             child: Padding(
               padding: const EdgeInsets.symmetric(horizontal: 24),
               child: const StatsDisplay(), // We might need to unbox this too later.
             ),
          ),

          // Chart Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
               child: recentStatsAsync.when(
                data: (stats) => StatsChart(
                  stats: stats,
                  period: 'weekly',
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Could not load chart', style: TextStyle(color: Colors.redAccent)),
              ),
            ),
          ),

          // History Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, color: AppTheme.textPrimary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Session History',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // History List
          // Assuming StatsHistoryList handles its own loading etc.
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
               child: const StatsHistoryList(),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 16)), // Spacer

          // Reset Data Button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => _handleResetAnalytics(context, ref),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.delete_forever_rounded, size: 20),
                  label: Text(
                    'Reset Analytics Data',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Future<void> _handleResetAnalytics(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          'Reset Analytics?',
          style: GoogleFonts.outfit(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will permanently delete ALL your focus history from this device and the cloud. This action cannot be undone.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete Everything',
              style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Clear local
        await StatsStorage.clearAllStats();
        
        // Clear remote
        await SupabaseAnalyticsRepository().clearAllAnalytics();
        
        // Refresh providers (invalidate to force reload)
        ref.invalidate(recentStatsProvider);
        ref.invalidate(todayStatsProvider);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'All analytics data deleted.',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error deleting data: $e',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }
}

// I need to include StatsHistoryList here since it was defined in the same file originally
// and I am overwriting the file.

class StatsHistoryList extends StatelessWidget {
  const StatsHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    // Ideally this import exists: import '../services/stats_storage.dart';
    // And '../models/session_stats.dart';
    // Use FutureBuilder...
    // I will copy the implementation from the previous file content view.
     return FutureBuilder<List<SessionStats>>(
      future: StatsStorage.getAllStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading stats', style: TextStyle(color: Colors.redAccent)));
        }
        
        final allStats = snapshot.data ?? [];
        
        if (allStats.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No sessions yet',
                style: GoogleFonts.inter(color: AppTheme.textSecondary),
              ),
            ),
          );
        }
        
        return ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allStats.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildHistoryItem(context, allStats[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryItem(BuildContext context, SessionStats stats) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final statsDate = DateTime(stats.date.year, stats.date.month, stats.date.day);
    
    String dateLabel;
    if (statsDate == today) {
      dateLabel = 'Today';
    } else if (statsDate == yesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = '${stats.date.day}/${stats.date.month}';
    }
    
    final hours = stats.focusMinutes ~/ 60;
    final minutes = stats.focusMinutes % 60;
    String durationText = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: AppTheme.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${stats.completedSessions} sessions',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            durationText,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}