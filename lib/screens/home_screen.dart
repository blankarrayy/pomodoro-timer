import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../ui/app_theme.dart';
import '../widgets/timer_display.dart';
import '../widgets/control_buttons.dart';
import '../widgets/task_list.dart';
import '../widgets/stats_card.dart';
import '../widgets/mode_badge.dart';

import 'package:confetti/confetti.dart';
import '../providers/task_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late ConfettiController _confettiController;
  int _previousCompletedCount = 0;
  int _previousTotalCount = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for task completion changes
    ref.listen(tasksProvider, (previous, next) {
      final totalTasks = next.length;
      final completedTasks = next.where((t) => t.isCompleted).length;

      // Check if we just completed the last task
      if (totalTasks > 0 && 
          completedTasks == totalTasks && 
          completedTasks > _previousCompletedCount) {
        _confettiController.play();
      }

      _previousTotalCount = totalTasks;
      _previousCompletedCount = completedTasks;
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),
                // Greeting
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: _buildGreeting(),
                  ),
                ),
                
                // Mode Badge (Standard, not sticky)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: ModeBadge(),
                    ),
                  ),
                ),

                // Timer and Controls
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      const TimerDisplay(),
                      const SizedBox(height: 24),
                      const ControlButtons(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),

                // Task List (Standard list under controls)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: TaskList(),
                  ),
                ),
                
                // Additional padding at bottom for scrollability
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
          
          // Confetti Rain Overlay (Multiple emitters for "Rain" effect)
          if (_confettiController.state == ConfettiControllerState.playing)
            Positioned(
              top: -20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) {
                  return ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirection: pi / 2, // Down
                    emissionFrequency: 0.05,
                    numberOfParticles: 5, // Lighter per-emitter
                    maxBlastForce: 20,
                    minBlastForce: 10,
                    gravity: 0.2, // Floatier
                    shouldLoop: false,
                    colors: const [
                      Colors.green,
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                      Colors.purple,
                      Colors.cyan,
                    ],
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }



  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour >= 5 && hour < 12) {
      greeting = 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      greeting = 'Good Evening';
    } else {
      greeting = 'Good Night';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: GoogleFonts.outfit(
            fontSize: 26, // Reduced size
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          'Ready to focus?',
          style: GoogleFonts.outfit( // Consistent font
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

