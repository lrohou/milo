import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/core/audio/audio_handler.dart';

/// Provider global du handler audio Milo.
final audioHandlerProvider = Provider<MiloAudioHandler>((ref) {
  throw UnimplementedError(
    'audioHandlerProvider doit être overridé dans main.dart',
  );
});

/// Morceau en cours de lecture.
final currentTrackProvider = StreamProvider((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.mediaItem.map((item) => item);
});

/// État lecture/pause.
final playbackStateProvider = StreamProvider((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.playbackState;
});
