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
  double _baseScale = 1.0;
  bool _isInteracting = false;

  // Valeurs animées avec gravité
  double _leftEarAngle = 0.0;
  double _rightEarAngle = 0.0;
  double _leftEarVelocity = 0.0;
  double _rightEarVelocity = 0.0;

  late final AnimationController _glowController;
  late final AnimationController _gravityController;

  MiloAudioHandler get _handler => ref.read(audioHandlerProvider);

  @override
  void initState() {
    super.initState();
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
      // Gravité : retour vers 0 avec bounce
      const gravity = 0.008;
      const damping = 0.92;

      _leftEarVelocity += -_leftEarAngle * gravity;
      _leftEarVelocity *= damping;
      _leftEarAngle += _leftEarVelocity;

      _rightEarVelocity += -_rightEarAngle * gravity;
      _rightEarVelocity *= damping;
      _rightEarAngle += _rightEarVelocity;

      if (_leftEarAngle.abs() < 0.001 && _leftEarVelocity.abs() < 0.001) {
        _leftEarAngle = 0.0;
        _leftEarVelocity = 0.0;
      }
      if (_rightEarAngle.abs() < 0.001 && _rightEarVelocity.abs() < 0.001) {
        _rightEarAngle = 0.0;
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
            height: 300,
            width: double.infinity,
            child: GestureDetector(
              onVerticalDragStart: (_) =>
                  setState(() => _isInteracting = true),
              onVerticalDragUpdate: _onVerticalDrag,
              onVerticalDragEnd: (details) {
                // Donner une vélocité de "lâcher" aux oreilles
                final vel = details.velocity.pixelsPerSecond.dy / 2000;
                _leftEarVelocity = vel * 0.5;
                _rightEarVelocity = vel * 0.5;
                setState(() => _isInteracting = false);
              },
              onScaleStart: (details) {
                _baseScale = 1.0;
                setState(() => _isInteracting = true);
              },
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: (_) {
                setState(() => _isInteracting = false);
              },
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
                _leftEarAngle = 0;
                _rightEarAngle = 0;
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

  Future<void> _onVerticalDrag(DragUpdateDetails details) async {
    HapticFeedback.selectionClick();
    final delta = -details.delta.dy / 100;

    try {
      final current = ref.read(equalizerStateProvider);

      if (details.localPosition.dx < MediaQuery.of(context).size.width / 2 - 24) {
        // Oreille gauche → basses
        _leftEarAngle = (_leftEarAngle + details.delta.dy / 50).clamp(-1.0, 1.0);
        _leftEarVelocity = details.delta.dy / 200;
        final bass = (current.bass + delta).clamp(-1.0, 1.0);
        await _handler.equalizer.setBass(bass);
      } else {
        // Oreille droite → aigus
        _rightEarAngle = (_rightEarAngle + details.delta.dy / 50).clamp(-1.0, 1.0);
        _rightEarVelocity = details.delta.dy / 200;
        final treble = (current.treble + delta).clamp(-1.0, 1.0);
        await _handler.equalizer.setTreble(treble);
      }
      ref.read(equalizerStateProvider.notifier).state = _handler.equalizer.state;
    } catch (_) {
      // Silently handle if audio handler isn't ready
    }
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    if (details.scale != 1.0) {
      HapticFeedback.lightImpact();
      try {
        final panDelta = (details.scale - _baseScale) * 2;
        _baseScale = details.scale;
        final pan = (ref.read(equalizerStateProvider).pan + panDelta)
            .clamp(-1.0, 1.0);
        await _handler.equalizer.setPan(pan);
        ref.read(equalizerStateProvider.notifier).state =
            _handler.equalizer.state;
      } catch (_) {
        // Silently handle
      }
    }
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

  // Palette 3D de l'âne
  static const _donkeyMain = Color(0xFF7A7A7A);
  static const _donkeyLight = Color(0xFFA8A8A8);
  static const _donkeyHighlight = Color(0xFFC4C4C4);
  static const _donkeyShadow = Color(0xFF4A4A4A);
  static const _donkeyDark = Color(0xFF3A3A3A);
  static const _muzzleMain = Color(0xFFD9C9B5);
  static const _muzzleLight = Color(0xFFEDE0D0);
  static const _muzzleShadow = Color(0xFFB5A590);
  static const _earInner = Color(0xFFE8B5C8);
  static const _earInnerLight = Color(0xFFF5D4E2);
  static const _noseDark = Color(0xFF2D2D2D);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 15);
    final headW = size.width * 0.30;
    final headH = size.width * 0.36;

    // ─── Glow derrière les oreilles actives ───
    if (glowIntensity > 0) {
      if (bass.abs() > 0.05) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx - headW * 0.8, center.dy - headH * 1.3),
            width: headW * 1.0,
            height: headH * 1.4 * leftEarStretch,
          ),
          Paint()
            ..color = AppColors.yellowGold.withValues(alpha: glowIntensity * 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
        );
      }
      if (treble.abs() > 0.05) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx + headW * 0.8, center.dy - headH * 1.3),
            width: headW * 1.0,
            height: headH * 1.4 * rightEarStretch,
          ),
          Paint()
            ..color = AppColors.yellowVivid.withValues(alpha: glowIntensity * 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
        );
      }
    }

    // ─── Oreille gauche (GRANDE, avec gravité) ───
    _drawDonkeyEar3D(
      canvas,
      basePos: Offset(center.dx - headW * 0.6, center.dy - headH * 0.55),
      width: headW * 0.5,
      height: headH * 1.4 * leftEarStretch,
      gravityAngle: leftEarAngle * 0.4 - 0.15,
      isActive: bass.abs() > 0.05 && isInteracting,
    );

    // ─── Oreille droite (GRANDE, avec gravité) ───
    _drawDonkeyEar3D(
      canvas,
      basePos: Offset(center.dx + headW * 0.6, center.dy - headH * 0.55),
      width: headW * 0.5,
      height: headH * 1.4 * rightEarStretch,
      gravityAngle: rightEarAngle * 0.4 + 0.15,
      isActive: treble.abs() > 0.05 && isInteracting,
    );

    // ─── Crinière (effet 3D avec ombres) ───
    for (var i = 0; i < 9; i++) {
      final x = center.dx + (i - 4) * headW * 0.1;
      final baseY = center.dy - headH * 0.6;
      final heightVar = (4 - (i - 4).abs()) * 5.0;
      final tuftPath = Path()
        ..moveTo(x - 5, baseY + 10)
        ..quadraticBezierTo(x - 2, baseY - heightVar - 10, x, baseY - heightVar - 14)
        ..quadraticBezierTo(x + 2, baseY - heightVar - 10, x + 5, baseY + 10);
      // Ombre
      canvas.drawPath(
        tuftPath,
        Paint()
          ..color = _donkeyDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
      // Mèche
      canvas.drawPath(
        tuftPath,
        Paint()
          ..color = _donkeyShadow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }

    // ─── Tête (ovale 3D avec gradient) ───
    final headRect = Rect.fromCenter(
      center: center,
      width: headW * 2.0,
      height: headH * 1.8,
    );
    // Ombre portée
    canvas.drawOval(
      headRect.shift(const Offset(3, 4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
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

    // ─── Zones claires autour des yeux (3D) ───
    final leftEyeZone = Rect.fromCenter(
      center: Offset(center.dx - headW * 0.38, center.dy - headH * 0.12),
      width: headW * 0.6,
      height: headH * 0.5,
    );
    canvas.drawOval(leftEyeZone, Paint()
      ..shader = RadialGradient(
        colors: [_donkeyHighlight, _donkeyLight],
      ).createShader(leftEyeZone));
    
    final rightEyeZone = Rect.fromCenter(
      center: Offset(center.dx + headW * 0.38, center.dy - headH * 0.12),
      width: headW * 0.6,
      height: headH * 0.5,
    );
    canvas.drawOval(rightEyeZone, Paint()
      ..shader = RadialGradient(
        colors: [_donkeyHighlight, _donkeyLight],
      ).createShader(rightEyeZone));

    // ─── Museau 3D ───
    final muzzleCenter = Offset(center.dx, center.dy + headH * 0.52);
    final muzzleRect = Rect.fromCenter(
      center: muzzleCenter,
      width: headW * 1.5,
      height: headH * 0.9,
    );
    // Ombre museau
    canvas.drawRRect(
      RRect.fromRectAndRadius(muzzleRect.shift(const Offset(2, 3)), Radius.circular(headW * 0.65)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Museau gradient
    final muzzleRRect = RRect.fromRectAndRadius(muzzleRect, Radius.circular(headW * 0.65));
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

    // ─── Narines 3D ───
    _drawNostril(canvas, Offset(center.dx - headW * 0.28, center.dy + headH * 0.55));
    _drawNostril(canvas, Offset(center.dx + headW * 0.28, center.dy + headH * 0.55));

    // ─── Yeux 3D ───
    if (isInteracting) {
      _drawExcitedEye(canvas, Offset(center.dx - headW * 0.38, center.dy - headH * 0.12));
      _drawExcitedEye(canvas, Offset(center.dx + headW * 0.38, center.dy - headH * 0.12));
    } else {
      _drawEye(canvas, Offset(center.dx - headW * 0.38, center.dy - headH * 0.12));
      _drawEye(canvas, Offset(center.dx + headW * 0.38, center.dy - headH * 0.12));
    }

    // ─── Sourire ───
    final smilePath = Path()
      ..moveTo(center.dx - headW * 0.3, center.dy + headH * 0.35)
      ..quadraticBezierTo(
        center.dx,
        center.dy + headH * (isInteracting ? 0.58 : 0.48),
        center.dx + headW * 0.3,
        center.dy + headH * 0.35,
      );
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = _noseDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // ─── Labels d'interaction ───
    if (isInteracting) {
      _drawLabel(canvas, 'BASS', AppColors.yellowGold,
          Offset(center.dx - headW * 0.8, center.dy - headH * 1.9));
      _drawLabel(canvas, 'TREBLE', AppColors.yellowVivid,
          Offset(center.dx + headW * 0.8, center.dy - headH * 1.9));
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

  /// Grande oreille d'âne 3D avec effet de gravité.
  void _drawDonkeyEar3D(
    Canvas canvas, {
    required Offset basePos,
    required double width,
    required double height,
    required double gravityAngle,
    required bool isActive,
  }) {
    canvas.save();
    canvas.translate(basePos.dx, basePos.dy);
    canvas.rotate(gravityAngle);

    // Oreille extérieure avec gradient 3D
    final earPath = Path()
      ..moveTo(-width * 0.45, height * 0.05)
      ..cubicTo(-width * 0.5, -height * 0.3, -width * 0.15, -height * 0.5, 0, -height * 0.52)
      ..cubicTo(width * 0.15, -height * 0.5, width * 0.5, -height * 0.3, width * 0.45, height * 0.05)
      ..cubicTo(width * 0.35, height * 0.2, 0, height * 0.28, 0, height * 0.28)
      ..cubicTo(0, height * 0.28, -width * 0.35, height * 0.2, -width * 0.45, height * 0.05)
      ..close();

    // Ombre portée de l'oreille
    canvas.drawPath(
      earPath.shift(const Offset(3, 4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
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

    // Intérieur rose 3D
    final innerPath = Path()
      ..moveTo(-width * 0.22, height * 0.0)
      ..cubicTo(-width * 0.25, -height * 0.2, -width * 0.08, -height * 0.35, 0, -height * 0.37)
      ..cubicTo(width * 0.08, -height * 0.35, width * 0.25, -height * 0.2, width * 0.22, height * 0.0)
      ..cubicTo(width * 0.15, height * 0.1, 0, height * 0.14, 0, height * 0.14)
      ..cubicTo(0, height * 0.14, -width * 0.15, height * 0.1, -width * 0.22, height * 0.0)
      ..close();

    final innerBounds = innerPath.getBounds();
    canvas.drawPath(innerPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_earInnerLight, _earInner],
      ).createShader(innerBounds));

    // Highlight subtil
    canvas.drawPath(
      innerPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    canvas.restore();
  }

  void _drawNostril(Canvas canvas, Offset center) {
    // Ombre
    canvas.drawOval(
      Rect.fromCenter(center: center + const Offset(1, 1), width: 14, height: 18),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    // Narine
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 13, height: 17),
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
    // Iris
    canvas.drawCircle(center + const Offset(1, 1), 8, Paint()..color = const Color(0xFF2A1F0A));
    // Pupille
    canvas.drawCircle(center + const Offset(1, 1), 5, Paint()..color = _noseDark);
    // Reflet
    canvas.drawCircle(center + const Offset(4, -3), 3, Paint()..color = Colors.white);
    canvas.drawCircle(center + const Offset(-2, 2), 1.5, Paint()..color = Colors.white.withValues(alpha: 0.6));
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
    canvas.drawCircle(center, 10, Paint()..color = const Color(0xFF2A1F0A));
    canvas.drawCircle(center, 7, Paint()
      ..shader = RadialGradient(
        colors: [AppColors.yellowVivid, AppColors.yellowGold],
      ).createShader(Rect.fromCircle(center: center, radius: 7)));
    // Pupille
    canvas.drawCircle(center, 4, Paint()..color = _noseDark);
    // Étoile reflet
    canvas.drawCircle(center + const Offset(4, -4), 3, Paint()..color = Colors.white);
    canvas.drawCircle(center + const Offset(-2, 3), 2, Paint()..color = Colors.white.withValues(alpha: 0.5));
  }

  @override
  bool shouldRepaint(covariant _MiloEarsPainter oldDelegate) => true;
}