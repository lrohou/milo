import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/core/audio/audio_handler.dart';
import 'package:milo/core/audio/equalizer_controller.dart';
import 'package:milo/core/providers/audio_providers.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/shared/widgets/glass_card.dart';
import 'package:milo/shared/widgets/neo_brutal_button.dart';

/// Provider de l'état visuel de l'égaliseur « Grandes Oreilles ».
final equalizerStateProvider =
    StateProvider<EqualizerState>((ref) => const EqualizerState());

/// Égaliseur interactif — tête de Milo avec oreilles déformables et animations fluides.
class MiloEqualizerWidget extends ConsumerStatefulWidget {
  const MiloEqualizerWidget({super.key});

  @override
  ConsumerState<MiloEqualizerWidget> createState() =>
      _MiloEqualizerWidgetState();
}

class _MiloEqualizerWidgetState extends ConsumerState<MiloEqualizerWidget>
    with TickerProviderStateMixin {
  bool _isInteracting = false;

  // Valeurs animées avec gravité
  double _leftEarAngle = 0.0;
  double _rightEarAngle = 0.0;
  double _leftEarVelocity = 0.0;
  double _rightEarVelocity = 0.0;

  // Angle de repos — les oreilles penchent naturellement vers l'avant
  static const double _restAngleLeft = 0.25;
  static const double _restAngleRight = -0.25;

  late final AnimationController _glowController;
  late final AnimationController _gravityController;

  // Pour le geste unifié (scale)
  Offset _lastFocalPoint = Offset.zero;
  double _lastScale = 1.0;

  MiloAudioHandler get _handler => ref.read(audioHandlerProvider);

  @override
  void initState() {
    super.initState();
    // Initialiser les oreilles à leur angle de repos
    _leftEarAngle = _restAngleLeft;
    _rightEarAngle = _restAngleRight;

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _gravityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateGravity);
    _gravityController.repeat();
  }

  void _updateGravity() {
    if (!_isInteracting) {
      // Gravité : retour vers l'angle de repos avec bounce
      const gravity = 0.008;
      const damping = 0.92;

      // Oreille gauche tend vers _restAngleLeft
      _leftEarVelocity += -(_leftEarAngle - _restAngleLeft) * gravity;
      _leftEarVelocity *= damping;
      _leftEarAngle += _leftEarVelocity;

      // Oreille droite tend vers _restAngleRight
      _rightEarVelocity += -(_rightEarAngle - _restAngleRight) * gravity;
      _rightEarVelocity *= damping;
      _rightEarAngle += _rightEarVelocity;

      if ((_leftEarAngle - _restAngleLeft).abs() < 0.001 &&
          _leftEarVelocity.abs() < 0.001) {
        _leftEarAngle = _restAngleLeft;
        _leftEarVelocity = 0.0;
      }
      if ((_rightEarAngle - _restAngleRight).abs() < 0.001 &&
          _rightEarVelocity.abs() < 0.001) {
        _rightEarAngle = _restAngleRight;
        _rightEarVelocity = 0.0;
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _glowController.dispose();
    _gravityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eqState = ref.watch(equalizerStateProvider);

    return Column(
      children: [
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            height: 320,
            width: double.infinity,
            // Geste unifié : onScale gère à la fois le drag 1 doigt et le pinch 2 doigts
            child: GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: _onScaleEnd,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _MiloEarsPainter(
                    bass: eqState.bass,
                    treble: eqState.treble,
                    pan: eqState.pan,
                    leftEarStretch: eqState.leftEarStretch,
                    rightEarStretch: eqState.rightEarStretch,
                    leftEarAngle: _leftEarAngle,
                    rightEarAngle: _rightEarAngle,
                    glowIntensity: _isInteracting
                        ? 0.6 + _glowController.value * 0.4
                        : 0.0,
                    isInteracting: _isInteracting,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _EqualizerLabels(eqState: eqState),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            NeoBrutalButton(
              label: 'Lent',
              icon: Icons.speed_rounded,
              backgroundColor: eqState.speed < 1.0 ? AppColors.yellowVivid : AppColors.backgroundSurface,
              foregroundColor: eqState.speed < 1.0 ? AppColors.backgroundDeep : AppColors.cream,
              onPressed: () {
                HapticFeedback.mediumImpact();
                _handler.equalizer.setSpeed(0.5);
                ref.read(equalizerStateProvider.notifier).state = _handler.equalizer.state;
              },
            ),
            NeoBrutalButton(
              label: 'Rapide',
              icon: Icons.fast_forward_rounded,
              backgroundColor: eqState.speed > 1.0 ? AppColors.yellowVivid : AppColors.backgroundSurface,
              foregroundColor: eqState.speed > 1.0 ? AppColors.backgroundDeep : AppColors.cream,
              onPressed: () {
                HapticFeedback.mediumImpact();
                _handler.equalizer.setSpeed(1.5);
                ref.read(equalizerStateProvider.notifier).state = _handler.equalizer.state;
              },
            ),
            NeoBrutalButton(
              label: 'Reset',
              icon: Icons.refresh_rounded,
              backgroundColor: AppColors.backgroundSurface,
              foregroundColor: AppColors.cream,
              onPressed: () {
                HapticFeedback.heavyImpact();
                _handler.equalizer.resetAll();
                _leftEarAngle = _restAngleLeft;
                _rightEarAngle = _restAngleRight;
                _leftEarVelocity = 0;
                _rightEarVelocity = 0;
                ref.read(equalizerStateProvider.notifier).state = _handler.equalizer.state;
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '↕ Tirer les oreilles  ·  Pincer = Pan',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.cream.withValues(alpha: 0.6),
              ),
          textAlign: TextAlign.center,
        )
            .animate(target: _isInteracting ? 1 : 0)
            .fadeIn(duration: 300.ms),
      ],
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.localFocalPoint;
    _lastScale = 1.0;
    setState(() => _isInteracting = true);
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    final focalPoint = details.localFocalPoint;
    final deltaY = focalPoint.dy - _lastFocalPoint.dy;
    _lastFocalPoint = focalPoint;

    // Si on pince (2 doigts), gérer le pan
    if ((details.scale - 1.0).abs() > 0.01) {
      HapticFeedback.lightImpact();
      try {
        final panDelta = (details.scale - _lastScale) * 2;
        _lastScale = details.scale;
        final pan = (ref.read(equalizerStateProvider).pan + panDelta)
            .clamp(-1.0, 1.0);
        await _handler.equalizer.setPan(pan);
        ref.read(equalizerStateProvider.notifier).state =
            _handler.equalizer.state;
      } catch (_) {
        // Silently handle if audio handler isn't ready
      }
      return;
    }

    // Sinon, drag vertical (1 doigt) → bass ou treble
    HapticFeedback.selectionClick();
    // delta positif = doigt vers le bas → diminuer (tirer vers bas = diminuer)
    // delta négatif = doigt vers le haut → augmenter (tirer vers haut = augmenter)
    final valueDelta = -deltaY / 100;

    try {
      final current = ref.read(equalizerStateProvider);
      final halfWidth = (context.size?.width ?? 300) / 2;

      if (focalPoint.dx < halfWidth) {
        // Oreille gauche → basses
        _leftEarAngle = (_leftEarAngle + deltaY / 50).clamp(-1.5, 1.5);
        _leftEarVelocity = deltaY / 200;
        final bass = (current.bass + valueDelta).clamp(-1.0, 1.0);
        await _handler.equalizer.setBass(bass);
      } else {
        // Oreille droite → aigus
        _rightEarAngle = (_rightEarAngle + deltaY / 50).clamp(-1.5, 1.5);
        _rightEarVelocity = deltaY / 200;
        final treble = (current.treble + valueDelta).clamp(-1.0, 1.0);
        await _handler.equalizer.setTreble(treble);
      }
      ref.read(equalizerStateProvider.notifier).state = _handler.equalizer.state;
    } catch (_) {
      // Silently handle if audio handler isn't ready
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    // Donner une vélocité de "lâcher" aux oreilles
    final vel = details.velocity.pixelsPerSecond.dy / 2000;
    _leftEarVelocity = vel * 0.5;
    _rightEarVelocity = vel * 0.5;
    setState(() => _isInteracting = false);
  }
}

class _EqualizerLabels extends StatelessWidget {
  const _EqualizerLabels({required this.eqState});

  final EqualizerState eqState;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _LabelChip(label: 'Basses', value: eqState.bass, icon: Icons.graphic_eq_rounded),
        _LabelChip(label: 'Aigus', value: eqState.treble, icon: Icons.equalizer_rounded),
        _LabelChip(label: 'Pan', value: eqState.pan, icon: Icons.surround_sound_rounded),
      ],
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.label, required this.value, required this.icon});

  final String label;
  final double value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isActive = value.abs() > 0.05;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.yellowVivid.withValues(alpha: 0.15)
            : AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.yellowVivid : AppColors.border,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: isActive ? AppColors.yellowVivid : AppColors.cream, size: 18),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            '${(value * 100).round()}%',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.yellowVivid,
                ),
          ),
        ],
      ),
    );
  }
}

/// Peint la tête de Milo (âne) avec grandes oreilles 3D, effet de gravité.
class _MiloEarsPainter extends CustomPainter {
  _MiloEarsPainter({
    required this.bass,
    required this.treble,
    required this.pan,
    required this.leftEarStretch,
    required this.rightEarStretch,
    required this.leftEarAngle,
    required this.rightEarAngle,
    required this.glowIntensity,
    required this.isInteracting,
  });

  final double bass;
  final double treble;
  final double pan;
  final double leftEarStretch;
  final double rightEarStretch;
  final double leftEarAngle;
  final double rightEarAngle;
  final double glowIntensity;
  final bool isInteracting;

  // Palette 3D de l'âne — tons plus chauds et réalistes
  static const _donkeyMain = Color(0xFF8B7D6B);
  static const _donkeyLight = Color(0xFFB0A090);
  static const _donkeyHighlight = Color(0xFFCDBFA8);
  static const _donkeyShadow = Color(0xFF5A4E40);
  static const _donkeyDark = Color(0xFF3A3028);
  static const _muzzleMain = Color(0xFFE0CEBD);
  static const _muzzleLight = Color(0xFFF0E4D8);
  static const _muzzleShadow = Color(0xFFBBA998);
  static const _earInner = Color(0xFFEBB5C8);
  static const _earInnerLight = Color(0xFFF8D8E6);
  static const _noseDark = Color(0xFF2D2520);
  static const _eyebrowColor = Color(0xFF4A3E30);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 20);
    // Tête plus allongée verticalement pour un vrai âne
    final headW = size.width * 0.28;
    final headH = size.width * 0.42;

    // ─── Glow derrière les oreilles actives ───
    if (glowIntensity > 0) {
      if (bass.abs() > 0.05) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx - headW * 0.85, center.dy - headH * 1.2),
            width: headW * 1.4,
            height: headH * 1.8 * leftEarStretch,
          ),
          Paint()
            ..color = AppColors.yellowGold.withValues(alpha: glowIntensity * 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35),
        );
      }
      if (treble.abs() > 0.05) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx + headW * 0.85, center.dy - headH * 1.2),
            width: headW * 1.4,
            height: headH * 1.8 * rightEarStretch,
          ),
          Paint()
            ..color = AppColors.yellowVivid.withValues(alpha: glowIntensity * 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35),
        );
      }
    }

    // ─── Oreille gauche (TRÈS GRANDE, avec gravité vers l'avant) ───
    _drawDonkeyEar3D(
      canvas,
      basePos: Offset(center.dx - headW * 0.65, center.dy - headH * 0.5),
      width: headW * 0.8,
      height: headH * 2.0 * leftEarStretch,
      gravityAngle: leftEarAngle * 0.4 - 0.15,
      isActive: bass.abs() > 0.05 && isInteracting,
      isLeft: true,
    );

    // ─── Oreille droite (TRÈS GRANDE, avec gravité vers l'avant) ───
    _drawDonkeyEar3D(
      canvas,
      basePos: Offset(center.dx + headW * 0.65, center.dy - headH * 0.5),
      width: headW * 0.8,
      height: headH * 2.0 * rightEarStretch,
      gravityAngle: rightEarAngle * 0.4 + 0.15,
      isActive: treble.abs() > 0.05 && isInteracting,
      isLeft: false,
    );

    // ─── Crinière (effet 3D avec ombres, plus épaisse) ───
    for (var i = 0; i < 11; i++) {
      final x = center.dx + (i - 5) * headW * 0.1;
      final baseY = center.dy - headH * 0.6;
      final heightVar = (5 - (i - 5).abs()) * 5.5;
      final tuftPath = Path()
        ..moveTo(x - 6, baseY + 10)
        ..quadraticBezierTo(x - 3, baseY - heightVar - 12, x, baseY - heightVar - 16)
        ..quadraticBezierTo(x + 3, baseY - heightVar - 12, x + 6, baseY + 10);
      // Ombre
      canvas.drawPath(
        tuftPath,
        Paint()
          ..color = _donkeyDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round,
      );
      // Mèche
      canvas.drawPath(
        tuftPath,
        Paint()
          ..color = _donkeyShadow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // ─── Tête (ovale allongé 3D avec gradient) ───
    final headRect = Rect.fromCenter(
      center: center,
      width: headW * 2.0,
      height: headH * 1.9,
    );
    // Ombre portée
    canvas.drawOval(
      headRect.shift(const Offset(3, 5)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    // Corps principal
    final headPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 1.2,
        colors: [_donkeyHighlight, _donkeyMain, _donkeyShadow],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(headRect);
    canvas.drawOval(headRect, headPaint);
    // Bordure subtile
    canvas.drawOval(
      headRect,
      Paint()
        ..color = _donkeyShadow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // ─── Touffes de poils aux bases des oreilles ───
    _drawFurTuft(canvas, Offset(center.dx - headW * 0.7, center.dy - headH * 0.4), isLeft: true);
    _drawFurTuft(canvas, Offset(center.dx + headW * 0.7, center.dy - headH * 0.4), isLeft: false);

    // ─── Zones claires autour des yeux (3D, plus grandes) ───
    final leftEyeZone = Rect.fromCenter(
      center: Offset(center.dx - headW * 0.38, center.dy - headH * 0.15),
      width: headW * 0.65,
      height: headH * 0.5,
    );
    canvas.drawOval(leftEyeZone, Paint()
      ..shader = RadialGradient(
        colors: [_donkeyHighlight, _donkeyLight],
      ).createShader(leftEyeZone));

    final rightEyeZone = Rect.fromCenter(
      center: Offset(center.dx + headW * 0.38, center.dy - headH * 0.15),
      width: headW * 0.65,
      height: headH * 0.5,
    );
    canvas.drawOval(rightEyeZone, Paint()
      ..shader = RadialGradient(
        colors: [_donkeyHighlight, _donkeyLight],
      ).createShader(rightEyeZone));

    // ─── Sourcils expressifs ───
    _drawEyebrow(canvas, Offset(center.dx - headW * 0.38, center.dy - headH * 0.32), isLeft: true);
    _drawEyebrow(canvas, Offset(center.dx + headW * 0.38, center.dy - headH * 0.32), isLeft: false);

    // ─── Museau 3D (plus grand et proéminent) ───
    final muzzleCenter = Offset(center.dx, center.dy + headH * 0.48);
    final muzzleRect = Rect.fromCenter(
      center: muzzleCenter,
      width: headW * 1.6,
      height: headH * 1.0,
    );
    // Ombre museau
    canvas.drawRRect(
      RRect.fromRectAndRadius(muzzleRect.shift(const Offset(2, 4)), Radius.circular(headW * 0.7)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    // Museau gradient
    final muzzleRRect = RRect.fromRectAndRadius(muzzleRect, Radius.circular(headW * 0.7));
    canvas.drawRRect(muzzleRRect, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.5),
        radius: 1.0,
        colors: [_muzzleLight, _muzzleMain, _muzzleShadow],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(muzzleRect));
    canvas.drawRRect(
      muzzleRRect,
      Paint()
        ..color = _muzzleShadow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ─── Ligne du menton ───
    final chinPath = Path()
      ..moveTo(center.dx - headW * 0.3, center.dy + headH * 0.85)
      ..quadraticBezierTo(
        center.dx,
        center.dy + headH * 0.92,
        center.dx + headW * 0.3,
        center.dy + headH * 0.85,
      );
    canvas.drawPath(
      chinPath,
      Paint()
        ..color = _muzzleShadow.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // ─── Narines 3D (plus grandes, plus écartées) ───
    _drawNostril(canvas, Offset(center.dx - headW * 0.32, center.dy + headH * 0.52), isLarge: true);
    _drawNostril(canvas, Offset(center.dx + headW * 0.32, center.dy + headH * 0.52), isLarge: true);

    // ─── Yeux 3D ───
    if (isInteracting) {
      _drawExcitedEye(canvas, Offset(center.dx - headW * 0.38, center.dy - headH * 0.15));
      _drawExcitedEye(canvas, Offset(center.dx + headW * 0.38, center.dy - headH * 0.15));
    } else {
      _drawEye(canvas, Offset(center.dx - headW * 0.38, center.dy - headH * 0.15));
      _drawEye(canvas, Offset(center.dx + headW * 0.38, center.dy - headH * 0.15));
    }

    // ─── Sourire ───
    final smilePath = Path()
      ..moveTo(center.dx - headW * 0.32, center.dy + headH * 0.33)
      ..quadraticBezierTo(
        center.dx,
        center.dy + headH * (isInteracting ? 0.52 : 0.44),
        center.dx + headW * 0.32,
        center.dy + headH * 0.33,
      );
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = _noseDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // ─── Petites rides de sourire ───
    if (isInteracting) {
      for (final side in [-1.0, 1.0]) {
        final dimplePath = Path()
          ..moveTo(center.dx + side * headW * 0.34, center.dy + headH * 0.31)
          ..quadraticBezierTo(
            center.dx + side * headW * 0.38,
            center.dy + headH * 0.34,
            center.dx + side * headW * 0.36,
            center.dy + headH * 0.37,
          );
        canvas.drawPath(
          dimplePath,
          Paint()
            ..color = _donkeyShadow.withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // ─── Labels d'interaction ───
    if (isInteracting) {
      _drawLabel(canvas, 'BASS', AppColors.yellowGold,
          Offset(center.dx - headW * 1.0, center.dy - headH * 1.6));
      _drawLabel(canvas, 'TREBLE', AppColors.yellowVivid,
          Offset(center.dx + headW * 1.0, center.dy - headH * 1.6));
    }
  }

  void _drawLabel(Canvas canvas, String text, Color color, Offset pos) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(pos.dx - painter.width / 2, pos.dy));
  }

  /// Touffe de poils à la base de l'oreille.
  void _drawFurTuft(Canvas canvas, Offset pos, {required bool isLeft}) {
    final dir = isLeft ? -1.0 : 1.0;
    for (var i = 0; i < 5; i++) {
      final angle = (i - 2) * 0.15 + dir * 0.2;
      final length = 8.0 + (2 - (i - 2).abs()) * 3.0;
      final endX = pos.dx + math.cos(angle - math.pi / 2) * length;
      final endY = pos.dy + math.sin(angle - math.pi / 2) * length;
      canvas.drawLine(
        pos,
        Offset(endX, endY),
        Paint()
          ..color = _donkeyShadow
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// Sourcil expressif au-dessus de l'œil.
  void _drawEyebrow(Canvas canvas, Offset pos, {required bool isLeft}) {
    final dir = isLeft ? -1.0 : 1.0;
    final browPath = Path()
      ..moveTo(pos.dx - dir * 12, pos.dy + 2)
      ..quadraticBezierTo(pos.dx, pos.dy - (isInteracting ? 5 : 3), pos.dx + dir * 12, pos.dy + 1);
    canvas.drawPath(
      browPath,
      Paint()
        ..color = _eyebrowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Grande oreille d'âne 3D avec effet de gravité vers l'avant.
  void _drawDonkeyEar3D(
    Canvas canvas, {
    required Offset basePos,
    required double width,
    required double height,
    required double gravityAngle,
    required bool isActive,
    required bool isLeft,
  }) {
    canvas.save();
    canvas.translate(basePos.dx, basePos.dy);
    canvas.rotate(gravityAngle);

    // Forme d'oreille en feuille allongée — typiquement âne
    final earPath = Path()
      ..moveTo(-width * 0.4, height * 0.05)
      ..cubicTo(-width * 0.55, -height * 0.15, -width * 0.45, -height * 0.4, -width * 0.2, -height * 0.5)
      ..cubicTo(-width * 0.05, -height * 0.55, width * 0.05, -height * 0.55, width * 0.2, -height * 0.5)
      ..cubicTo(width * 0.45, -height * 0.4, width * 0.55, -height * 0.15, width * 0.4, height * 0.05)
      ..cubicTo(width * 0.3, height * 0.18, 0, height * 0.24, 0, height * 0.24)
      ..cubicTo(0, height * 0.24, -width * 0.3, height * 0.18, -width * 0.4, height * 0.05)
      ..close();

    // Ombre portée de l'oreille (plus prononcée)
    canvas.drawPath(
      earPath.shift(const Offset(4, 5)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Gradient principal de l'oreille
    final earBounds = earPath.getBounds();
    canvas.drawPath(earPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_donkeyLight, _donkeyMain, _donkeyShadow],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(earBounds));

    // Bordure
    canvas.drawPath(
      earPath,
      Paint()
        ..color = isActive ? AppColors.yellowVivid : _donkeyShadow
        ..style = PaintingStyle.stroke
        ..strokeWidth = isActive ? 3.5 : 2.5,
    );

    // Intérieur rose 3D (plus grand, forme de feuille interne)
    final innerPath = Path()
      ..moveTo(-width * 0.2, height * 0.0)
      ..cubicTo(-width * 0.3, -height * 0.1, -width * 0.25, -height * 0.3, -width * 0.1, -height * 0.38)
      ..cubicTo(-width * 0.02, -height * 0.41, width * 0.02, -height * 0.41, width * 0.1, -height * 0.38)
      ..cubicTo(width * 0.25, -height * 0.3, width * 0.3, -height * 0.1, width * 0.2, height * 0.0)
      ..cubicTo(width * 0.13, height * 0.08, 0, height * 0.11, 0, height * 0.11)
      ..cubicTo(0, height * 0.11, -width * 0.13, height * 0.08, -width * 0.2, height * 0.0)
      ..close();

    final innerBounds = innerPath.getBounds();
    canvas.drawPath(innerPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_earInnerLight, _earInner],
      ).createShader(innerBounds));

    // Veines de l'oreille (détail réaliste)
    final veinPaint = Paint()
      ..color = _earInner.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    
    final vein1 = Path()
      ..moveTo(0, height * 0.05)
      ..quadraticBezierTo(-width * 0.05, -height * 0.15, 0, -height * 0.3);
    canvas.drawPath(vein1, veinPaint);

    final vein2 = Path()
      ..moveTo(0, height * 0.02)
      ..quadraticBezierTo(width * 0.08, -height * 0.12, width * 0.05, -height * 0.25);
    canvas.drawPath(vein2, veinPaint);

    final vein3 = Path()
      ..moveTo(0, height * 0.02)
      ..quadraticBezierTo(-width * 0.08, -height * 0.12, -width * 0.05, -height * 0.25);
    canvas.drawPath(vein3, veinPaint);

    // Highlight subtil le long du bord
    canvas.drawPath(
      innerPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    canvas.restore();
  }

  void _drawNostril(Canvas canvas, Offset center, {bool isLarge = false}) {
    final w = isLarge ? 16.0 : 13.0;
    final h = isLarge ? 20.0 : 17.0;
    // Ombre
    canvas.drawOval(
      Rect.fromCenter(center: center + const Offset(1, 1), width: w + 1, height: h + 1),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    // Narine
    canvas.drawOval(
      Rect.fromCenter(center: center, width: w, height: h),
      Paint()..color = _noseDark,
    );
    // Reflet
    canvas.drawOval(
      Rect.fromCenter(center: center + const Offset(-2, -3), width: 4, height: 5),
      Paint()..color = _donkeyShadow,
    );
  }

  void _drawEye(Canvas canvas, Offset center) {
    // Ombre de l'œil
    canvas.drawOval(
      Rect.fromCenter(center: center + const Offset(1, 2), width: 24, height: 22),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    // Blanc de l'œil avec gradient
    final eyeRect = Rect.fromCenter(center: center, width: 24, height: 22);
    canvas.drawOval(eyeRect, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [Colors.white, const Color(0xFFE8E8E8)],
      ).createShader(eyeRect));
    canvas.drawOval(
      eyeRect,
      Paint()
        ..color = _donkeyShadow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Iris marron chaud
    canvas.drawCircle(center + const Offset(1, 1), 8, Paint()..color = const Color(0xFF3A2810));
    // Pupille
    canvas.drawCircle(center + const Offset(1, 1), 5, Paint()..color = _noseDark);
    // Reflet
    canvas.drawCircle(center + const Offset(4, -3), 3, Paint()..color = Colors.white);
    canvas.drawCircle(center + const Offset(-2, 2), 1.5, Paint()..color = Colors.white.withValues(alpha: 0.6));
    // Cils en haut
    for (var i = 0; i < 3; i++) {
      final angle = -math.pi / 2 + (i - 1) * 0.3;
      final startX = center.dx + math.cos(angle) * 11;
      final startY = center.dy + math.sin(angle) * 10;
      final endX = center.dx + math.cos(angle) * 15;
      final endY = center.dy + math.sin(angle) * 14;
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        Paint()
          ..color = _donkeyDark
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawExcitedEye(Canvas canvas, Offset center) {
    // Ombre
    canvas.drawOval(
      Rect.fromCenter(center: center + const Offset(1, 2), width: 28, height: 26),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    // Blanc plus grand
    final eyeRect = Rect.fromCenter(center: center, width: 28, height: 26);
    canvas.drawOval(eyeRect, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [Colors.white, const Color(0xFFE8E8E8)],
      ).createShader(eyeRect));
    canvas.drawOval(
      eyeRect,
      Paint()
        ..color = _donkeyShadow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Iris doré
    canvas.drawCircle(center, 10, Paint()..color = const Color(0xFF3A2810));
    canvas.drawCircle(center, 7, Paint()
      ..shader = RadialGradient(
        colors: [AppColors.yellowVivid, AppColors.yellowGold],
      ).createShader(Rect.fromCircle(center: center, radius: 7)));
    // Pupille
    canvas.drawCircle(center, 4, Paint()..color = _noseDark);
    // Étoile reflet
    canvas.drawCircle(center + const Offset(4, -4), 3, Paint()..color = Colors.white);
    canvas.drawCircle(center + const Offset(-2, 3), 2, Paint()..color = Colors.white.withValues(alpha: 0.5));
    // Cils excités (plus longs)
    for (var i = 0; i < 4; i++) {
      final angle = -math.pi / 2 + (i - 1.5) * 0.25;
      final startX = center.dx + math.cos(angle) * 13;
      final startY = center.dy + math.sin(angle) * 12;
      final endX = center.dx + math.cos(angle) * 18;
      final endY = center.dy + math.sin(angle) * 17;
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        Paint()
          ..color = _donkeyDark
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiloEarsPainter oldDelegate) => true;
}