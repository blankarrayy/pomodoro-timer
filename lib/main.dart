import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'dart:ui';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/main_layout.dart';
import 'ui/app_theme.dart';
import 'services/sync_orchestrator.dart';
import 'screens/settings_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/stats_storage.dart';
import 'services/desktop_overlay_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize Sync Orchestrator
  SyncOrchestrator().initialize();

  await StatsStorage.checkAndResetDailyStats();
  
  if (Platform.isWindows || Platform.isMacOS) {
    doWhenWindowReady(() {
      const initialSize = Size(430, 730);
      appWindow.minSize = initialSize;
      appWindow.maxSize = const Size(800, 1000);
      appWindow.size = initialSize;
      appWindow.alignment = Alignment.center;
      appWindow.show();
    });
  }

  // Initialize notifications in background without blocking UI
  NotificationService.initialize().catchError((e) {
    print('Error initializing notifications in main: $e');
  });

  // Initialize desktop overlay service for Windows and macOS
  if (Platform.isWindows || Platform.isMacOS) {
    DesktopOverlayService.initialize().catchError((e) {
      print('Error initializing desktop overlay service: $e');
    });
  }

  runApp(const ProviderScope(child: FocusForgeApp()));
}

class FocusForgeApp extends StatelessWidget {
  const FocusForgeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus Forge',
      theme: AppTheme.darkTheme,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),
      home: const SplashScreen(),
    );
  }
}
