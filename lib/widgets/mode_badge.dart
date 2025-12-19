
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/timer_provider.dart';
import '../ui/app_theme.dart';

class ModeBadge extends ConsumerWidget {
  const ModeBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerServiceProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getModeColor(timerState).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getModeColor(timerState).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getModeIcon(timerState),
            size: 16,
            color: _getModeColor(timerState),
          ),
          const SizedBox(width: 8),
          Text(
            _getModeText(timerState),
            style: GoogleFonts.outfit(
              color: _getModeColor(timerState),
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getModeText(dynamic timerState) {
    if (timerState.isBreak) {
      return timerState.isLongBreak ? 'LONG BREAK' : 'SHORT BREAK';
    }
    return 'FOCUS MODE';
  }

  IconData _getModeIcon(dynamic timerState) {
    if (timerState.isBreak) {
      return timerState.isLongBreak ? Icons.spa_rounded : Icons.coffee_rounded;
    }
    return Icons.bolt_rounded;
  }

  Color _getModeColor(dynamic timerState) {
    if (timerState.isBreak) {
      return AppTheme.tertiary; // Cyan/Blue for break
    }
    return AppTheme.primary; // Indigo for focus
  }
}
