import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/core/providers/audio_providers.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/features/mood_avatars/services/mood_avatar_service.dart';
import 'package:milo/features/rhythm_terrain/providers/rhythm_terrain_provider.dart';
import 'package:milo/shared/models/milo_mood.dart';

/// Avatar dynamique de Milo — dessin vectoriel CustomPaint par humeur.
class DynamicMiloAvatar extends ConsumerWidget {
  const DynamicMiloAvatar({super.key, this.size = 80});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);
    final track = handler.currentTrack;
    final isSprint = ref.watch(rhythmTerrainActiveProvider);
    final mood = MoodAvatarService.resolve(
      track: track,
      isSprintMode: isSprint,
    );

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _moodBgColor(mood),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 3),
        boxShadow: [
          BoxShadow(
            color: _moodAccentColor(mood).withValues(alpha: 0.3),
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: ClipOval(
        child: CustomPaint(
          painter: _MiloMoodPainter(mood: mood, size: size),
          size: Size(size, size),
        ),
      ),
    );

    // Animations spécifiques par mood
    avatar = switch (mood) {
      MiloMood.chill => avatar
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(
              begin: -4,
              end: 4,
              duration: 2.seconds,
              curve: Curves.easeInOut),
      MiloMood.rock => avatar
          .animate(onPlay: (c) => c.repeat())
          .shake(hz: 4, rotation: 0.08, duration: 600.ms),
      MiloMood.sprint => avatar
          .animate(onPlay: (c) => c.repeat())
          .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              duration: 400.ms),
      MiloMood.kick => avatar
          .animate(onPlay: (c) => c.repeat())
          .shake(hz: 8, rotation: 0.15),
      MiloMood.jazz => avatar
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .rotate(begin: -0.02, end: 0.02, duration: 1500.ms),
      _ => avatar,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatar,
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _moodAccentColor(mood).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _moodAccentColor(mood).withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Text(
            mood.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _moodAccentColor(mood),
                  fontSize: 11,
                ),
          ),
        ),
      ],
    );
  }

  Color _moodBgColor(MiloMood mood) => switch (mood) {
        MiloMood.rock => AppColors.backgroundSurface,
        MiloMood.jazz => const Color(0xFF4A3728),
        MiloMood.chill => const Color(0xFF2A3A2A),
        MiloMood.kick => AppColors.error.withValues(alpha: 0.3),
        MiloMood.sprint => AppColors.yellowGold,
        MiloMood.happy => AppColors.cream,
      };

  Color _moodAccentColor(MiloMood mood) => switch (mood) {
        MiloMood.rock => AppColors.error,
        MiloMood.jazz => const Color(0xFFD4A574),
        MiloMood.chill => AppColors.success,
        MiloMood.kick => AppColors.error,
        MiloMood.sprint => AppColors.yellowVivid,
        MiloMood.happy => AppColors.yellowVivid,
      };
}

/// Peint la mascotte Milo adaptée à chaque humeur.
class _MiloMoodPainter extends CustomPainter {
  _MiloMoodPainter({required this.mood, required this.size});

  final MiloMood mood;
  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final r = canvasSize.width * 0.35;

    switch (mood) {
      case MiloMood.happy:
        _drawHappyMilo(canvas, center, r);
      case MiloMood.rock:
        _drawRockMilo(canvas, center, r);
      case MiloMood.jazz:
        _drawJazzMilo(canvas, center, r);
      case MiloMood.chill:
        _drawChillMilo(canvas, center, r);
      case MiloMood.kick:
        _drawKickMilo(canvas, center, r);
      case MiloMood.sprint:
        _drawSprintMilo(canvas, center, r);
    }
  }

  // — Milo Joyeux (défaut)
  void _drawHappyMilo(Canvas canvas, Offset center, double r) {
    // Mini oreilles
    _drawMiniEar(canvas, Offset(center.dx - r * 0.7, center.dy - r * 0.6), r * 0.25, AppColors.yellowGold);
    _drawMiniEar(canvas, Offset(center.dx + r * 0.7, center.dy - r * 0.6), r * 0.25, AppColors.yellowVivid);

    // Yeux joyeux (arcs)
    final eyePaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx - r * 0.25, center.dy - r * 0.1), width: r * 0.3, height: r * 0.2),
      math.pi, math.pi, false, eyePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx + r * 0.25, center.dy - r * 0.1), width: r * 0.3, height: r * 0.2),
      math.pi, math.pi, false, eyePaint,
    );

    // Grand sourire
    _drawSmile(canvas, center, r, wide: true);
  }

  // — Milo Rock (lunettes noires + cornes)
  void _drawRockMilo(Canvas canvas, Offset center, double r) {
    // Cornes (au lieu d'oreilles)
    final hornPaint = Paint()
      ..color = AppColors.error
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - r * 0.5, center.dy - r * 0.3),
      Offset(center.dx - r * 0.8, center.dy - r * 0.9),
      hornPaint,
    );
    canvas.drawLine(
      Offset(center.dx + r * 0.5, center.dy - r * 0.3),
      Offset(center.dx + r * 0.8, center.dy - r * 0.9),
      hornPaint,
    );

    // Lunettes noires
    final glassesPaint = Paint()..color = AppColors.border;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx - r * 0.25, center.dy - r * 0.05), width: r * 0.45, height: r * 0.3),
        const Radius.circular(4),
      ),
      glassesPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx + r * 0.25, center.dy - r * 0.05), width: r * 0.45, height: r * 0.3),
        const Radius.circular(4),
      ),
      glassesPaint,
    );
    // Pont
    canvas.drawLine(
      Offset(center.dx - r * 0.03, center.dy - r * 0.05),
      Offset(center.dx + r * 0.03, center.dy - r * 0.05),
      Paint()..color = AppColors.border..strokeWidth = 2.5,
    );

    // Grimace rock
    canvas.drawLine(
      Offset(center.dx - r * 0.2, center.dy + r * 0.25),
      Offset(center.dx + r * 0.2, center.dy + r * 0.25),
      Paint()..color = AppColors.border..strokeWidth = 2.5..strokeCap = StrokeCap.round,
    );
  }

  // — Milo Jazz (chapeau + yeux mi-clos)
  void _drawJazzMilo(Canvas canvas, Offset center, double r) {
    // Béret
    final beretPath = Path()
      ..moveTo(center.dx - r * 0.6, center.dy - r * 0.3)
      ..quadraticBezierTo(
        center.dx, center.dy - r * 1.1,
        center.dx + r * 0.6, center.dy - r * 0.3,
      );
    canvas.drawPath(
      beretPath,
      Paint()..color = const Color(0xFF4A3728),
    );
    canvas.drawPath(
      beretPath,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Yeux mi-clos (détendus)
    final eyePaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - r * 0.35, center.dy - r * 0.05),
      Offset(center.dx - r * 0.15, center.dy - r * 0.05),
      eyePaint,
    );
    canvas.drawLine(
      Offset(center.dx + r * 0.15, center.dy - r * 0.05),
      Offset(center.dx + r * 0.35, center.dy - r * 0.05),
      eyePaint,
    );

    // Petit sourire serein
    _drawSmile(canvas, center, r, wide: false);

    // ☕ Tasse de café (à droite)
    final cupPaint = Paint()..color = const Color(0xFFD4A574);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx + r * 0.6, center.dy + r * 0.35),
          width: r * 0.3,
          height: r * 0.25,
        ),
        const Radius.circular(3),
      ),
      cupPaint,
    );
    // Vapeur
    final steamPaint = Paint()
      ..color = AppColors.cream.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final steamPath = Path()
      ..moveTo(center.dx + r * 0.55, center.dy + r * 0.18)
      ..quadraticBezierTo(
        center.dx + r * 0.5, center.dy + r * 0.08,
        center.dx + r * 0.55, center.dy,
      );
    canvas.drawPath(steamPath, steamPaint);
  }

  // — Milo Chill (yeux fermés + zzz)
  void _drawChillMilo(Canvas canvas, Offset center, double r) {
    _drawMiniEar(canvas, Offset(center.dx - r * 0.7, center.dy - r * 0.6), r * 0.2, AppColors.success.withValues(alpha: 0.5));
    _drawMiniEar(canvas, Offset(center.dx + r * 0.7, center.dy - r * 0.6), r * 0.2, AppColors.success.withValues(alpha: 0.5));

    // Yeux fermés (lignes courbes)
    final eyePaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx - r * 0.25, center.dy - r * 0.05), width: r * 0.25, height: r * 0.15),
      0, math.pi, false, eyePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx + r * 0.25, center.dy - r * 0.05), width: r * 0.25, height: r * 0.15),
      0, math.pi, false, eyePaint,
    );

    // Petit O de la bouche (respiration)
    canvas.drawCircle(
      Offset(center.dx, center.dy + r * 0.25),
      r * 0.08,
      Paint()..color = AppColors.border,
    );

    // Zzz
    final zPaint = TextPainter(
      text: TextSpan(
        text: 'z z z',
        style: TextStyle(
          color: AppColors.success.withValues(alpha: 0.7),
          fontSize: r * 0.22,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    zPaint.paint(canvas, Offset(center.dx + r * 0.3, center.dy - r * 0.65));
  }

  // — Milo Kick (yeux furieux + bouche ouverte)
  void _drawKickMilo(Canvas canvas, Offset center, double r) {
    // Sourcils furieux
    final browPaint = Paint()
      ..color = AppColors.error
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - r * 0.4, center.dy - r * 0.25),
      Offset(center.dx - r * 0.15, center.dy - r * 0.15),
      browPaint,
    );
    canvas.drawLine(
      Offset(center.dx + r * 0.4, center.dy - r * 0.25),
      Offset(center.dx + r * 0.15, center.dy - r * 0.15),
      browPaint,
    );

    // Yeux furieux
    canvas.drawCircle(
      Offset(center.dx - r * 0.25, center.dy),
      r * 0.1,
      Paint()..color = AppColors.error,
    );
    canvas.drawCircle(
      Offset(center.dx + r * 0.25, center.dy),
      r * 0.1,
      Paint()..color = AppColors.error,
    );

    // Bouche ouverte (cri)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + r * 0.3),
        width: r * 0.4,
        height: r * 0.3,
      ),
      Paint()..color = AppColors.border,
    );

    // « ! ! »
    final exclamation = TextPainter(
      text: TextSpan(
        text: '!!',
        style: TextStyle(
          color: AppColors.error,
          fontSize: r * 0.3,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    exclamation.paint(canvas, Offset(center.dx + r * 0.4, center.dy - r * 0.6));
  }

  // — Milo Sprint (yeux déterminés + bandeau)
  void _drawSprintMilo(Canvas canvas, Offset center, double r) {
    // Bandeau de sport
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - r * 0.3),
        width: r * 1.6,
        height: r * 0.18,
      ),
      Paint()..color = AppColors.yellowVivid,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - r * 0.3),
        width: r * 1.6,
        height: r * 0.18,
      ),
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Yeux déterminés (triangles)
    final eyePaint = Paint()..color = AppColors.border;
    // Oeil gauche
    canvas.drawCircle(Offset(center.dx - r * 0.25, center.dy), r * 0.1, eyePaint);
    canvas.drawCircle(
      Offset(center.dx - r * 0.23, center.dy - r * 0.02),
      r * 0.04,
      Paint()..color = AppColors.cream,
    );
    // Oeil droit
    canvas.drawCircle(Offset(center.dx + r * 0.25, center.dy), r * 0.1, eyePaint);
    canvas.drawCircle(
      Offset(center.dx + r * 0.27, center.dy - r * 0.02),
      r * 0.04,
      Paint()..color = AppColors.cream,
    );

    // Sourire déterminé
    _drawSmile(canvas, center, r, wide: true);

    // Lignes de vitesse
    final speedPaint = Paint()
      ..color = AppColors.yellowVivid.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - r * 0.9, center.dy + r * 0.1),
      Offset(center.dx - r * 0.6, center.dy + r * 0.1),
      speedPaint,
    );
    canvas.drawLine(
      Offset(center.dx - r * 0.95, center.dy + r * 0.25),
      Offset(center.dx - r * 0.7, center.dy + r * 0.25),
      speedPaint,
    );
  }

  // — Helpers

  void _drawMiniEar(Canvas canvas, Offset center, double size, Color color) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: size, height: size * 1.5),
      Paint()..color = color,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: size, height: size * 1.5),
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawSmile(Canvas canvas, Offset center, double r, {required bool wide}) {
    final path = Path()
      ..moveTo(center.dx - r * (wide ? 0.25 : 0.15), center.dy + r * 0.2)
      ..quadraticBezierTo(
        center.dx,
        center.dy + r * (wide ? 0.45 : 0.35),
        center.dx + r * (wide ? 0.25 : 0.15),
        center.dy + r * 0.2,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MiloMoodPainter oldDelegate) =>
      mood != oldDelegate.mood || size != oldDelegate.size;
}
