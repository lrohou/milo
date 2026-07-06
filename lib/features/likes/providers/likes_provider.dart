import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider qui gère les "likes" (liste d'IDs de pistes aimées).
final likesProvider = StateNotifierProvider<LikesNotifier, Set<String>>((ref) {
  return LikesNotifier();
});

class LikesNotifier extends StateNotifier<Set<String>> {
  LikesNotifier() : super({}) {
    _load();
  }

  SharedPreferences? _prefs;

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final jsonString = _prefs!.getString('liked_track_ids');
    if (jsonString != null) {
      final list = List<String>.from(json.decode(jsonString));
      state = list.toSet();
    }
  }

  Future<void> toggleLike(String trackId) async {
    _prefs ??= await SharedPreferences.getInstance();
    final updated = Set<String>.from(state);
    if (updated.contains(trackId)) {
      updated.remove(trackId);
    } else {
      updated.add(trackId);
    }
    state = updated;
    await _prefs!.setString('liked_track_ids', json.encode(updated.toList()));
  }

  bool isLiked(String trackId) => state.contains(trackId);
}
