import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/core/providers/audio_providers.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/features/dab_radio/models/dab_radio_station.dart';
import 'package:milo/shared/widgets/glass_card.dart';

class DabRadioCategoryDetailScreen extends ConsumerStatefulWidget {
  const DabRadioCategoryDetailScreen({
    super.key,
    required this.title,
    required this.stations,
  });

  final String title;
  final List<DabRadioStation> stations;

  @override
  ConsumerState<DabRadioCategoryDetailScreen> createState() =>
      _DabRadioCategoryDetailScreenState();
}

class _DabRadioCategoryDetailScreenState
    extends ConsumerState<DabRadioCategoryDetailScreen> {
  
  @override
  Widget build(BuildContext context) {
    final playbackAsync = ref.watch(playbackStateProvider);
    final isPlaying = playbackAsync.valueOrNull?.playing ?? false;
    final currentTrackAsync = ref.watch(currentTrackProvider);
    final currentId = currentTrackAsync.valueOrNull?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: widget.stations.length,
        itemBuilder: (context, index) {
          final station = widget.stations[index];
          final isCurrent = currentId == station.id;
          final showPlaying = isCurrent && isPlaying;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onTap: () => _toggleStation(station),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.yellowVivid
                          : AppColors.backgroundSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        station.logoEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: isCurrent
                                    ? AppColors.yellowVivid
                                    : AppColors.textPrimary,
                                fontWeight: isCurrent ? FontWeight.w900 : null,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          station.genre,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (showPlaying)
                     const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.volume_up_rounded, color: AppColors.yellowVivid),
                    ),
                  if (!isCurrent)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.play_arrow_rounded, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (50 * index).ms).moveY(begin: 10, end: 0);
        },
      ),
    );
  }

  void _toggleStation(DabRadioStation station) {
    if (ref.read(currentTrackProvider).valueOrNull?.id == station.id) {
      if (ref.read(playbackStateProvider).valueOrNull?.playing == true) {
        ref.read(audioPlayerServiceProvider).pause();
      } else {
        ref.read(audioPlayerServiceProvider).play();
      }
    } else {
      ref.read(audioPlayerServiceProvider).playRadioStream(
            station.streamUrl,
            station.name,
            genre: station.genre,
            id: station.id,
          );
    }
  }
}
