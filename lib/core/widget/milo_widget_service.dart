import 'package:home_widget/home_widget.dart';
import 'package:milo/core/audio/audio_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Synchronise l'état de lecture avec les widgets écran d'accueil.
class MiloWidgetService {
  MiloWidgetService._();

  static const _androidMiniPlayer = 'MiloHomeWidgetProvider';
  static const _androidControls = 'MiloControlsWidgetProvider';
  static const _androidQuickAccess = 'MiloQuickAccessWidgetProvider';

  static Future<void> init(MiloAudioHandler handler) async {
    await HomeWidget.setAppGroupId('group.com.milo.milo');
    HomeWidget.registerBackgroundCallback(_backgroundCallback);

    handler.currentTrackStream.listen((_) => _sync(handler));
    handler.playbackState.listen((_) => _sync(handler));
    handler.mediaItem.listen((_) => _sync(handler));
    await _sync(handler);
  }

  static Future<void> _sync(MiloAudioHandler handler) async {
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
  }

  @pragma('vm:entry-point')
  static Future<void> _backgroundCallback(Uri? uri) async {
    final host = uri?.host;
    if (host == null) return;

    final handler = await initAudioService();
    final prefs = await SharedPreferences.getInstance();

    switch (host) {
      case 'toggle_playback':
        if (handler.player.playing) {
          await handler.pause();
        } else if (handler.currentTrack != null || handler.isRadioMode) {
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
        // Charger la bibliothèque et lancer en lecture aléatoire
        await _loadAndShuffleLibrary(handler, prefs);
        break;

      case 'play_favorites':
        // Charger les favoris et les jouer
        await _loadAndPlayFavorites(handler, prefs);
        break;

      case 'open_library':
      case 'open_radio':
        // Ces actions ouvrent l'app via deep link
        // L'app gère la navigation en fonction de l'URI
        break;
    }

    await _sync(handler);
  }

  /// Charge la bibliothèque depuis les préférences et lance en mode shuffle.
  static Future<void> _loadAndShuffleLibrary(
    MiloAudioHandler handler,
    SharedPreferences prefs,
  ) async {
    try {
      final libraryJson = prefs.getString('cached_library');
      if (libraryJson == null) return;

      final List<dynamic> decoded = jsonDecode(libraryJson);
      if (decoded.isEmpty) return;

      // Mélanger et jouer
      decoded.shuffle();
      // Note: On ne peut pas charger directement la bibliothèque ici
      // car on n'a pas accès aux TrackModel complets depuis le background
      // L'action va ouvrir l'app qui gèrera le shuffle
    } catch (e) {
      // Erreur silencieuse
    }
  }

  /// Charge les favoris et lance la lecture.
  static Future<void> _loadAndPlayFavorites(
    MiloAudioHandler handler,
    SharedPreferences prefs,
  ) async {
    try {
      final likesJson = prefs.getString('likes');
      if (likesJson == null) return;

      final List<dynamic> likedIds = jsonDecode(likesJson);
      if (likedIds.isEmpty) return;

      // Note: Idem, on ouvre l'app pour gérer la lecture des favoris
    } catch (e) {
      // Erreur silencieuse
    }
  }
}
