import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/core/providers/audio_providers.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/features/library/providers/library_providers.dart';
import 'package:milo/shared/models/track_model.dart';
import 'package:milo/shared/widgets/glass_card.dart';
import 'package:milo/shared/widgets/milo_artwork_widget.dart';

enum LibrarySortMode { all, byArtist, byGenre }

/// Bibliothèque locale — liste des morceaux scannés avec recherche et tri.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  LibrarySortMode _sortMode = LibrarySortMode.all;

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
                t.artist.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (t.genre ?? '')
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()))
            .toList();

    return libraryAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.yellowVivid),
      ),
      error: (e, _) => Center(child: Text('Erreur : $e')),
      data: (_) => Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: AppColors.cream),
              decoration: InputDecoration(
                hintText: 'Rechercher une musique...',
                hintStyle:
                    TextStyle(color: AppColors.cream.withValues(alpha: 0.5)),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.yellowVivid),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon:
                            const Icon(Icons.clear, color: AppColors.cream),
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
                  borderSide:
                      const BorderSide(color: AppColors.border, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.border, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.yellowVivid, width: 2),
                ),
              ),
            ),
          ),

          // Chips de tri
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                _SortChip(
                  label: 'Tout',
                  selected: _sortMode == LibrarySortMode.all,
                  onTap: () =>
                      setState(() => _sortMode = LibrarySortMode.all),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Artiste',
                  selected: _sortMode == LibrarySortMode.byArtist,
                  onTap: () =>
                      setState(() => _sortMode = LibrarySortMode.byArtist),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Style',
                  selected: _sortMode == LibrarySortMode.byGenre,
                  onTap: () =>
                      setState(() => _sortMode = LibrarySortMode.byGenre),
                ),
              ],
            ),
          ),

          // Liste
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
                  : _buildList(context, tracks, handler),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
      BuildContext context, List<TrackModel> tracks, dynamic handler) {
    if (_sortMode == LibrarySortMode.all) {
      return _buildFlatList(context, tracks, handler);
    }

    // Group tracks
    final Map<String, List<TrackModel>> groups = {};
    for (final track in tracks) {
      final key = _sortMode == LibrarySortMode.byArtist
          ? track.artist
          : (track.genre ?? 'Inconnu');
      groups.putIfAbsent(key, () => []).add(track);
    }
    final sortedKeys = groups.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      itemCount: sortedKeys.length,
      itemBuilder: (context, sectionIndex) {
        final key = sortedKeys[sectionIndex];
        final sectionTracks = groups[key]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                key,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.yellowVivid,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ...sectionTracks.map((track) {
              final globalIndex = tracks.indexOf(track);
              return _TrackTile(
                track: track,
                onTap: () async {
                  HapticFeedback.selectionClick();
                  await handler.loadQueue(tracks, startIndex: globalIndex);
                  await handler.play();
                },
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildFlatList(
      BuildContext context, List<TrackModel> tracks, dynamic handler) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return _TrackTile(
          track: track,
          onTap: () async {
            HapticFeedback.selectionClick();
            await handler.loadQueue(tracks, startIndex: index);
            await handler.play();
          },
        );
      },
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({required this.track, required this.onTap});
  final TrackModel track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        onTap: onTap,
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
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${track.artist} · ${track.effectiveBpm} BPM',
                    style: Theme.of(context).textTheme.bodyMedium,
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
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.yellowVivid : AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.yellowGold : AppColors.border,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.backgroundDeep : AppColors.cream,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
