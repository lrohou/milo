import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/core/providers/audio_providers.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/features/library/providers/library_providers.dart';
import 'package:milo/shared/widgets/glass_card.dart';
import 'package:milo/shared/widgets/milo_artwork_widget.dart';

/// Bibliothèque locale — liste des morceaux scannés avec recherche.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryAsync = ref.watch(libraryProvider);
    final allTracks = ref.watch(effectiveLibraryProvider);
    final handler = ref.watch(audioHandlerProvider);

    final tracks = _searchQuery.isEmpty
        ? allTracks
        : allTracks
            .where((t) =>
                t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                t.artist.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return libraryAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.yellowVivid),
      ),
      error: (e, _) => Center(child: Text('Erreur : $e')),
      data: (_) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: AppColors.cream),
              decoration: InputDecoration(
                hintText: 'Rechercher une musique...',
                hintStyle: TextStyle(color: AppColors.cream.withValues(alpha: 0.5)),
                prefixIcon: const Icon(Icons.search, color: AppColors.yellowVivid),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.cream),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.backgroundSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.yellowVivid, width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
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
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
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
                                MiloArtworkWidget(id: track.id, size: 48),
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
          ),
        ],
      ),
    );
  }
}
