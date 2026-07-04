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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(width: 8),
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
            const SizedBox(width: 8),
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

/// Peint la tête de Milo avec oreilles déformables + effets de glow.
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

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 20);
    final headRadius = size.width * 0.22;

    // Glow derrière les oreilles actives
    if (glowIntensity > 0) {
      // Glow oreille gauche (basses)
      if (bass.abs() > 0.05) {
        canvas.drawCircle(
          Offset(center.dx - headRadius * 1.1, center.dy - headRadius * 0.9),
          headRadius * 0.7 * leftEarStretch,
          Paint()
            ..color = AppColors.yellowGold.withValues(alpha: glowIntensity * 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
        );
      }
      // Glow oreille droite (aigus)
      if (treble.abs() > 0.05) {
        canvas.drawCircle(
          Offset(center.dx + headRadius * 1.1, center.dy - headRadius * 0.9),
          headRadius * 0.7 * rightEarStretch,
          Paint()
            ..color = AppColors.yellowVivid.withValues(alpha: glowIntensity * 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
        );
      }
    }

    // Oreille gauche (basses)
    _drawEar(
      canvas,
      Offset(center.dx - headRadius * 1.1, center.dy - headRadius * 0.9),
      headRadius * 0.55,
      headRadius * 0.9 * leftEarStretch,
      AppColors.yellowGold,
      bass.abs() > 0.05 && isInteracting,
    );

    // Oreille droite (aigus)
    _drawEar(
      canvas,
      Offset(center.dx + headRadius * 1.1, center.dy - headRadius * 0.9),
      headRadius * 0.55,
      headRadius * 0.9 * rightEarStretch,
      AppColors.yellowVivid,
      treble.abs() > 0.05 && isInteracting,
    );

    // Tête
    final headPaint = Paint()
      ..color = AppColors.cream
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, headRadius, headPaint);
    canvas.drawCircle(center, headRadius, borderPaint);

    // Museau
    final snoutRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + headRadius * 0.35),
        width: headRadius * 1.1,
        height: headRadius * 0.65,
      ),
      const Radius.circular(16),
    );
    canvas.drawRRect(snoutRect, headPaint);
    canvas.drawRRect(snoutRect, borderPaint);

    // Narines
    final nostrilPaint = Paint()..color = AppColors.backgroundSurface;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - headRadius * 0.15, center.dy + headRadius * 0.38),
        width: 8,
        height: 6,
      ),
      nostrilPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + headRadius * 0.15, center.dy + headRadius * 0.38),
        width: 8,
        height: 6,
      ),
      nostrilPaint,
    );

    // Yeux joyeux (expressifs selon l'interaction)
    if (isInteracting) {
      _drawExcitedEye(canvas, Offset(center.dx - headRadius * 0.35, center.dy - 10));
      _drawExcitedEye(canvas, Offset(center.dx + headRadius * 0.35, center.dy - 10));
    } else {
      _drawEye(canvas, Offset(center.dx - headRadius * 0.35, center.dy - 10));
      _drawEye(canvas, Offset(center.dx + headRadius * 0.35, center.dy - 10));
    }

    // Sourire
    final smilePath = Path()
      ..moveTo(center.dx - headRadius * 0.3, center.dy + headRadius * 0.15)
      ..quadraticBezierTo(
        center.dx,
        center.dy + headRadius * (isInteracting ? 0.55 : 0.45),
        center.dx + headRadius * 0.3,
        center.dy + headRadius * 0.15,
      );
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Crinière
    for (var i = 0; i < 5; i++) {
      final angle = math.pi + (i - 2) * 0.35;
      final start = Offset(
        center.dx + math.cos(angle) * headRadius * 0.8,
        center.dy + math.sin(angle) * headRadius * 0.5 - headRadius * 0.5,
      );
      canvas.drawLine(
        start,
        start + Offset(math.cos(angle) * 18, math.sin(angle) * 18 - 8),
        Paint()
          ..color = AppColors.yellowVivid
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }

    // Indication de zone d'interaction
    if (isInteracting) {
      // Indicateur gauche (BASS)
      final leftLabel = TextPainter(
        text: const TextSpan(
          text: 'BASS',
          style: TextStyle(
            color: AppColors.yellowGold,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      leftLabel.paint(
        canvas,
        Offset(center.dx - headRadius * 1.1 - leftLabel.width / 2,
            center.dy - headRadius * 1.8),
      );

      // Indicateur droite (TREBLE)
      final rightLabel = TextPainter(
        text: const TextSpan(
          text: 'TREBLE',
          style: TextStyle(
            color: AppColors.yellowVivid,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      rightLabel.paint(
        canvas,
        Offset(center.dx + headRadius * 1.1 - rightLabel.width / 2,
            center.dy - headRadius * 1.8),
      );
    }
  }

  void _drawEar(Canvas canvas, Offset center, double width, double height,
      Color fill, bool active) {
    final earRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: width, height: height),
      Radius.circular(width / 2),
    );
    canvas.drawRRect(
      earRect,
      Paint()..color = fill,
    );
    canvas.drawRRect(
      earRect,
      Paint()
        ..color = active ? AppColors.yellowVivid : AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 4 : 3,
    );

    // Intérieur de l'oreille
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 2),
        width: width * 0.5,
        height: height * 0.6,
      ),
      Radius.circular(width / 3),
    );
    canvas.drawRRect(
      innerRect,
      Paint()..color = fill.withValues(alpha: 0.6),
    );
  }

  void _drawEye(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 8, Paint()..color = AppColors.border);
    canvas.drawCircle(
      center + const Offset(2, -2),
      3,
      Paint()..color = AppColors.cream,
    );
  }

  void _drawExcitedEye(Canvas canvas, Offset center) {
    // Étoiles dans les yeux quand on interagit
    canvas.drawCircle(center, 10, Paint()..color = AppColors.border);
    canvas.drawCircle(center, 7, Paint()..color = AppColors.yellowVivid);
    canvas.drawCircle(
      center + const Offset(2, -2),
      3,
      Paint()..color = AppColors.cream,
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