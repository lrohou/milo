import 'dart:math' as math;

import 'package:milo/shared/models/track_model.dart';

/// Cluster K-means local — regroupe les pistes par ambiance.
/// Prêt à recevoir un modèle ML externe via [injectClusters].
class PastureClusteringService {
  PastureClusteringService({this.clusterCount = 4});

  final int clusterCount;
  List<PastureCluster>? _cachedClusters;

  /// Features normalisées : [bpm, durationMinutes, genreHash]
  List<List<double>> extractFeatures(List<TrackModel> tracks) {
    return tracks.map((t) {
      final genreCode = _genreToCode(t.genre ?? 'Unknown');
      return [
        t.effectiveBpm / 200.0,
        (t.durationMs / 60000.0).clamp(0, 10) / 10.0,
        genreCode,
      ];
    }).toList();
  }

  /// K-means simplifié — 10 itérations max.
  List<PastureCluster> clusterTracks(List<TrackModel> tracks) {
    if (tracks.isEmpty) return [];
    if (_cachedClusters != null &&
        _cachedClusters!.length == tracks.length) {
      return _cachedClusters!;
    }

    final features = extractFeatures(tracks);
    final k = clusterCount.clamp(2, math.min(6, tracks.length)).toInt();
    final centroids = _initCentroids(features, k);

    for (var iter = 0; iter < 10; iter++) {
      final assignments = List<int>.filled(features.length, 0);
      for (var i = 0; i < features.length; i++) {
        var bestDist = double.infinity;
        for (var c = 0; c < k; c++) {
          final dist = _euclidean(features[i], centroids[c]);
          if (dist < bestDist) {
            bestDist = dist;
            assignments[i] = c;
          }
        }
      }

      for (var c = 0; c < k; c++) {
        final members =
            features.where((f) => assignments[features.indexOf(f)] == c);
        if (members.isEmpty) continue;
        for (var d = 0; d < features[0].length; d++) {
          centroids[c][d] =
              members.map((m) => m[d]).reduce((a, b) => a + b) / members.length;
        }
      }
    }

    // Regroupement final
    final clusters = List.generate(k, (c) {
      final members = <TrackModel>[];
      for (var i = 0; i < tracks.length; i++) {
        var best = 0;
        var bestDist = double.infinity;
        for (var ci = 0; ci < k; ci++) {
          final dist = _euclidean(features[i], centroids[ci]);
          if (dist < bestDist) {
            bestDist = dist;
            best = ci;
          }
        }
        if (best == c) members.add(tracks[i]);
      }
      return PastureCluster(
        id: c,
        label: _labelForCluster(members),
        tracks: members,
        centerX: 0.2 + (c % 2) * 0.5,
        centerY: 0.2 + (c ~/ 2) * 0.4,
      );
    }).where((c) => c.tracks.isNotEmpty).toList();

    _cachedClusters = clusters;
    return clusters;
  }

  void injectClusters(List<PastureCluster> clusters) {
    _cachedClusters = clusters;
  }

  void clearCache() => _cachedClusters = null;

  List<List<double>> _initCentroids(List<List<double>> features, int k) {
    final rng = math.Random(42);
    return List.generate(
      k,
      (_) => features[rng.nextInt(features.length)],
    );
  }

  double _euclidean(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += (a[i] - b[i]) * (a[i] - b[i]);
    }
    return math.sqrt(sum);
  }

  double _genreToCode(String genre) {
    final g = genre.toLowerCase();
    if (g.contains('electro')) return 0.9;
    if (g.contains('rock') || g.contains('metal')) return 0.8;
    if (g.contains('jazz')) return 0.3;
    if (g.contains('ambient') || g.contains('chill')) return 0.1;
    return 0.5;
  }

  String _labelForCluster(List<TrackModel> members) {
    if (members.isEmpty) return 'Pâture vide';
    final avgBpm =
        members.map((t) => t.effectiveBpm).reduce((a, b) => a + b) /
            members.length;
    if (avgBpm >= 130) return 'Électro Sprint';
    if (avgBpm >= 110) return 'Énergie';
    if (avgBpm >= 90) return 'Balade';
    return 'Chill Zen';
  }
}

class PastureCluster {
  const PastureCluster({
    required this.id,
    required this.label,
    required this.tracks,
    required this.centerX,
    required this.centerY,
  });

  final int id;
  final String label;
  final List<TrackModel> tracks;
  final double centerX;
  final double centerY;
}
