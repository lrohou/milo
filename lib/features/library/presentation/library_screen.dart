import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/core/providers/audio_providers.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/features/library/providers/library_providers.dart';
import 'package:milo/shared/widgets/glass_card.dart';

/// Bibliothèque locale — liste des morceaux scannés.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryAsync = ref.watch(libraryProvider);
    final tracks = ref.watch(effectiveLibraryProvider);
    final handler = ref.watch(audioHandlerProvider);

    return libraryAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.yellowVivid),
      ),
      error: (e, _) => Center(child: Text('Erreur : $e')),
      data: (_) => RefreshIndicator(
        color: AppColors.yellowVivid,
        onRefresh: () async {
          ref.invalidate(libraryProvider);
          await ref.read(libraryProvider.future);
        },
        child: tracks.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Aucun morceau trouvé')),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        await handler.loadQueue(tracks, startIndex: index);
                        await handler.play();
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.yellowVivid,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.border,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.music_note_rounded,
                              color: AppColors.backgroundDeep,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track.title,
                                  style:
                                      Theme.of(context).textTheme.titleLarge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${track.artist} · ${track.effectiveBpm} BPM',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            track.genre ?? '—',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.yellowGold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
