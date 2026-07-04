import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/core/providers/audio_providers.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/features/player/presentation/screens/now_playing_screen.dart';
import 'package:milo/shared/widgets/milo_artwork_widget.dart';

final isPlayerExpandedProvider = StateProvider<bool>((ref) => false);

class PlayerOverlay extends ConsumerWidget {
  const PlayerOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(isPlayerExpandedProvider);
    final mediaAsync = ref.watch(currentTrackProvider);
    final media = mediaAsync.valueOrNull;

    if (media == null) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      height: isExpanded ? MediaQuery.of(context).size.height : 80,
      child: GestureDetector(
        onTap: () {
          if (!isExpanded) ref.read(isPlayerExpandedProvider.notifier).state = true;
        },
        onVerticalDragUpdate: (details) {
          if (details.delta.dy > 5 && isExpanded) {
            ref.read(isPlayerExpandedProvider.notifier).state = false;
          } else if (details.delta.dy < -5 && !isExpanded) {
            ref.read(isPlayerExpandedProvider.notifier).state = true;
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundSurface,
            borderRadius: isExpanded ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
            border: const Border(top: BorderSide(color: AppColors.border, width: 2)),
          ),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: SizedBox(
              height: isExpanded ? MediaQuery.of(context).size.height : 80,
              child: isExpanded ? const NowPlayingScreen() : const MiniPlayer(),
            ),
          ),
        ),
      ),
    );
  }
}

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(currentTrackProvider);
    final playbackAsync = ref.watch(playbackStateProvider);
    final handler = ref.watch(audioHandlerProvider);

    final media = mediaAsync.valueOrNull;
    final isPlaying = playbackAsync.valueOrNull?.playing ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          if (media != null) MiloArtworkWidget(id: media.id, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  media?.title ?? 'Aucun morceau',
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  media?.artist ?? '—',
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: AppColors.cream, size: 32),
            onPressed: () {
              isPlaying ? handler.pause() : handler.play();
            },
          ),
          IconButton(
            icon: const Icon(Icons.skip_next_rounded, color: AppColors.cream, size: 32),
            onPressed: () {
              handler.skipToNext();
            },
          ),
        ],
      ),
    );
  }
}
