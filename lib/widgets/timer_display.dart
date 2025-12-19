import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/timer_provider.dart';
import '../ui/app_theme.dart';

class TimerDisplay extends ConsumerWidget {
  const TimerDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerServiceProvider);
    
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < 0) {
          // Swipe Left -> Next Mode
          ref.read(timerServiceProvider.notifier).nextMode();
        } else if (details.primaryVelocity! > 0) {
          // Swipe Right -> Previous Mode
          ref.read(timerServiceProvider.notifier).previousMode();
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          
          // Timer Text with Glow
          Stack(
            children: [
              // Glow effect
              Text(
                '${timerState.minutes}:${timerState.seconds.toString().padLeft(2, '0')}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 100,
                  fontWeight: FontWeight.bold,
                  height: 1,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 4
                    ..color = _getModeColor(timerState).withOpacity(0.1),
                ),
              ),
              // Actual Text
              Text(
                '${timerState.minutes}:${timerState.seconds.toString().padLeft(2, '0')}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 100,
                  fontWeight: FontWeight.bold,
                  height: 1,
                  color: AppTheme.textPrimary,
                  shadows: [
                    Shadow(
                      color: _getModeColor(timerState).withOpacity(0.5),
                      blurRadius: 30,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Progress Bar
          SizedBox(
            width: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: timerState.progress,
                minHeight: 6,
                backgroundColor: AppTheme.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(_getModeColor(timerState)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getModeColor(dynamic timerState) {
    if (timerState.isBreak) {
      return AppTheme.tertiary; // Cyan/Blue for break
    }
    return AppTheme.primary; // Indigo for focus
  }
}