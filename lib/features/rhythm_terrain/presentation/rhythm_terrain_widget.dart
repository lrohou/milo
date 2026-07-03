import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/features/rhythm_terrain/providers/rhythm_terrain_provider.dart';
import 'package:milo/shared/widgets/glass_card.dart';
import 'package:milo/shared/widgets/neo_brutal_container.dart';

/// Widget « Rythme du Terrain » — mode sport avec jauge d'effort.
class RhythmTerrainWidget extends ConsumerWidget {
  const RhythmTerrainWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Active le contrôleur de sprint
    ref.watch(rhythmTerrainControllerProvider);

    final isActive = ref.watch(rhythmTerrainActiveProvider);
    final effortAsync = ref.watch(effortLevelProvider);
    final effort = effortAsync.valueOrNull ?? 0.0;
    final normalized = (effort / 18.0).clamp(0.0, 1.0);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '🏀',
                style: const TextStyle(fontSize: 28),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .shake(hz: 2, rotation: 0.05, duration: 800.ms),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rythme du Terrain',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Sprint détecté → BPM max',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Switch(
                value: isActive,
                activeThumbColor: AppColors.yellowVivid,
                activeTrackColor: AppColors.yellowGold,
                onChanged: (v) {
                  HapticFeedback.mediumImpact();
                  ref.read(rhythmTerrainActiveProvider.notifier).state = v;
                },
              ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 24),
            Text(
              'Intensité',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            _EffortBar(level: normalized),
            const SizedBox(height: 12),
            NeoBrutalContainer(
              backgroundColor: normalized > 0.8
                  ? AppColors.yellowVivid
                  : AppColors.backgroundSurface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              withShadow: normalized > 0.8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    normalized > 0.8
                        ? Icons.bolt_rounded
                        : Icons.directions_run_rounded,
                    color: normalized > 0.8
                        ? AppColors.backgroundDeep
                        : AppColors.cream,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    normalized > 0.8
                        ? 'SPRINT ! File BPM max activée'
                        : 'En attente de mouvement…',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: normalized > 0.8
                              ? AppColors.backgroundDeep
                              : AppColors.cream,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ).animate(target: normalized > 0.8 ? 1 : 0).shake(hz: 3),
          ],
        ],
      ),
    );
  }
}

class _EffortBar extends StatelessWidget {
  const _EffortBar({required this.level});

  final double level;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              height: 24,
              width: constraints.maxWidth,
              decoration: BoxDecoration(
                color: AppColors.backgroundDeep,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 2),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              height: 24,
              width: constraints.maxWidth * level,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.yellowGold,
                    if (level > 0.8) AppColors.error else AppColors.yellowVivid,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 2),
              ),
            ),
          ],
        );
      },
    );
  }
}
