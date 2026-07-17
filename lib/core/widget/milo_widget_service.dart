import 'package:home_widget/home_widget.dart';
import 'package:milo/core/audio/audio_handler.dart';

/// Synchronise l'état de lecture avec les widgets écran d'accueil.
class MiloWidgetService {
  MiloWidgetService._();

  static const _androidMiniPlayer = 'MiloHomeWidgetProvider';
  static const _androidControls = 'MiloControlsWidgetProvider';
  static const _androidQuickAccess = 'MiloQuickAccessWidgetProvider';

  static Future<void> init(MiloAudioHandler handler) async {
    try {
      await HomeWidget.setAppGroupId('group.com.milo.milo');
      HomeWidget.registerBackgroundCallback(_backgroundCallback);

      // Sync initiale pour que les widgets affichent quelque chose immédiatement
      await _sync(handler);

      // Écouter les changements
      handler.currentTrackStream.listen((_) => _sync(handler));
      handler.playbackState.listen((_) => _sync(handler));
      handler.mediaItem.listen((_) => _sync(handler));
    } catch (e) {
      // Widget init failed silently - app should still work
    }
  }

  static Future<void> _sync(MiloAudioHandler handler) async {
    try {
      final mediaItem = handler.mediaItem.valueOrNull;
      final isPlaying = handler.player.playing;

      await HomeWidget.saveWidgetData<String>(
        'title',
        mediaItem?.title ?? 'Milo',
      );
      await HomeWidget.saveWidgetData<String>(
        'artist',
        mediaItem?.artist ?? 'Lecteur local',
      );
      await HomeWidget.saveWidgetData<bool>('is_playing', isPlaying);

      // Mettre à jour tous les widgets
      await HomeWidget.updateWidget(
        name: _androidMiniPlayer,
        androidName: _androidMiniPlayer,
      );
      await HomeWidget.updateWidget(
        name: _androidControls,
        androidName: _androidControls,
      );
      await HomeWidget.updateWidget(
        name: _androidQuickAccess,
        androidName: _androidQuickAccess,
      );
    } catch (e) {
      // Widget sync failed - non-critical
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _backgroundCallback(Uri? uri) async {
    try {
      final host = uri?.host;
      if (host == null) return;

      final handler = await initAudioService();

      switch (host) {
        case 'toggle_playback':
          if (handler.player.playing) {
            await handler.pause();
          } else {
            await handler.play();
          }
          break;

        case 'skip_previous':
          await handler.skipToPrevious();
          break;

        case 'skip_next':
          await handler.skipToNext();
          break;

        case 'shuffle_all':
        case 'play_favorites':
        case 'open_library':
        case 'open_radio':
          // Ces actions nécessitent l'app en premier plan
          break;
      }

      await _sync(handler);
    } catch (e) {
      // Background callback error - non-critical
    }
  }
}
