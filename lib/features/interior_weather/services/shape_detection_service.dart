import 'dart:math' as math;
import 'dart:ui';

import 'package:milo/features/interior_weather/models/draw_point.dart';
import 'package:milo/features/interior_weather/services/weather_mood.dart';
import 'package:milo/shared/models/track_model.dart';

/// Détection basique de formes dessinées (bounding box + circularité).
class ShapeDetectionService {
  ShapeDetectionService._();

  static WeatherMood detect(List<DrawPoint> points) {
    if (points.length < 5) return WeatherMood.cloud;

    final bounds = _computeBounds(points);
    final width = bounds.width;
    final height = bounds.height;
    if (width < 10 || height < 10) return WeatherMood.cloud;

    final aspectRatio = width / height;
    final circularity = _circularity(points, bounds);
    final jaggedness = _jaggedness(points);

    // Rond → Soleil
    if (circularity > 0.65 && aspectRatio > 0.7 && aspectRatio < 1.4) {
      return WeatherMood.sunny;
    }

    // Trait brisé / zigzag → Éclair
    if (jaggedness > 0.45 || (height > width * 1.8 && jaggedness > 0.25)) {
      return WeatherMood.lightning;
    }

    // Forme horizontale douce → Pluie
    if (aspectRatio > 1.5 && jaggedness < 0.3) {
      return WeatherMood.rain;
    }

    return WeatherMood.cloud;
  }

  static List<TrackModel> filterTracks(
    List<TrackModel> tracks,
    WeatherMood mood,
  ) {
    return switch (mood) {
      WeatherMood.sunny => tracks
          .where((t) =>
              t.effectiveBpm >= 100 &&
              t.effectiveBpm <= 130 &&
              !t.isAggressive)
          .toList(),
      WeatherMood.lightning => tracks.where((t) => t.isAggressive).toList()
        ..sort((a, b) => b.effectiveBpm.compareTo(a.effectiveBpm)),
      WeatherMood.rain => tracks.where((t) => t.isCalm).toList(),
      WeatherMood.cloud => tracks,
    };
  }

  static Rect _computeBounds(List<DrawPoint> points) {
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;

    for (final p in points) {
      minX = math.min(minX, p.offset.dx);
      minY = math.min(minY, p.offset.dy);
      maxX = math.max(maxX, p.offset.dx);
      maxY = math.max(maxY, p.offset.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Ratio aire/périmètre² — proche de 1/(4π) pour un cercle.
  static double _circularity(List<DrawPoint> points, Rect bounds) {
    final area = bounds.width * bounds.height;
    if (area <= 0) return 0;

    var perimeter = 0.0;
    for (var i = 1; i < points.length; i++) {
      perimeter += (points[i].offset - points[i - 1].offset).distance;
    }

    if (perimeter <= 0) return 0;
    return (4 * math.pi * area) / (perimeter * perimeter);
  }

  /// Mesure les changements brusques de direction.
  static double _jaggedness(List<DrawPoint> points) {
    if (points.length < 3) return 0;

    var sharpTurns = 0;
    for (var i = 2; i < points.length; i++) {
      final v1 = points[i - 1].offset - points[i - 2].offset;
      final v2 = points[i].offset - points[i - 1].offset;
      if (v1.distance < 1 || v2.distance < 1) continue;

      final angle = v1.direction - v2.direction;
      if (angle.abs() > math.pi / 3) sharpTurns++;
    }

    return sharpTurns / points.length;
  }
}
