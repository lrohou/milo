import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:milo/core/audio/equalizer_controller.dart';
import 'package:milo/shared/models/track_model.dart';

/// Handler audio principal — lecture arrière-plan + contrôles notification.
class MiloAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  MiloAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  late final EqualizerController equalizer = EqualizerController(_player);
  final List<TrackModel> _tracks = [];
  int _currentIndex = 0;

  /// Stream réactif du morceau en cours (TrackModel).
  final _currentTrackController = StreamController<TrackModel?>.broadcast();
  Stream<TrackModel?> get currentTrackStream => _currentTrackController.stream;

  AudioPlayer get player => _player;
  int get currentIndex => _currentIndex;

  /// Charge la file d'attente depuis la bibliothèque locale.
  Future<void> loadQueue(List<TrackModel> tracks, {int startIndex = 0}) async {
    _tracks
      ..clear()
      ..addAll(tracks);
    _currentIndex = startIndex.clamp(0, _tracks.length - 1);

    queue.add(
      _tracks
          .map(
            (t) => MediaItem(
              id: t.id,
              title: t.title,
              artist: t.artist,
              album: t.album,
              duration: Duration(milliseconds: t.durationMs),
              artUri: t.artUri != null ? Uri.parse(t.artUri!) : null,
            ),
          )
          .toList(),
    );

    if (_tracks.isNotEmpty) {
      await _loadTrack(_currentIndex);
    }
  }

  /// Remplace la file par les morceaux à BPM élevé (Rythme du Terrain).
  Future<void> switchToHighBpmQueue(List<TrackModel> allTracks) async {
    if (allTracks.isEmpty) return;
    final sorted = [...allTracks]..sort(
        (a, b) => b.effectiveBpm.compareTo(a.effectiveBpm),
      );
    await loadQueue(sorted.take(20).toList());
    await play();
  }

  Future<void> _loadTrack(int index) async {
    if (index < 0 || index >= _tracks.length) return;
    _currentIndex = index;
    final track = _tracks[index];

    mediaItem.add(
      MediaItem(
        id: track.id,
        title: track.title,
        artist: track.artist,
        album: track.album,
        duration: Duration(milliseconds: track.durationMs),
        artUri: track.artUri != null ? Uri.parse(track.artUri!) : null,
      ),
    );

    await _player.setAudioSource(
      AudioSource.uri(Uri.parse(track.uri)),
    );
    await equalizer.apply();
    _currentTrackController.add(track);
  }

  TrackModel? get currentTrack =>
      _tracks.isEmpty ? null : _tracks[_currentIndex];

  List<TrackModel> get tracks => List.unmodifiable(_tracks);

  @override
  Future<void> play() async {
    await _player.play();
    playbackState.add(_buildState(true));
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    playbackState.add(_buildState(false));
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_tracks.isEmpty) return;
    final next = (_currentIndex + 1) % _tracks.length;
    await _loadTrack(next);
    await play();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_tracks.isEmpty) return;
    final prev = (_currentIndex - 1 + _tracks.length) % _tracks.length;
    await _loadTrack(prev);
    await play();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    await _loadTrack(index);
    await play();
  }

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(_buildState(_player.playing));
  }

  PlaybackState _buildState(bool playing) {
    final processingState = const {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[_player.processingState]!;

    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: processingState,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
    );
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await super.onTaskRemoved();
  }

  Future<void> dispose() async {
    await _player.dispose();
    await _currentTrackController.close();
  }
}

/// Point d'entrée pour initialiser audio_service en arrière-plan.
Future<MiloAudioHandler> initAudioService() async {
  return AudioService.init(
    builder: MiloAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.milo.audio',
      androidNotificationChannelName: 'Milo — Lecture en cours',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/launcher_icon',
    ),
  );
}
