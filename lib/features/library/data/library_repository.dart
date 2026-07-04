import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:milo/shared/models/track_model.dart';

/// Scan MP3/FLAC via on_audio_query avec gestion des permissions.
class LibraryRepository {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Demande les permissions et scanne la bibliothèque locale.
  Future<List<TrackModel>> scanLocalLibrary() async {
    final granted = await _requestPermissions();
    if (!granted) return _demoTracks();

    try {
      final songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      if (songs.isEmpty) return _demoTracks();

      final validSongs = songs.where((s) => (s.duration ?? 0) >= 30000).toList();
      if (validSongs.isEmpty) return _demoTracks();

      return validSongs.map(_mapSong).toList();
    } catch (_) {
      return _demoTracks();
    }
  }

  Future<bool> _requestPermissions() async {
    if (await Permission.audio.isGranted) return true;

    final status = await Permission.audio.request();
    if (status.isGranted) return true;

    // Fallback Android < 13
    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  TrackModel _mapSong(SongModel song) {
    return TrackModel(
      id: song.id.toString(),
      title: song.title,
      artist: song.artist ?? 'Artiste inconnu',
      album: song.album ?? 'Album inconnu',
      uri: song.uri ?? '',
      durationMs: song.duration ?? 0,
      genre: _guessGenre(song.title),
      bpm: _estimateBpm(song.title),
      artUri: song.id.toString(),
    );
  }

  /// Estimation heuristique du genre depuis le titre (placeholder ML).
  String? _guessGenre(String title) {
    final t = title.toLowerCase();
    if (t.contains('metal') || t.contains('rock')) return 'Rock';
    if (t.contains('jazz')) return 'Jazz';
    if (t.contains('electro') || t.contains('techno')) return 'Electro';
    if (t.contains('chill') || t.contains('ambient')) return 'Ambient';
    return null;
  }

  int? _estimateBpm(String title) {
    final t = title.toLowerCase();
    if (t.contains('slow') || t.contains('ballad')) return 70;
    if (t.contains('fast') || t.contains('sprint')) return 160;
    return null;
  }

  /// Pistes de démo pour développement sans permissions.
  List<TrackModel> _demoTracks() => const [
        TrackModel(
          id: 'demo_1',
          title: 'Sprint Basket',
          artist: 'Milo Beats',
          album: 'Terrain',
          uri: 'asset:///assets/demo/demo1.mp3',
          durationMs: 180000,
          genre: 'Electro',
          bpm: 165,
        ),
        TrackModel(
          id: 'demo_2',
          title: 'Jazz Café',
          artist: 'Milo Lounge',
          album: 'Pâture Zen',
          uri: 'asset:///assets/demo/demo2.mp3',
          durationMs: 240000,
          genre: 'Jazz',
          bpm: 85,
        ),
        TrackModel(
          id: 'demo_3',
          title: 'Metal Ruade',
          artist: 'Milo Rock',
          album: 'Ruade',
          uri: 'asset:///assets/demo/demo3.mp3',
          durationMs: 200000,
          genre: 'Metal',
          bpm: 150,
        ),
        TrackModel(
          id: 'demo_4',
          title: 'Soleil Majeur',
          artist: 'Milo Joy',
          album: 'Météo',
          uri: 'asset:///assets/demo/demo4.mp3',
          durationMs: 210000,
          genre: 'Pop',
          bpm: 120,
        ),
      ];
}
