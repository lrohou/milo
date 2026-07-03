import 'package:just_audio/just_audio.dart';

/// État de l'égaliseur « Grandes Oreilles ».
class EqualizerState {
  const EqualizerState({
    this.bass = 0.0,
    this.treble = 0.0,
    this.pan = 0.0,
    this.leftEarStretch = 1.0,
    this.rightEarStretch = 1.0,
  });

  /// -1.0 (min) à 1.0 (max)
  final double bass;
  final double treble;
  final double pan;
  final double leftEarStretch;
  final double rightEarStretch;

  EqualizerState copyWith({
    double? bass,
    double? treble,
    double? pan,
    double? leftEarStretch,
    double? rightEarStretch,
  }) {
    return EqualizerState(
      bass: bass ?? this.bass,
      treble: treble ?? this.treble,
      pan: pan ?? this.pan,
      leftEarStretch: leftEarStretch ?? this.leftEarStretch,
      rightEarStretch: rightEarStretch ?? this.rightEarStretch,
    );
  }
}

/// Contrôle bass/treble/pan et applique les effets sur le lecteur audio.
class EqualizerController {
  EqualizerController(this._player);

  final AudioPlayer _player;
  EqualizerState _state = const EqualizerState();

  EqualizerState get state => _state;

  /// Applique les réglages au pipeline audio.
  /// Note: just_audio ne propose pas d'EQ natif ; le pitch simule les aigus,
  /// le volume compensé simule les basses. Pan via balance (Android/iOS).
  Future<void> apply() async {
    // Treble → léger pitch shift (0.95 à 1.05)
    final pitch = 1.0 + (_state.treble * 0.05);
    await _player.setPitch(pitch.clamp(0.9, 1.1));

    // Bass → volume boost subtil
    final volume = (1.0 + _state.bass * 0.15).clamp(0.5, 1.0);
    await _player.setVolume(volume);

    // Pan : valeur stockée pour l'UI ; intégration native (AudioBalance) à brancher
    // via platform channel sur Android Equalizer / iOS AVAudioEngine.
  }

  Future<void> setBass(double value) async {
    _state = _state.copyWith(
      bass: value.clamp(-1.0, 1.0),
      leftEarStretch: 1.0 + value.abs() * 0.3,
      rightEarStretch: 1.0 + value.abs() * 0.3,
    );
    await apply();
  }

  Future<void> setTreble(double value) async {
    _state = _state.copyWith(
      treble: value.clamp(-1.0, 1.0),
      leftEarStretch: 1.0 + value * 0.2,
    );
    await apply();
  }

  Future<void> setPan(double value) async {
    _state = _state.copyWith(
      pan: value.clamp(-1.0, 1.0),
      leftEarStretch: 1.0 + (value < 0 ? -value * 0.25 : 0),
      rightEarStretch: 1.0 + (value > 0 ? value * 0.25 : 0),
    );
    await apply();
  }

  void resetVisualDeformation() {
    _state = _state.copyWith(
      leftEarStretch: 1.0,
      rightEarStretch: 1.0,
    );
  }
}
