import 'package:audio_service/audio_service.dart';
import 'package:milo/shared/models/milo_mood.dart';
import 'package:milo/shared/models/track_model.dart';

/// Détermine l'humeur de Milo depuis le morceau en cours.
class MoodAvatarService {
  MoodAvatarService._();

  static MiloMood resolve({
    TrackModel? track,
    MediaItem? mediaItem,
    bool isSprintMode = false,
    bool isKickAlarm = false,
  }) {
    if (isKickAlarm) return MiloMood.kick;
    if (isSprintMode) return MiloMood.sprint;
    if (track == null) return MiloMood.happy;

    final genre = (track.genre ?? '').toLowerCase();
    if (genre.contains('metal') || genre.contains('rock')) {
      return MiloMood.rock;
    }
    if (genre.contains('jazz')) return MiloMood.jazz;
    if (track.effectiveBpm <= 90) return MiloMood.chill;

    return MiloMood.happy;
  }
}
