import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:milo/core/providers/audio_providers.dart';
import 'package:milo/core/theme/app_colors.dart';

import 'package:milo/features/likes/providers/likes_provider.dart';
import 'package:milo/features/mood_avatars/widgets/dynamic_milo_avatar.dart';
import 'package:milo/features/player/presentation/widgets/player_overlay.dart';
import 'package:milo/features/rhythm_terrain/presentation/rhythm_terrain_widget.dart';
import 'package:milo/shared/widgets/milo_artwork_widget.dart';

/// Écran « Lecture en cours » avec égaliseur Grandes Oreilles.
class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackAsync = ref.watch(playbackStateProvider);
    final mediaAsync = ref.watch(currentTrackProvider);
    final handler = ref.watch(audioHandlerProvider);

    final media = mediaAsync.valueOrNull;
    final isPlaying = playbackAsync.valueOrNull?.playing ?? false;
    final isRadio = media?.extras?['isRadio'] == true;
    final radioEmoji = media?.extras?['emoji'] as String? ?? '📻';

    return SafeArea(
      child: NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels < -50) {
            ref.read(isPlayerExpandedProvider.notifier).state = false;
            return true;
          }
          return false;
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const DynamicMiloAvatar(size: 64),
                  Row(
                    children: [
                      if (!isRadio)
                        StreamBuilder<bool>(
                          stream: handler.player.shuffleModeEnabledStream,
                          builder: (context, snapshot) {
                            final isEnabled = snapshot.data ?? false;
                            return IconButton(
                              icon: Icon(
                                isEnabled
                                    ? Icons.shuffle_on_rounded
                                    : Icons.shuffle_rounded,
                                color: AppColors.cream,
                              ),
                              onPressed: () async {
                                HapticFeedback.selectionClick();
                                if (isEnabled) {
                                  await handler.setShuffleMode(
                                      AudioServiceShuffleMode.none);
                                } else {
                                  await handler.setShuffleMode(
                                      AudioServiceShuffleMode.all);
                                }
                              },
                            );
                          },
                        ),
                      if (!isRadio)
                        IconButton(
                          icon: const Icon(Icons.queue_music_rounded,
                              color: AppColors.cream),
                          onPressed: () => _showQueue(context, handler),
                        ),
                      IconButton(
                        icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.cream),
                        onPressed: () {
                          ref.read(isPlayerExpandedProvider.notifier).state =
                              false;
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // — Infos morceau ou radio
              if (media != null) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity == null) return;
                        if (details.primaryVelocity! < -300) {
                          HapticFeedback.lightImpact();
                          handler.skipToNext();
                        } else if (details.primaryVelocity! > 300) {
                          HapticFeedback.lightImpact();
                          handler.skipToPrevious();
                        }
                      },
                      child: isRadio
                          ? Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                color: AppColors.backgroundDeep,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppColors.border, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.yellowVivid.withValues(alpha: 0.2),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(radioEmoji, style: const TextStyle(fontSize: 120)),
                              ),
                            )
                          : MiloArtworkWidget(
                              id: media.id, size: 280, borderRadius: 24),
                    ),
                  ),
                ),

                // — Titre défilant + bouton Like (pas de Like pour radio)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: _MarqueeTitle(
                          text: media.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium!,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!isRadio) _LikeButton(trackId: media.id),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  media.artist ?? (isRadio ? 'Radio DAB+' : 'Artiste inconnu'),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.cream.withValues(alpha: 0.7),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ] else
                Text(
                  'Aucun morceau',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),

              const SizedBox(height: 24),

              // — Seek bar (barre de progression) - pas pour radio
              if (!isRadio) _SeekBar(handler: handler),
              if (isRadio)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.glassFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isPlaying ? AppColors.success : AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isPlaying ? 'En direct' : 'Arrêté',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.cream,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // — Contrôles lecture
              _PlaybackControls(
                isPlaying: isPlaying,
                onPlayPause: () {
                  HapticFeedback.mediumImpact();
                  isPlaying ? handler.pause() : handler.play();
                },
                onPrevious: () {
                  HapticFeedback.lightImpact();
                  handler.skipToPrevious();
                },
                onNext: () {
                  HapticFeedback.lightImpact();
                  handler.skipToNext();
                },
              ),

              // — Espacement entre contrôles et Rythme du Terrain
              const SizedBox(height: 40),

              // — Rythme du Terrain (mode sport) - pas pour radio
              if (!isRadio) const RhythmTerrainWidget(),
            ],
          ),
        ),
      ),
    );
  }

  void _showQueue(BuildContext context, dynamic handler) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text("File d'attente",
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: handler.tracks.length,
              itemBuilder: (context, index) {
                final track = handler.tracks[index];
                final isPlaying = index == handler.currentIndex;
                return ListTile(
                  leading: Icon(
                    isPlaying
                        ? Icons.play_arrow_rounded
                        : Icons.music_note_rounded,
                    color: isPlaying
                        ? AppColors.yellowVivid
                        : AppColors.cream,
                  ),
                  title: Text(track.title,
                      style: TextStyle(
                          color: isPlaying
                              ? AppColors.yellowVivid
                              : AppColors.cream)),
                  subtitle: Text(track.artist,
                      style: TextStyle(
                          color: AppColors.cream.withValues(alpha: 0.6))),
                  onTap: () {
                    handler.skipToQueueItem(index);
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Like Button ────────────────────────────────────────────────────────────

class _LikeButton extends ConsumerWidget {
  const _LikeButton({required this.trackId});
  final String trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(likesProvider).contains(trackId);
    return IconButton(
      icon: Icon(
        liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: liked ? AppColors.error : AppColors.cream,
        size: 28,
      ),
      onPressed: () {
        HapticFeedback.selectionClick();
        ref.read(likesProvider.notifier).toggleLike(trackId);
      },
    );
  }
}

// ─── Marquee Title (custom, no dependency) ──────────────────────────────────

class _MarqueeTitle extends StatefulWidget {
  const _MarqueeTitle({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_MarqueeTitle> createState() => _MarqueeTitleState();
}

class _MarqueeTitleState extends State<_MarqueeTitle> {
  late ScrollController _scrollController;
  bool _needsScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndScroll());
  }

  @override
  void didUpdateWidget(_MarqueeTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _scrollController.jumpTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndScroll());
    }
  }

  void _checkAndScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    _needsScroll = _scrollController.position.maxScrollExtent > 0;
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

// ─── Seek Bar ───────────────────────────────────────────────────────────────

class _SeekBar extends StatelessWidget {
  const _SeekBar({required this.handler});

  final dynamic handler;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: handler.player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration =
            handler.player.duration ?? const Duration(seconds: 1);
        final progress = duration.inMilliseconds > 0
            ? (position.inMilliseconds / duration.inMilliseconds)
                .clamp(0.0, 1.0)
            : 0.0;

        return Column(
          children: [
            GestureDetector(
              onTapDown: (details) {
                HapticFeedback.selectionClick();
                final box = context.findRenderObject() as RenderBox?;
                if (box != null) {
                  final ratio = details.localPosition.dx / box.size.width;
                  final seekPos = Duration(
                    milliseconds:
                        (ratio * duration.inMilliseconds).round(),
                  );
                  handler.seek(seekPos);
                }
              },
              onHorizontalDragUpdate: (details) {
                final box = context.findRenderObject() as RenderBox?;
                if (box != null) {
                  final ratio =
                      (details.localPosition.dx / box.size.width)
                          .clamp(0.0, 1.0);
                  final seekPos = Duration(
                    milliseconds:
                        (ratio * duration.inMilliseconds).round(),
                  );
                  handler.seek(seekPos);
                }
              },
              child: Container(
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.backgroundSurface,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.border, width: 2.5),
                ),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.yellowGold,
                              AppColors.yellowVivid,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment(progress * 2 - 1, 0),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.border,
                            width: 2.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.yellowGold,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.yellowVivid,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  _formatDuration(duration),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.cream.withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes =
        d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

// ─── Playback Controls ──────────────────────────────────────────────────────

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({
    required this.isPlaying,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
  });

  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlButton(
            icon: Icons.skip_previous_rounded, onTap: onPrevious),
        const SizedBox(width: 24),
        _ControlButton(
          icon: isPlaying
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          size: 72,
          filled: true,
          onTap: onPlayPause,
        )
            .animate(target: isPlaying ? 1 : 0)
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.05, 1.05),
              duration: 300.ms,
            ),
        const SizedBox(width: 24),
        _ControlButton(
            icon: Icons.skip_next_rounded, onTap: onNext),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.size = 56,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled
              ? AppColors.yellowVivid
              : AppColors.backgroundSurface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 3),
          boxShadow: filled
              ? const [
                  BoxShadow(
                    color: AppColors.yellowGold,
                    offset: Offset(4, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: filled ? AppColors.backgroundDeep : AppColors.cream,
          size: size * 0.45,
        ),
      ),
    );
  }
}
