import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../widgets/settings_form.dart';
import '../ui/app_theme.dart';
import 'credits_screen.dart';
import '../providers/task_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            
            // Breathable Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                          'Settings',
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Customize your focus experience',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                         IconButton(
                          onPressed: () => _showResetDialog(context, ref),
                          icon: Icon(Icons.delete_forever_rounded, color: Colors.red.withOpacity(0.7), size: 24),
                          tooltip: 'Reset Local Data',
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CreditsScreen()),
                            );
                          },
                          icon: Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary.withOpacity(0.7), size: 24),
                          tooltip: 'Credits',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Settings Form acts as the scrollable content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const SettingsForm(),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Future<void> _showResetDialog(BuildContext context, WidgetRef ref) async {
    // Lazy import provider if needed, or assume it's available via consumer
    // We need to import task_provider.dart at top of file, let's assume it is or add it
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Reset Local Data?', style: GoogleFonts.outfit(color: AppTheme.textPrimary)),
        content: Text(
          'This will wipe all tasks and stats from this device. It will NOT delete data from the cloud unless it syncs later. This is effectively a "Fresh Install" state.',
          style: GoogleFonts.outfit(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(taskProvider.notifier).clearAllLocalData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All local data has been reset.')),
                );
              }
            },
            child: Text('Reset', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}