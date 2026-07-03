import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Service « Rythme du Terrain » — détecte les pics d'effort via accéléromètre.
class RhythmTerrainService {
  RhythmTerrainService({
    this.sprintThreshold = 18.0,
    this.calibrationSamples = 30,
  });

  /// Seuil de magnitude (m/s²) pour un sprint/saut basket.
  final double sprintThreshold;
  final int calibrationSamples;

  StreamSubscription<AccelerometerEvent>? _subscription;
  final _effortController = StreamController<double>.broadcast();
  final _sprintController = StreamController<void>.broadcast();

  double _baseline = 9.81;
  int _calibrationCount = 0;
  double _calibrationSum = 0;
  bool _isActive = false;

  Stream<double> get effortStream => _effortController.stream;
  Stream<void> get sprintDetectedStream => _sprintController.stream;

  bool get isActive => _isActive;

  /// Démarre l'écoute de l'accéléromètre.
  void start() {
    if (_isActive) return;
    _isActive = true;
    _calibrationCount = 0;
    _calibrationSum = 0;

    _subscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen(_onAccelerometerEvent);
  }

  void stop() {
    _isActive = false;
    _subscription?.cancel();
    _subscription = null;
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    // Phase de calibration : mesure le repos
    if (_calibrationCount < calibrationSamples) {
      _calibrationSum += magnitude;
      _calibrationCount++;
      if (_calibrationCount == calibrationSamples) {
        _baseline = _calibrationSum / calibrationSamples;
      }
      return;
    }

    final delta = (magnitude - _baseline).abs();
    _effortController.add(delta);

    // Pic d'effort : sprint ou saut détecté
    if (delta >= sprintThreshold) {
      HapticFeedback.heavyImpact();
      _sprintController.add(null);
    }
  }

  void dispose() {
    stop();
    _effortController.close();
    _sprintController.close();
  }
}
