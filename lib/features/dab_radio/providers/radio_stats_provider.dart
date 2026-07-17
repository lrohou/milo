import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:milo/core/providers/audio_providers.dart';

/// Provider des stats d'écoute des radios DAB+.
final radioStatsProvider = StateNotifierProvider<RadioStatsNotifier, Map<String, int>>((ref) {
  final notifier = RadioStatsNotifier();

  ref.listen(currentTrackProvider, (previous, next) {
    final media = next.valueOrNull;
    if (media != null && media.extras?['isRadio'] == true) {
      notifier.recordListen(media.id);
    }
  });

  return notifier;
});

class RadioStatsNotifier extends StateNotifier<Map<String, int>> {
  RadioStatsNotifier() : super({}) {
    _load();
  }

  static const _prefsKey = 'radio_listen_stats';
  SharedPreferences? _prefs;

  Future<void> _load() async {
    _prefs ??= await SharedPreferences.getInstance();
    final jsonStr = _prefs!.getString(_prefsKey);
    if (jsonStr != null) {
      state = Map<String, int>.from(jsonDecode(jsonStr));
    }
  }

  Future<void> recordListen(String stationId) async {
    _prefs ??= await SharedPreferences.getInstance();
    final current = Map<String, int>.from(state);
    current[stationId] = (current[stationId] ?? 0) + 1;
    state = current;
    await _prefs!.setString(_prefsKey, jsonEncode(state));
  }
}
