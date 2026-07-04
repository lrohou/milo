import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/core/providers/audio_providers.dart';
import 'package:milo/features/library/providers/library_providers.dart';
import 'package:milo/features/rhythm_terrain/services/rhythm_terrain_service.dart';

final rhythmTerrainServiceProvider = Provider<RhythmTerrainService>((ref) {
  final service = RhythmTerrainService();
  ref.onDispose(service.dispose);
  return service;
});

/// Active/désactive le mode sport.
final rhythmTerrainActiveProvider = StateProvider<bool>((ref) => false);

/// Niveau d'effort courant (0 = repos, >18 = sprint).
final effortLevelProvider = StreamProvider<double>((ref) {
  final service = ref.watch(rhythmTerrainServiceProvider);
  return service.effortStream;
});

/// Écoute les sprints et bascule vers les BPM élevés.
final rhythmTerrainControllerProvider = Provider<void>((ref) {
  final active = ref.watch(rhythmTerrainActiveProvider);
  final service = ref.watch(rhythmTerrainServiceProvider);

  if (active) {
    service.start();
    final sub = service.sprintDetectedStream.listen((_) async {
      final library = ref.read(libraryProvider).valueOrNull ?? [];
      final handler = ref.read(audioHandlerProvider);
      await handler.startTerrainRhythmMode(library);
    });
    ref.onDispose(sub.cancel);
  } else {
    service.stop();
    final handler = ref.read(audioHandlerProvider);
    handler.stopTerrainRhythmMode();
  }
});
