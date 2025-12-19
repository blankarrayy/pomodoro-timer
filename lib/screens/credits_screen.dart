import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import '../ui/app_theme.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Credits', style: GoogleFonts.outfit(color: AppTheme.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.background,
                  AppTheme.surface,
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 48, color: AppTheme.primary),
                        const SizedBox(height: 24),
                        Text(
                          'Attribution',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        _buildSectionHeader('Sound Effects'),
                        const SizedBox(height: 16),
                        _buildAttributionItem(
                          context,
                          'Alarm Sound',
                          'Sound Effect by ',
                          'Jeremay Jimenez',
                          'https://pixabay.com/users/jeremayjimenez-28887262/?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=450782',
                          ' from ',
                          'Pixabay',
                          'https://pixabay.com/sound-effects//?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=450782',
                        ),

                        const SizedBox(height: 32),
                        _buildSectionHeader('Open Source Libraries'),
                        const SizedBox(height: 16),
                        Text(
                          'This application uses multiple open source libraries. We are grateful to the open source community for their contributions.',
                          style: GoogleFonts.inter(color: AppTheme.textSecondary, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            showLicensePage(
                              context: context,
                              applicationName: 'Focus Forge',
                              applicationVersion: '1.0.0',
                              applicationIcon: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset('assets/logo.png', width: 48, height: 48), // Assuming logo exists
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.surfaceLight,
                            foregroundColor: AppTheme.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('View Open Source Licenses', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 2,
          width: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.5),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _buildAttributionItem(
    BuildContext context,
    String title,
    String prefix,
    String author,
    String authorUrl,
    String middle,
    String source,
    String sourceUrl,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.inter(color: AppTheme.textSecondary, height: 1.5),
              children: [
                TextSpan(text: prefix),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: InkWell(
                    onTap: () => _launchUrl(authorUrl),
                    child: Text(
                      author,
                      style: GoogleFonts.inter(
                        color: AppTheme.primary,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                TextSpan(text: middle),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: InkWell(
                    onTap: () => _launchUrl(sourceUrl),
                    child: Text(
                      source,
                      style: GoogleFonts.inter(
                        color: AppTheme.primary,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
