import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/core/providers/audio_providers.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/features/interior_weather/presentation/interior_weather_sheet.dart';
import 'package:milo/features/mood_avatars/widgets/dynamic_milo_avatar.dart';
import 'package:milo/features/player/presentation/widgets/milo_equalizer_widget.dart';
import 'package:milo/features/rhythm_terrain/presentation/rhythm_terrain_widget.dart';
import 'package:milo/shared/widgets/neo_brutal_button.dart';

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

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // — En-tête : Avatar Milo + bouton Météo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const DynamicMiloAvatar(size: 64),
                NeoBrutalButton(
                  label: 'Météo',
                  icon: Icons.draw_rounded,
                  onPressed: () => showInteriorWeatherSheet(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // — Infos morceau
            if (media != null) ...[
              Text(
                media.title,
                style: Theme.of(context).textTheme.headlineMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                media.artist ?? 'Artiste inconnu',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.cream.withValues(alpha: 0.7),
                    ),
              ),
            ] else
              Text(
                'Aucun morceau',
                style: Theme.of(context).textTheme.headlineMedium,
              ),

            const SizedBox(height: 24),

            // — Seek bar (barre de progression)
            _SeekBar(handler: handler),

            const SizedBox(height: 32),

            // — Égaliseur Grandes Oreilles
            const MiloEqualizerWidget(),

            const SizedBox(height: 32),

            // — Rythme du Terrain (mode sport)
            const RhythmTerrainWidget(),

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
          ],
        ),
      ),
    );
  }
}

/// Barre de progression avec position et durée.
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
            ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;

        return Column(
          children: [
            // Barre de progression néo-brutaliste
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
                      (details.localPosition.dx / box.size.width).clamp(0.0, 1.0);
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
                  border: Border.all(color: AppColors.border, width: 2.5),
                ),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.yellowGold, AppColors.yellowVivid],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    // Thumb
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
            // Temps position / durée
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
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

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
        _ControlButton(icon: Icons.skip_previous_rounded, onTap: onPrevious),
        const SizedBox(width: 24),
        _ControlButton(
          icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
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
        _ControlButton(icon: Icons.skip_next_rounded, onTap: onNext),
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
          color: filled ? AppColors.yellowVivid : AppColors.backgroundSurface,
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
