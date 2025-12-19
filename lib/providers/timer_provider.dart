import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/timer_service.dart';
import '../models/timer_state.dart';
import 'stats_provider.dart';

final timerServiceProvider = NotifierProvider<TimerService, TimerState>(() {
  return TimerService();
});
