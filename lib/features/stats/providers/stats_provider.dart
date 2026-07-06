import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:milo/core/providers/audio_providers.dart';

final statsProvider = StateNotifierProvider<StatsNotifier, Map<String, int>>((ref) {
  final notifier = StatsNotifier();
  
  ref.listen(currentTrackProvider, (previous, next) {
    if (next.valueOrNull != null) {
      notifier.recordPlay(next.valueOrNull!.id);
    }
  });

  return notifier;
});

class StatsNotifier extends StateNotifier<Map<String, int>> {
  StatsNotifier() : super({}) {
    _loadStats();
  }

  SharedPreferences? _prefs;

  String get _currentMonthKey {
    final now = DateTime.now();
    return 'stats_${now.year}_${now.month.toString().padLeft(2, '0')}';
  }

  Future<void> _loadStats() async {
    _prefs ??= await SharedPreferences.getInstance();
    final jsonString = _prefs!.getString(_currentMonthKey);
    if (jsonString != null) {
      state = Map<String, int>.from(json.decode(jsonString));
    }
  }

  Future<void> recordPlay(String trackId) async {
    _prefs ??= await SharedPreferences.getInstance();
    final currentStats = Map<String, int>.from(state);
    currentStats[trackId] = (currentStats[trackId] ?? 0) + 1;
    state = currentStats;
    await _prefs!.setString(_currentMonthKey, json.encode(state));
  }
}
