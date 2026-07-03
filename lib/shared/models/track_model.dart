/// Modèle unifié pour une piste audio locale.
class TrackModel {
  const TrackModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.uri,
    this.durationMs = 0,
    this.genre,
    this.bpm,
    this.artUri,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final String uri;
  final int durationMs;
  final String? genre;
  final int? bpm;
  final String? artUri;

  TrackModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? uri,
    int? durationMs,
    String? genre,
    int? bpm,
    String? artUri,
  }) {
    return TrackModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      uri: uri ?? this.uri,
      durationMs: durationMs ?? this.durationMs,
      genre: genre ?? this.genre,
      bpm: bpm ?? this.bpm,
      artUri: artUri ?? this.artUri,
    );
  }

  /// BPM estimé depuis le genre si absent des métadonnées.
  int get effectiveBpm {
    if (bpm != null) return bpm!;
    final g = (genre ?? '').toLowerCase();
    if (g.contains('metal') || g.contains('rock')) return 140;
    if (g.contains('electro') || g.contains('dance')) return 128;
    if (g.contains('jazz') || g.contains('ambient')) return 80;
    if (g.contains('classical')) return 70;
    return 110;
  }

  bool get isAggressive {
    final g = (genre ?? '').toLowerCase();
    return effectiveBpm >= 130 ||
        g.contains('metal') ||
        g.contains('punk') ||
        g.contains('hardcore');
  }

  bool get isCalm {
    final g = (genre ?? '').toLowerCase();
    return effectiveBpm <= 90 ||
        g.contains('jazz') ||
        g.contains('ambient') ||
        g.contains('classical');
  }
}
