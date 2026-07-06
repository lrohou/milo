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

    return PopScope(
      canPop: !isExpanded,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && isExpanded) {
          ref.read(isPlayerExpandedProvider.notifier).state = false;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        height: isExpanded ? MediaQuery.of(context).size.height : 80,
        child: GestureDetector(
          onTap: () {
            if (!isExpanded) {
              ref.read(isPlayerExpandedProvider.notifier).state = true;
            }
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
              borderRadius: isExpanded
                  ? BorderRadius.zero
                  : const BorderRadius.vertical(top: Radius.circular(20)),
              border: const Border(
                top: BorderSide(color: AppColors.border, width: 2),
              ),
            ),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                height: isExpanded
                    ? MediaQuery.of(context).size.height
                    : 80,
                child: isExpanded
                    ? const NowPlayingScreen()
                    : const MiniPlayer(),
              ),
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
                // Marquee-style scrolling title in mini player
                SizedBox(
                  height: 24,
                  child: _MarqueeText(
                    text: media?.title ?? 'Aucun morceau',
                    style: Theme.of(context).textTheme.titleLarge!,
                  ),
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
            icon: const Icon(Icons.skip_previous_rounded,
                color: AppColors.cream, size: 32),
            onPressed: () => handler.skipToPrevious(),
          ),
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: AppColors.yellowVivid,
              size: 32,
            ),
            onPressed: () {
              if (isPlaying) {
                handler.pause();
              } else {
                handler.play();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.skip_next_rounded,
                color: AppColors.cream, size: 32),
            onPressed: () => handler.skipToNext(),
          ),
        ],
      ),
    );
  }
}

/// Widget texte défilant custom (pas de dépendance externe).
class _MarqueeText extends StatefulWidget {
  const _MarqueeText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _needsScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndScroll());
  }

  @override
  void didUpdateWidget(_MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _scrollController.jumpTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndScroll());
    }
  }

  void _checkAndScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    _needsScroll =
        _scrollController.position.maxScrollExtent > 0;
    if (_needsScroll) {
      _startScrolling();
    }
  }

  Future<void> _startScrolling() async {
    while (mounted && _scrollController.hasClients && _needsScroll) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || !_scrollController.hasClients) return;
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(
          milliseconds:
              (_scrollController.position.maxScrollExtent * 30).toInt(),
        ),
        curve: Curves.linear,
      );
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || !_scrollController.hasClients) return;
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}
