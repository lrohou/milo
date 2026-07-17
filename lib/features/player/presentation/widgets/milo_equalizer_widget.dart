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
    with SingleTickerProviderStateMixin {
  double _baseScale = 1.0;
  bool _isInteracting = false;

  // Valeurs animées cibles
  double _targetLeftStretch = 1.0;
  double _targetRightStretch = 1.0;

  late final AnimationController _glowController;

  MiloAudioHandler get _handler => ref.read(audioHandlerProvider);

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eqState = ref.watch(equalizerStateProvider);

    // Mise à jour des targets d'animation
    _targetLeftStretch = eqState.leftEarStretch;
    _targetRightStretch = eqState.rightEarStretch;

    return Column(
      children: [
        GlassCard(
          padding: const EdgeInsets.all(32),
          child: SizedBox(
            height: 280,
            width: double.infinity,
            child: GestureDetector(
              onVerticalDragStart: (_) =>
                  setState(() => _isInteracting = true),
              onVerticalDragUpdate: _onVerticalDrag,
              onVerticalDragEnd: (_) {
                _resetEarVisuals();
                setState(() => _isInteracting = false);
              },
              onScaleStart: (details) {
                _baseScale = 1.0;
                setState(() => _isInteracting = true);
              },
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: (_) {
                _resetEarVisuals();
                setState(() => _isInteracting = false);
              },
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.0, end: _targetLeftStretch),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    builder: (context, leftStretch, _) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.0, end: _targetRightStretch),
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        builder: (context, rightStretch, _) {
                          return CustomPaint(
                            painter: _MiloEarsPainter(
                              bass: eqState.bass,
                              treble: eqState.treble,
                              pan: eqState.pan,
                              leftEarStretch: leftStretch,
                              rightEarStretch: rightStretch,
                              glowIntensity: _isInteracting
                                  ? 0.6 + _glowController.value * 0.4
                                  : 0.0,
                              isInteracting: _isInteracting,
                            ),
                            size: Size.infinite,
                          );
                        },
                      );
                    },
                  );
                },
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
                ref.read(equalizerStateProvider.notifier).state = _handler.equalizer.state;
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '↑ Aigus  ·  ↓ Basses  ·  Pincer = Pan',
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
    final delta = -details.delta.dy / 120;
    final current = ref.read(equalizerStateProvider);

    if (details.localPosition.dx < 160) {
      // Oreille gauche → basses
      final bass = (current.bass + delta).clamp(-1.0, 1.0);
      await _handler.equalizer.setBass(bass);
      ref.read(equalizerStateProvider.notifier).state =
          _handler.equalizer.state;
    } else {
      // Oreille droite → aigus
      final treble = (current.treble + delta).clamp(-1.0, 1.0);
      await _handler.equalizer.setTreble(treble);
      ref.read(equalizerStateProvider.notifier).state =
          _handler.equalizer.state;
    }
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    if (details.scale != 1.0) {
      HapticFeedback.lightImpact();
      final panDelta = (details.scale - _baseScale) * 2;
      _baseScale = details.scale;
      final pan = (ref.read(equalizerStateProvider).pan + panDelta)
          .clamp(-1.0, 1.0);
      await _handler.equalizer.setPan(pan);
      ref.read(equalizerStateProvider.notifier).state =
          _handler.equalizer.state;
    }
  }

  void _resetEarVisuals() {
    _handler.equalizer.resetVisualDeformation();
    ref.read(equalizerStateProvider.notifier).state =
        _handler.equalizer.state;
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

/// Peint la tête de Milo (âne) avec oreilles déformables + effets de glow.
class _MiloEarsPainter extends CustomPainter {
  _MiloEarsPainter({
    required this.bass,
    required this.treble,
    required this.pan,
    required this.leftEarStretch,
    required this.rightEarStretch,
    required this.glowIntensity,
    required this.isInteracting,
  });

  final double bass;
  final double treble;
  final double pan;
  final double leftEarStretch;
  final double rightEarStretch;
  final double glowIntensity;
  final bool isInteracting;

  // Couleurs de l'âne
  static const _donkeyGrey = Color(0xFF8E8E8E);
  static const _donkeyDarkGrey = Color(0xFF5A5A5A);
  static const _donkeyLightGrey = Color(0xFFB5B5B5);
  static const _donkeyMuzzle = Color(0xFFD4C5B0);
  static const _donkeyInnerEar = Color(0xFFE8C9D4);
  static const _donkeyNose = Color(0xFF3D3D3D);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 25);
    final headW = size.width * 0.28;
    final headH = size.width * 0.34;

    final borderPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    // ─── Glow derrière les oreilles actives ───
    if (glowIntensity > 0) {
      if (bass.abs() > 0.05) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx - headW * 0.7, center.dy - headH * 1.2),
            width: headW * 0.7,
            height: headH * 0.9 * leftEarStretch,
          ),
          Paint()
            ..color = AppColors.yellowGold.withValues(alpha: glowIntensity * 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
        );
      }
      if (treble.abs() > 0.05) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx + headW * 0.7, center.dy - headH * 1.2),
            width: headW * 0.7,
            height: headH * 0.9 * rightEarStretch,
          ),
          Paint()
            ..color = AppColors.yellowVivid.withValues(alpha: glowIntensity * 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
        );
      }
    }

    // ─── Oreille gauche (longue, pointue, d'âne) ───
    _drawDonkeyEar(
      canvas,
      center: Offset(center.dx - headW * 0.55, center.dy - headH * 0.75),
      width: headW * 0.35,
      height: headH * 1.0 * leftEarStretch,
      tiltAngle: -0.2,
      isActive: bass.abs() > 0.05 && isInteracting,
      isLeft: true,
    );

    // ─── Oreille droite ───
    _drawDonkeyEar(
      canvas,
      center: Offset(center.dx + headW * 0.55, center.dy - headH * 0.75),
      width: headW * 0.35,
      height: headH * 1.0 * rightEarStretch,
      tiltAngle: 0.2,
      isActive: treble.abs() > 0.05 && isInteracting,
      isLeft: false,
    );

    // ─── Crinière (entre les oreilles) ───
    final manePaint = Paint()
      ..color = _donkeyDarkGrey
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 7; i++) {
      final x = center.dx + (i - 3) * headW * 0.12;
      final y = center.dy - headH * 0.65 - (3 - (i - 3).abs()) * 6;
      final tuftPath = Path()
        ..moveTo(x - 4, y + 12)
        ..quadraticBezierTo(x, y - 8, x + 4, y + 12);
      canvas.drawPath(tuftPath, manePaint..strokeWidth = 5);
      canvas.drawPath(
        tuftPath,
        Paint()
          ..color = _donkeyDarkGrey
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }

    // ─── Tête (ovale allongée verticalement) ───
    final headRect = Rect.fromCenter(
      center: center,
      width: headW * 1.8,
      height: headH * 1.7,
    );
    final headRRect = RRect.fromRectAndRadius(headRect, Radius.circular(headW * 0.8));
    canvas.drawRRect(headRRect, Paint()..color = _donkeyGrey);
    canvas.drawRRect(headRRect, borderPaint);

    // ─── Zones claires autour des yeux ───
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - headW * 0.35, center.dy - headH * 0.15),
        width: headW * 0.55,
        height: headH * 0.45,
      ),
      Paint()..color = _donkeyLightGrey,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + headW * 0.35, center.dy - headH * 0.15),
        width: headW * 0.55,
        height: headH * 0.45,
      ),
      Paint()..color = _donkeyLightGrey,
    );

    // ─── Museau (plus grand, allongé, couleur claire) ───
    final muzzleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + headH * 0.55),
        width: headW * 1.4,
        height: headH * 0.85,
      ),
      Radius.circular(headW * 0.6),
    );
    canvas.drawRRect(muzzleRect, Paint()..color = _donkeyMuzzle);
    canvas.drawRRect(muzzleRect, borderPaint);

    // ─── Narines (ovales, plus réalistes) ───
    final nostrilPaint = Paint()..color = _donkeyNose;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - headW * 0.25, center.dy + headH * 0.58),
        width: 12,
        height: 16,
      ),
      nostrilPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + headW * 0.25, center.dy + headH * 0.58),
        width: 12,
        height: 16,
      ),
      nostrilPaint,
    );

    // ─── Yeux ───
    if (isInteracting) {
      _drawExcitedEye(canvas, Offset(center.dx - headW * 0.35, center.dy - headH * 0.15));
      _drawExcitedEye(canvas, Offset(center.dx + headW * 0.35, center.dy - headH * 0.15));
    } else {
      _drawEye(canvas, Offset(center.dx - headW * 0.35, center.dy - headH * 0.15));
      _drawEye(canvas, Offset(center.dx + headW * 0.35, center.dy - headH * 0.15));
    }

    // ─── Sourire ───
    final smilePath = Path()
      ..moveTo(center.dx - headW * 0.35, center.dy + headH * 0.38)
      ..quadraticBezierTo(
        center.dx,
        center.dy + headH * (isInteracting ? 0.62 : 0.52),
        center.dx + headW * 0.35,
        center.dy + headH * 0.38,
      );
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = _donkeyNose
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // ─── Labels d'interaction ───
    if (isInteracting) {
      final leftLabel = TextPainter(
        text: const TextSpan(
          text: 'BASS',
          style: TextStyle(
            color: AppColors.yellowGold,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      leftLabel.paint(
        canvas,
        Offset(center.dx - headW * 0.7 - leftLabel.width / 2,
            center.dy - headH * 1.7),
      );

      final rightLabel = TextPainter(
        text: const TextSpan(
          text: 'TREBLE',
          style: TextStyle(
            color: AppColors.yellowVivid,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      rightLabel.paint(
        canvas,
        Offset(center.dx + headW * 0.7 - rightLabel.width / 2,
            center.dy - headH * 1.7),
      );
    }
  }

  /// Dessine une oreille d'âne : longue, pointue, avec intérieur rose.
  void _drawDonkeyEar(
    Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
    required double tiltAngle,
    required bool isActive,
    required bool isLeft,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tiltAngle);

    // Forme d'oreille pointue (path)
    final earPath = Path()
      ..moveTo(-width / 2, height * 0.1)
      ..quadraticBezierTo(-width * 0.4, -height * 0.35, 0, -height / 2)
      ..quadraticBezierTo(width * 0.4, -height * 0.35, width / 2, height * 0.1)
      ..quadraticBezierTo(width * 0.3, height * 0.25, 0, height * 0.3)
      ..quadraticBezierTo(-width * 0.3, height * 0.25, -width / 2, height * 0.1)
      ..close();

    // Oreille extérieure
    canvas.drawPath(earPath, Paint()..color = _donkeyGrey);
    canvas.drawPath(
      earPath,
      Paint()
        ..color = isActive ? AppColors.yellowVivid : AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = isActive ? 4 : 3,
    );

    // Intérieur rose de l'oreille
    final innerPath = Path()
      ..moveTo(-width * 0.25, height * 0.0)
      ..quadraticBezierTo(-width * 0.2, -height * 0.22, 0, -height * 0.32)
      ..quadraticBezierTo(width * 0.2, -height * 0.22, width * 0.25, height * 0.0)
      ..quadraticBezierTo(width * 0.15, height * 0.12, 0, height * 0.15)
      ..quadraticBezierTo(-width * 0.15, height * 0.12, -width * 0.25, height * 0.0)
      ..close();

    canvas.drawPath(innerPath, Paint()..color = _donkeyInnerEar);

    canvas.restore();
  }

  void _drawEye(Canvas canvas, Offset center) {
    // Blanc de l'œil
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 20, height: 18),
      Paint()..color = Colors.white,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 20, height: 18),
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Pupille
    canvas.drawCircle(center + const Offset(1, 1), 7, Paint()..color = _donkeyNose);
    // Reflet
    canvas.drawCircle(
      center + const Offset(3, -2),
      3,
      Paint()..color = Colors.white,
    );
  }

  void _drawExcitedEye(Canvas canvas, Offset center) {
    // Blanc de l'œil (plus grand)
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 24, height: 22),
      Paint()..color = Colors.white,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 24, height: 22),
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Pupille étoile (dorée)
    canvas.drawCircle(center, 9, Paint()..color = _donkeyNose);
    canvas.drawCircle(center, 6, Paint()..color = AppColors.yellowVivid);
    // Reflet
    canvas.drawCircle(
      center + const Offset(3, -3),
      3,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _MiloEarsPainter oldDelegate) =>
      bass != oldDelegate.bass ||
      treble != oldDelegate.treble ||
      pan != oldDelegate.pan ||
      leftEarStretch != oldDelegate.leftEarStretch ||
      rightEarStretch != oldDelegate.rightEarStretch ||
      glowIntensity != oldDelegate.glowIntensity ||
      isInteracting != oldDelegate.isInteracting;
}