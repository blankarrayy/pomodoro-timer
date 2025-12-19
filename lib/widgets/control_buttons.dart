import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/timer_provider.dart';
import '../ui/app_theme.dart';

class ControlButtons extends ConsumerWidget {
  const ControlButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerServiceProvider);
    final timerService = ref.read(timerServiceProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButton(
          context: context,
          icon: Icons.refresh_rounded,
          onPressed: () => timerService.resetTimer(),
          isSecondary: true,
        ),
        const SizedBox(width: 24),
        _buildButton(
          context: context,
          icon: timerState.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          onPressed: () => timerService.toggleTimer(),
          isPrimary: true,
          size: 72,
          iconSize: 32,
        ),
        const SizedBox(width: 24),
        _buildButton(
          context: context,
          icon: Icons.skip_next_rounded,
          onPressed: () => timerService.nextMode(),
          isSecondary: true,
        ),
      ],
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isSecondary = false,
    double size = 56,
    double iconSize = 24,
  }) {
    final color = isPrimary ? AppTheme.primary : AppTheme.textPrimary;
    final backgroundColor = isPrimary 
      ? AppTheme.primary 
      : AppTheme.surfaceLight.withOpacity(0.5);

    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: color,
          padding: EdgeInsets.zero,
          elevation: isPrimary ? 8 : 0,
          shadowColor: isPrimary ? AppTheme.primary.withOpacity(0.4) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: isSecondary 
              ? BorderSide(color: Colors.white.withOpacity(0.1)) 
              : BorderSide.none,
          ),
        ),
        child: Icon(
          icon, 
          size: iconSize,
          color: isPrimary ? Colors.white : AppTheme.textSecondary,
        ),
      ),
    );
  }
}