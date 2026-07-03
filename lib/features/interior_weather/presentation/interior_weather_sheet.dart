import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/features/interior_weather/models/draw_point.dart';
import 'package:milo/features/interior_weather/services/shape_detection_service.dart';
import 'package:milo/features/interior_weather/services/weather_mood.dart';
import 'package:milo/features/library/providers/library_providers.dart';
import 'package:milo/shared/widgets/glass_card.dart';
import 'package:milo/shared/widgets/neo_brutal_button.dart';

/// Affiche le bottom sheet « Météo Intérieure » avec canvas de dessin.
void showInteriorWeatherSheet(BuildContext context, WidgetRef ref) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const InteriorWeatherSheet(),
  );
}

class InteriorWeatherSheet extends ConsumerStatefulWidget {
  const InteriorWeatherSheet({super.key});

  @override
  ConsumerState<InteriorWeatherSheet> createState() =>
      _InteriorWeatherSheetState();
}

class _InteriorWeatherSheetState extends ConsumerState<InteriorWeatherSheet> {
  final List<DrawPoint> _points = [];
  WeatherMood? _detectedMood;
  bool _showResult = false;

  @override
  Widget build(BuildContext context) {
    final hasFilter = ref.watch(filteredTracksProvider) != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.glassFill,
                border: Border.all(color: AppColors.glassBorder, width: 2),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  // — Poignée
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.cream.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // — Titre
                  Text(
                    'Météo Intérieure',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dessine une forme — Milo devine ton ambiance',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // — Légende des formes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: WeatherMood.values.map((mood) {
                      final isActive = _detectedMood == mood;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.yellowVivid.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.yellowVivid
                                  : AppColors.cream.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '${mood.emoji} ${mood.label}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: 11,
                                  color: isActive
                                      ? AppColors.yellowVivid
                                      : AppColors.cream.withValues(alpha: 0.5),
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // — Canvas de dessin
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: AspectRatio(
                      aspectRatio: 1.2,
                      child: GestureDetector(
                        onPanStart: (d) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _points.add(DrawPoint(d.localPosition, true));
                            _detectedMood = null;
                            _showResult = false;
                          });
                        },
                        onPanUpdate: (d) {
                          setState(() {
                            _points.add(DrawPoint(d.localPosition, true));
                          });
                        },
                        onPanEnd: (_) => _analyzeShape(),
                        child: CustomPaint(
                          painter: _WeatherCanvasPainter(
                            points: _points,
                            detectedMood: _detectedMood,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // — Résultat détecté (animé)
                  if (_detectedMood != null && _showResult) ...[
                    _MoodResultCard(mood: _detectedMood!)
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1, 1),
                          duration: 300.ms,
                          curve: Curves.easeOutBack,
                        ),
                    const SizedBox(height: 16),
                    NeoBrutalButton(
                      label: 'Appliquer le filtre',
                      icon: Icons.filter_list_rounded,
                      expanded: true,
                      onPressed: () => _applyFilter(_detectedMood!),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // — Réinitialiser le filtre (si actif)
                  if (hasFilter)
                    NeoBrutalButton(
                      label: 'Réinitialiser le filtre',
                      icon: Icons.clear_all_rounded,
                      backgroundColor: AppColors.yellowGold,
                      expanded: true,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ref.read(filteredTracksProvider.notifier).state = null;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Filtre réinitialisé — bibliothèque complète'),
                            backgroundColor: AppColors.backgroundSurface,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  if (hasFilter) const SizedBox(height: 12),

                  NeoBrutalButton(
                    label: 'Effacer le dessin',
                    icon: Icons.refresh_rounded,
                    backgroundColor: AppColors.backgroundSurface,
                    foregroundColor: AppColors.cream,
                    expanded: true,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _points.clear();
                        _detectedMood = null;
                        _showResult = false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _analyzeShape() {
    if (_points.length < 5) return;
    HapticFeedback.mediumImpact();
    final mood = ShapeDetectionService.detect(_points);
    setState(() {
      _detectedMood = mood;
      _showResult = true;
    });
  }

  void _applyFilter(WeatherMood mood) {
    HapticFeedback.heavyImpact();
    final library = ref.read(libraryProvider).valueOrNull ?? [];
    final filtered = ShapeDetectionService.filterTracks(library, mood);
    ref.read(filteredTracksProvider.notifier).state = filtered;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${mood.emoji} ${filtered.length} morceaux — ${mood.label}'),
        backgroundColor: AppColors.backgroundSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _WeatherCanvasPainter extends CustomPainter {
  _WeatherCanvasPainter({required this.points, this.detectedMood});

  final List<DrawPoint> points;
  final WeatherMood? detectedMood;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.backgroundDeep.withValues(alpha: 0.5),
    );

    if (points.isEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '☀️  ⚡  🌧️\nDessine ici',
          style: TextStyle(
            color: AppColors.cream.withValues(alpha: 0.3),
            fontSize: 24,
            height: 1.6,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );
      return;
    }

    // Tracé du dessin
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (i == 0 || !p.isDrawing) {
        path.moveTo(p.offset.dx, p.offset.dy);
      } else {
        path.lineTo(p.offset.dx, p.offset.dy);
      }
    }

    // Glow derrière le tracé si forme détectée
    if (detectedMood != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.yellowVivid.withValues(alpha: 0.15)
          ..strokeWidth = 16
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = detectedMood != null
            ? AppColors.yellowVivid
            : AppColors.cream.withValues(alpha: 0.8)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _WeatherCanvasPainter oldDelegate) =>
      points.length != oldDelegate.points.length ||
      detectedMood != oldDelegate.detectedMood;
}

class _MoodResultCard extends StatelessWidget {
  const _MoodResultCard({required this.mood});

  final WeatherMood mood;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.yellowVivid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 3),
        boxShadow: const [
          BoxShadow(
            color: AppColors.yellowGold,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(mood.emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mood.label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.backgroundDeep,
                      ),
                ),
                Text(
                  mood.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.backgroundDeep.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
