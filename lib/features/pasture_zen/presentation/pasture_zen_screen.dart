import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/core/providers/audio_providers.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/features/library/providers/library_providers.dart';
import 'package:milo/features/pasture_zen/services/pasture_clustering_service.dart';
import 'package:milo/shared/widgets/glass_card.dart';
import 'package:milo/shared/widgets/neo_brutal_button.dart';

final pastureClusteringProvider = Provider<PastureClusteringService>(
  (ref) => PastureClusteringService(),
);

final pastureClustersProvider = Provider<List<PastureCluster>>((ref) {
  final library = ref.watch(effectiveLibraryProvider);
  return ref.watch(pastureClusteringProvider).clusterTracks(library);
});

/// Carte spatiale Canvas interactive — îlots de morceaux « Pâture Zen ».
class PastureZenScreen extends ConsumerStatefulWidget {
  const PastureZenScreen({super.key});

  @override
  ConsumerState<PastureZenScreen> createState() => _PastureZenScreenState();
}

class _PastureZenScreenState extends ConsumerState<PastureZenScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedCluster;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clusters = ref.watch(pastureClustersProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pâture Zen', style: Theme.of(context).textTheme.displayMedium)
              .animate()
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 4),
          Text(
            'Tes morceaux regroupés par ambiance',
            style: Theme.of(context).textTheme.bodyLarge,
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 20),

          // — Carte spatiale interactive
          Expanded(
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: clusters.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🌿', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            'Aucun morceau à regrouper',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onTapDown: (details) =>
                              _onTapCanvas(details, constraints, clusters),
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, _) {
                              return CustomPaint(
                                painter: _PastureMapPainter(
                                  clusters: clusters,
                                  selectedCluster: _selectedCluster,
                                  pulseValue: _pulseController.value,
                                ),
                                size: Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),

          // — Détail du cluster sélectionné
          if (_selectedCluster != null &&
              _selectedCluster! < clusters.length) ...[
            const SizedBox(height: 16),
            _ClusterDetail(
              cluster: clusters[_selectedCluster!],
              onPlay: () => _playCluster(clusters[_selectedCluster!]),
              onDismiss: () => setState(() => _selectedCluster = null),
            ),
          ],
        ],
      ),
    );
  }

  void _onTapCanvas(
    TapDownDetails details,
    BoxConstraints constraints,
    List<PastureCluster> clusters,
  ) {
    HapticFeedback.selectionClick();
    final tapX = details.localPosition.dx / constraints.maxWidth;
    final tapY = details.localPosition.dy / constraints.maxHeight;

    for (var i = 0; i < clusters.length; i++) {
      final c = clusters[i];
      final dx = tapX - c.centerX;
      final dy = tapY - c.centerY;
      final dist = math.sqrt(dx * dx + dy * dy);
      final radius = (30.0 + c.tracks.length * 8.0) /
          math.min(constraints.maxWidth, constraints.maxHeight);

      if (dist < radius * 1.3) {
        HapticFeedback.mediumImpact();
        setState(() => _selectedCluster = i);
        return;
      }
    }

    setState(() => _selectedCluster = null);
  }

  Future<void> _playCluster(PastureCluster cluster) async {
    HapticFeedback.heavyImpact();
    final handler = ref.read(audioHandlerProvider);
    await handler.loadQueue(cluster.tracks);
    await handler.play();
  }
}

/// Carte du cluster sélectionné.
class _ClusterDetail extends StatelessWidget {
  const _ClusterDetail({
    required this.cluster,
    required this.onPlay,
    required this.onDismiss,
  });

  final PastureCluster cluster;
  final VoidCallback onPlay;
  final VoidCallback onDismiss;

  static const _clusterEmojis = ['🌴', '🏔️', '🌊', '🌻', '🍃', '🌙'];

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _clusterEmojis[cluster.id % _clusterEmojis.length],
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cluster.label,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${cluster.tracks.length} morceaux',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.cream),
                onPressed: onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Liste des premiers morceaux
          ...cluster.tracks.take(3).map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.music_note_rounded,
                          color: AppColors.yellowGold, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${t.title} — ${t.artist}',
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (cluster.tracks.length > 3)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '+ ${cluster.tracks.length - 3} autres…',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.cream.withValues(alpha: 0.5)),
              ),
            ),
          const SizedBox(height: 12),
          NeoBrutalButton(
            label: 'Jouer cette pâture',
            icon: Icons.play_arrow_rounded,
            expanded: true,
            onPressed: onPlay,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .moveY(begin: 20, end: 0, curve: Curves.easeOutCubic);
  }
}

class _PastureMapPainter extends CustomPainter {
  _PastureMapPainter({
    required this.clusters,
    required this.selectedCluster,
    required this.pulseValue,
  });

  final List<PastureCluster> clusters;
  final int? selectedCluster;
  final double pulseValue;

  static const _colors = [
    AppColors.yellowVivid,
    AppColors.yellowGold,
    AppColors.cream,
    AppColors.success,
    Color(0xFF88CCFF),
    Color(0xFFFF8888),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Fond
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.backgroundDeep.withValues(alpha: 0.6),
    );

    // Grille de points décorative
    final dotPaint = Paint()
      ..color = AppColors.cream.withValues(alpha: 0.05);
    for (var x = 20.0; x < size.width; x += 30) {
      for (var y = 20.0; y < size.height; y += 30) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }

    // Connexions entre clusters (lignes décoratives)
    if (clusters.length > 1) {
      for (var i = 0; i < clusters.length - 1; i++) {
        final a = clusters[i];
        final b = clusters[i + 1];
        canvas.drawLine(
          Offset(a.centerX * size.width, a.centerY * size.height),
          Offset(b.centerX * size.width, b.centerY * size.height),
          Paint()
            ..color = AppColors.cream.withValues(alpha: 0.08)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke,
        );
      }
    }

    for (var ci = 0; ci < clusters.length; ci++) {
      final cluster = clusters[ci];
      final center = Offset(
        cluster.centerX * size.width,
        cluster.centerY * size.height,
      );
      final baseRadius = 30.0 + cluster.tracks.length * 8.0;
      final isSelected = selectedCluster == ci;
      final color = _colors[ci % _colors.length];

      // Pulse du cluster sélectionné
      if (isSelected) {
        final pulseRadius = baseRadius + pulseValue * 12;
        canvas.drawCircle(
          center,
          pulseRadius,
          Paint()
            ..color = color.withValues(alpha: 0.15 + pulseValue * 0.1)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }

      // Cercle de l'îlot
      canvas.drawCircle(
        center,
        baseRadius,
        Paint()
          ..color = color.withValues(alpha: isSelected ? 0.5 : 0.3),
      );
      canvas.drawCircle(
        center,
        baseRadius,
        Paint()
          ..color = isSelected ? color : AppColors.border
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 3.5 : 2,
      );

      // Points individuels (morceaux)
      for (var i = 0; i < cluster.tracks.length; i++) {
        final angle = (i / cluster.tracks.length) * 2 * math.pi;
        final r = baseRadius * (0.3 + (i % 3) * 0.15);
        final dotCenter = center +
            Offset(
              math.cos(angle) * r,
              math.sin(angle) * r,
            );
        canvas.drawCircle(
          dotCenter,
          isSelected ? 5 : 4,
          Paint()..color = isSelected ? color : AppColors.cream,
        );
        if (isSelected) {
          canvas.drawCircle(
            dotCenter,
            5,
            Paint()
              ..color = AppColors.border
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
      }

      // Label
      final tp = TextPainter(
        text: TextSpan(
          text: '${cluster.label}\n(${cluster.tracks.length})',
          style: TextStyle(
            color: isSelected ? color : AppColors.cream,
            fontSize: isSelected ? 12 : 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: baseRadius * 2);
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _PastureMapPainter oldDelegate) =>
      clusters != oldDelegate.clusters ||
      selectedCluster != oldDelegate.selectedCluster ||
      pulseValue != oldDelegate.pulseValue;
}
