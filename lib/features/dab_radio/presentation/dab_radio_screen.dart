import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/core/providers/audio_providers.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/features/dab_radio/models/dab_radio_station.dart';
import 'package:milo/features/dab_radio/presentation/dab_radio_categories_screen.dart';
import 'package:milo/features/dab_radio/presentation/open_dab_screen.dart';
import 'package:milo/shared/widgets/glass_card.dart';
import 'package:milo/shared/widgets/neo_brutal_container.dart';

/// Écran de sélection des radios DAB+.
class DabRadioScreen extends ConsumerStatefulWidget {
  const DabRadioScreen({super.key});

  @override
  ConsumerState<DabRadioScreen> createState() => _DabRadioScreenState();
}

class _DabRadioScreenState extends ConsumerState<DabRadioScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final playbackAsync = ref.watch(playbackStateProvider);
    final isPlaying = playbackAsync.valueOrNull?.playing ?? false;
    final currentTrackAsync = ref.watch(currentTrackProvider);
    final currentId = currentTrackAsync.valueOrNull?.id;

    final filteredStations = kDabRadioStations.where((station) {
      final query = _searchQuery.toLowerCase();
      return station.name.toLowerCase().contains(query) ||
             station.genre.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Radio DAB+'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.public),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const OpenDabScreen(),
                ),
              );
            },
            tooltip: 'Open DAB',
          ),
          IconButton(
            icon: const Icon(Icons.category_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DabRadioCategoriesScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
        children: [
          NeoBrutalContainer(
            padding: const EdgeInsets.all(20),
            backgroundColor: AppColors.yellowVivid,
            child: Row(
              children: [
                const Text('📻', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Radios DAB+',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.backgroundDeep,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stations françaises en direct',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.backgroundDeep
                                  .withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .moveY(begin: -10, end: 0),
          const SizedBox(height: 24),
          NeoBrutalContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            backgroundColor: AppColors.backgroundSurface,
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Rechercher une radio...',
                border: InputBorder.none,
                icon: Icon(Icons.search_rounded),
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          )
              .animate()
              .fadeIn(delay: 100.ms)
              .moveY(begin: -10, end: 0),
          const SizedBox(height: 24),
          ...List.generate(filteredStations.length, (i) {
            final station = filteredStations[i];
            final isCurrent = currentId == station.id;
            final showPlaying = isCurrent && isPlaying;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      alignment: Alignment.center,
                      child: Text(
                        station.logoEmoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${station.frequency} · ${station.genre}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.cream
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      showPlaying
                          ? Icons.equalizer_rounded
                          : isCurrent
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                      color: isCurrent
                          ? AppColors.yellowVivid
                          : AppColors.cream.withValues(alpha: 0.5),
                      size: 32,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 100 + i * 60))
                  .moveX(begin: 20, end: 0),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _toggleStation(DabRadioStation station) async {
    HapticFeedback.selectionClick();
    final handler = ref.read(audioHandlerProvider);
    final currentId = handler.mediaItem.valueOrNull?.id;

    if (currentId == station.id) {
      if (handler.player.playing) {
        await handler.pause();
      } else {
        await handler.play();
      }
      return;
    }

    await handler.playRadioStation(station);
  }
}
