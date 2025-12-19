import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/settings_service.dart';
import '../providers/timer_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_auth_service.dart';
import '../screens/auth/sign_in_screen.dart';
import '../ui/app_theme.dart';

class SettingsForm extends ConsumerStatefulWidget {
  const SettingsForm({super.key});

  @override
  SettingsFormState createState() => SettingsFormState();
}

class SettingsFormState extends ConsumerState<SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  int _workDuration = 25;
  int _shortBreakDuration = 5;
  int _longBreakDuration = 15;
  bool _autoStartBreak = true;
  bool _autoStartWork = false;
  int _sessionsUntilLongBreak = 4;
  String? _focusSoundPath;
  String? _breakSoundPath;
  bool _isLoading = true;
  User? _currentUser;
  
  late TextEditingController _workDurationController;
  late TextEditingController _shortBreakDurationController;
  late TextEditingController _longBreakDurationController;
  late TextEditingController _sessionsController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadSettings();
    _checkCurrentUser();
    
    SupabaseAuthService().authStateChanges.listen((data) {
      if (mounted) {
        setState(() {
          _currentUser = data.session?.user;
        });
      }
    });
  }

  void _checkCurrentUser() {
    setState(() {
      _currentUser = SupabaseAuthService().currentUser;
    });
  }
  
  void _initializeControllers() {
    _workDurationController = TextEditingController(text: _workDuration.toString());
    _shortBreakDurationController = TextEditingController(text: _shortBreakDuration.toString());
    _longBreakDurationController = TextEditingController(text: _longBreakDuration.toString());
    _sessionsController = TextEditingController(text: _sessionsUntilLongBreak.toString());
  }
  
  @override
  void dispose() {
    _workDurationController.dispose();
    _shortBreakDurationController.dispose();
    _longBreakDurationController.dispose();
    _sessionsController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await SettingsService.loadSettings();
      if (mounted) {
        setState(() {
          _workDuration = settings['workDuration'];
          _shortBreakDuration = settings['shortBreakDuration'];
          _longBreakDuration = settings['longBreakDuration'];
          _autoStartBreak = settings['autoStartBreak'];
          _autoStartWork = settings['autoStartWork'];
          _sessionsUntilLongBreak = settings['sessionsUntilLongBreak'];
          _focusSoundPath = settings['focusSoundPath'];
          _breakSoundPath = settings['breakSoundPath'];
          _isLoading = false;
        });
        _updateControllers();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _updateControllers() {
    _workDurationController.text = _workDuration.toString();
    _shortBreakDurationController.text = _shortBreakDuration.toString();
    _longBreakDurationController.text = _longBreakDuration.toString();
    _sessionsController.text = _sessionsUntilLongBreak.toString();
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      await SettingsService.saveSettings(
        workDuration: _workDuration,
        shortBreakDuration: _shortBreakDuration,
        longBreakDuration: _longBreakDuration,
        autoStartBreak: _autoStartBreak,
        autoStartWork: _autoStartWork,
        sessionsUntilLongBreak: _sessionsUntilLongBreak,
        focusSoundPath: _focusSoundPath,
        breakSoundPath: _breakSoundPath,
      );

      if (mounted) {
        final timerService = ref.read(timerServiceProvider.notifier);
        timerService.updateSettings(
          newWorkDuration: _workDuration,
          newShortBreakDuration: _shortBreakDuration,
          newLongBreakDuration: _longBreakDuration,
          newAutoStartBreak: _autoStartBreak,
          newAutoStartWork: _autoStartWork,
          newSessionsUntilLongBreak: _sessionsUntilLongBreak,
          newFocusSoundPath: _focusSoundPath,
          newBreakSoundPath: _breakSoundPath,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settings saved', style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Timer Settings'),
          const SizedBox(height: 16),
          _buildDurationField(
            'Work Duration (minutes)',
            _workDuration,
            (value) => setState(() => _workDuration = value),
            controller: _workDurationController,
            icon: Icons.timer,
          ),
          const SizedBox(height: 12),
          _buildDurationField(
            'Short Break Duration (minutes)',
            _shortBreakDuration,
            (value) => setState(() => _shortBreakDuration = value),
            controller: _shortBreakDurationController,
            icon: Icons.coffee,
          ),
          const SizedBox(height: 12),
          _buildDurationField(
            'Long Break Duration (minutes)',
            _longBreakDuration,
            (value) => setState(() => _longBreakDuration = value),
            controller: _longBreakDurationController,
            icon: Icons.weekend,
          ),
          const SizedBox(height: 12),
          _buildDurationField(
            'Sessions Until Long Break',
            _sessionsUntilLongBreak,
            (value) => setState(() => _sessionsUntilLongBreak = value),
            min: 1,
            max: 10,
            controller: _sessionsController,
            icon: Icons.repeat,
          ),
          const SizedBox(height: 24),
          _buildSwitchField(
            'Auto-start Break',
            _autoStartBreak,
            (value) => setState(() => _autoStartBreak = value ?? true),
          ),
          const SizedBox(height: 8),
          _buildSwitchField(
            'Auto-start Work',
            _autoStartWork,
            (value) => setState(() => _autoStartWork = value ?? false),
          ),
          
          const SizedBox(height: 32),
          _buildSectionHeader('Notification Sounds'),
          const SizedBox(height: 16),
          _buildSoundPicker('Focus Sound', _focusSoundPath, (path) => setState(() => _focusSoundPath = path)),
          const SizedBox(height: 12),
          _buildSoundPicker('Break Sound', _breakSoundPath, (path) => setState(() => _breakSoundPath = path)),
          
          const SizedBox(height: 32),
          _buildSectionHeader('Account'),
          const SizedBox(height: 16),
          _buildAccountSection(),
          
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Save Settings'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _handleReset,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.withOpacity(0.5)),
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Reset to Defaults'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Reset Settings', style: GoogleFonts.outfit(color: AppTheme.textPrimary)),
        content: Text(
          'This will restore all timer settings to default values.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await SettingsService.resetToDefaults();
      if (mounted) {
        setState(() {
          _workDuration = 25;
          _shortBreakDuration = 5;
          _longBreakDuration = 15;
          _autoStartBreak = true;
          _autoStartWork = true;
          _sessionsUntilLongBreak = 4;
          _focusSoundPath = null;
          _breakSoundPath = null;
        });
        _updateControllers();
      }
      final timerService = ref.read(timerServiceProvider.notifier);
      timerService.updateSettings(
        newWorkDuration: 25,
        newShortBreakDuration: 5,
        newLongBreakDuration: 15,
        newAutoStartBreak: true,
        newAutoStartWork: true,
        newSessionsUntilLongBreak: 4,
        newFocusSoundPath: null,
        newBreakSoundPath: null,
      );
      timerService.resetTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Settings reset', style: GoogleFonts.inter())),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildDurationField(
    String label,
    int value,
    ValueChanged<int> onChanged, {
    int? min,
    int? max,
    TextEditingController? controller,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onSaved: (value) => onChanged(int.parse(value!)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchField(
    String label,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return SwitchListTile(
        title: Text(label, style: GoogleFonts.inter(color: AppTheme.textSecondary)),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );
  }

  Widget _buildSoundPicker(String label, String? currentPath, ValueChanged<String?> onPathChanged) {
    final hasCustomSound = currentPath != null && currentPath.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.background.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Text(
                    hasCustomSound ? currentPath.split(Platform.pathSeparator).last : 'Default Sound',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: hasCustomSound ? AppTheme.textPrimary : AppTheme.textSecondary,
                      fontStyle: hasCustomSound ? FontStyle.normal : FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (hasCustomSound) ...[
                IconButton(
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  tooltip: 'Preview',
                  color: AppTheme.primary,
                  onPressed: () => NotificationService.playPreview(currentPath),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Reset',
                  color: Colors.redAccent,
                  onPressed: () => onPathChanged(null),
                ),
              ] else ...[
                 IconButton(
                  icon: const Icon(Icons.folder_open_rounded),
                  color: AppTheme.primary,
                  onPressed: () async {
                    try {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.audio,
                        allowMultiple: false,
                      );
                      if (result != null) {
                        onPathChanged(result.files.single.path);
                      }
                    } catch (e) {
                       // Handle error
                    }
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: _currentUser != null ? Column(
        children: [
          Row(
            children: [
               Container(
                 padding: const EdgeInsets.all(2),
                 decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   border: Border.all(color: AppTheme.primary, width: 2),
                 ),
                 child: CircleAvatar(
                   backgroundColor: AppTheme.surface,
                   child: Text(
                     _currentUser!.email?[0].toUpperCase() ?? 'U',
                     style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                   ),
                 ),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       _currentUser!.email ?? 'User',
                       style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                     ),
                     Text(
                       'Signed in',
                       style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 12),
                     ),
                   ],
                 ),
               ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await SupabaseAuthService().signOut();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signed out')),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: BorderSide(color: AppTheme.textSecondary.withOpacity(0.3)),
              ),
              child: const Text('Sign Out'),
            ),
          ),
        ],
      ) : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sync your tasks',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to backup your tasks and sync across devices.',
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                );
              },
              child: const Text('Sign In / Sign Up'),
            ),
          ),
        ],
      ),
    );
  }
}