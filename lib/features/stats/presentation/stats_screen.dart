import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/features/stats/providers/stats_provider.dart';
import 'package:milo/features/library/providers/library_providers.dart';
import 'package:milo/shared/widgets/glass_card.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _shareScreenshot() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = await _screenshotController.captureAndSave(
        directory.path,
        fileName: 'milo_stats_${DateTime.now().millisecondsSinceEpoch}.png',
        pixelRatio: 2.0,
      );

      if (imagePath != null && mounted) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(imagePath)],
            text: 'Mes stats d\'écoute Milo du mois !',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du partage : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsProvider);
    final libraryAsync = ref.watch(libraryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.cream),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Récapitulatif du mois',
            style: TextStyle(color: AppColors.cream)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded,
                color: AppColors.yellowVivid),
            onPressed: () {
              HapticFeedback.selectionClick();
              _shareScreenshot();
            },
          ),
        ],
      ),
      body: libraryAsync.when(
        loading: () => const Center(
            child:
                CircularProgressIndicator(color: AppColors.yellowVivid)),
        error: (e, _) => Center(
            child: Text('Erreur: $e',
                style: const TextStyle(color: AppColors.cream))),
        data: (library) {
          if (stats.isEmpty) {
            return const Center(
              child: Text('Aucune donnée pour ce mois-ci.',
                  style: TextStyle(color: AppColors.cream)),
            );
          }

          final sortedStats = stats.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final topTracks = sortedStats.take(10).toList();

          return Screenshot(
            controller: _screenshotController,
            child: Container(
              color: AppColors.backgroundDeep,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Vos Tops Écoutes',
                    style: TextStyle(
                      color: AppColors.yellowVivid,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...topTracks.map((entry) {
                    final trackMatch = library.where((t) => t.id == entry.key);
                    if (trackMatch.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final track = trackMatch.first;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.yellowGold,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.value}x',
                                  style: const TextStyle(
                                      color: AppColors.backgroundDeep,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track.title,
                                    style: const TextStyle(
                                        color: AppColors.cream,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    track.artist,
                                    style: TextStyle(
                                        color: AppColors.cream
                                            .withValues(alpha: 0.6),
                                        fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 40),
                  const Center(
                    child: Text(
                      'Généré avec Milo',
                      style:
                          TextStyle(color: AppColors.border, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
