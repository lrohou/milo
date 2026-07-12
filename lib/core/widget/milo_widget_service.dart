import 'package:home_widget/home_widget.dart';
import 'package:milo/core/audio/audio_handler.dart';

/// Synchronise l'état de lecture avec le widget écran d'accueil.
class MiloWidgetService {
  MiloWidgetService._();

  static const _androidProvider = 'MiloHomeWidgetProvider';

  static Future<void> init(MiloAudioHandler handler) async {
    await HomeWidget.setAppGroupId('group.com.milo.milo');
    HomeWidget.registerBackgroundCallback(_backgroundCallback);

    handler.currentTrackStream.listen((_) => _sync(handler));
    handler.playbackState.listen((_) => _sync(handler));
    await _sync(handler);
  }

  static Future<void> _sync(MiloAudioHandler handler) async {
    final track = handler.currentTrack;
    final isPlaying = handler.player.playing;

    await HomeWidget.saveWidgetData<String>(
      'title',
      track?.title ?? 'Milo',
    );
    await HomeWidget.saveWidgetData<String>(
      'artist',
      track?.artist ?? 'Lecteur local',
    );
    await HomeWidget.saveWidgetData<bool>('is_playing', isPlaying);

    await HomeWidget.updateWidget(
      name: _androidProvider,
      androidName: _androidProvider,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _backgroundCallback(Uri? uri) async {
    if (uri?.host != 'toggle_playback') return;

    final handler = await initAudioService();
    if (handler.player.playing) {
      await handler.pause();
    } else if (handler.currentTrack != null) {
      await handler.play();
    }
    await _sync(handler);
  }
}
