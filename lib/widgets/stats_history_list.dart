import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/stats_storage.dart';
import '../models/session_stats.dart';

class StatsHistoryList extends ConsumerStatefulWidget {
  const StatsHistoryList({super.key});

  @override
  ConsumerState<StatsHistoryList> createState() => _StatsHistoryListState();
}

class _StatsHistoryListState extends ConsumerState<StatsHistoryList> {
  List<SessionStats> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await StatsStorage.getAllStats();
      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading stats history: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    }
    return '${remainingMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_history.isEmpty) {
      return Center(
        child: Text(
          'No history available',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    return Column(
      children: _history.map((stats) {
        return Column(
          children: [
            _buildHistoryItem(
              context,
              date: DateFormat.yMMMd().format(stats.date),
              sessions: stats.completedSessions,
              duration: _formatDuration(stats.focusMinutes),
            ),
            if (stats != _history.last) const Divider(height: 32),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context, {
    required String date,
    required int sessions,
    required String duration,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            date,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Expanded(
          child: Text(
            '$sessions sessions',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Text(
          duration,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
} 