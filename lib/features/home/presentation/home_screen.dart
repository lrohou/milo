import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/core/providers/audio_providers.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/features/dab_radio/models/dab_radio_station.dart';
import 'package:milo/features/dab_radio/presentation/dab_radio_screen.dart';
import 'package:milo/features/dab_radio/providers/radio_stats_provider.dart';
import 'package:milo/features/home/presentation/widgets/mood_selector_widget.dart';
import 'package:milo/features/library/presentation/library_screen.dart';
import 'package:milo/features/likes/providers/likes_provider.dart';
import 'package:milo/features/library/providers/library_providers.dart';
import 'package:milo/features/player/presentation/widgets/milo_equalizer_widget.dart';
import 'package:milo/features/playlists/models/playlist_model.dart';
import 'package:milo/features/playlists/presentation/playlist_detail_screen.dart';
import 'package:milo/features/playlists/providers/playlist_providers.dart';
import 'package:milo/features/stats/providers/stats_provider.dart';
import 'package:milo/shared/widgets/glass_card.dart';
import 'package:milo/shared/widgets/milo_artwork_widget.dart';
import 'package:milo/shared/widgets/neo_brutal_button.dart';
import 'package:milo/features/settings/presentation/account_settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);
    final stats = ref.watch(statsProvider);
    final libraryAsync = ref.watch(libraryProvider);
    final likedIds = ref.watch(likesProvider);
    final handler = ref.watch(audioHandlerProvider);
    final radioStats = ref.watch(radioStatsProvider);
    final savedRadios = ref.watch(openDabStationsProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 160),
        children: [
          // En-tête Accueil
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bonjour !',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              Row(
                children: [
                  // Bouton popup Égaliseur "Oreilles d'Âne"
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.equalizer_rounded,
                          color: AppColors.yellowVivid),
                      tooltip: 'Égaliseur DJ',
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _showEqualizerPopup(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.person_rounded,
                          color: AppColors.yellowVivid),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const AccountSettingsScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ─── Musiques du moment (basé sur les stats) ──────────────
          if (stats.isNotEmpty)
            libraryAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _a) => const SizedBox.shrink(),
              data: (library) {
                final sorted = stats.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final topIds = sorted.take(6).map((e) => e.key).toList();
                final topTracks = topIds
                    .map((id) {
                      try {
                        return library.firstWhere((t) => t.id == id);
                      } catch (_) {
                        return null;
                      }
                    })
                    .where((t) => t != null)
                    .toList();

                if (topTracks.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Musiques du moment',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LibraryScreen()),
                            );
                          },
                          child: const Text(
                            'Voir plus',
                            style: TextStyle(color: AppColors.yellowVivid),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 150,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: topTracks.length,
                        separatorBuilder: (_, _a) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final track = topTracks[i]!;
                          return GestureDetector(
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              await handler.loadQueue(library,
                                  startIndex: library.indexOf(track));
                              await handler.play();
                            },
                            child: SizedBox(
                              width: 110,
                              child: Column(
                                children: [
                                  MiloArtworkWidget(
                                      id: track.id,
                                      size: 100,
                                      borderRadius: 16),
                                  const SizedBox(height: 8),
                                  Text(
                                    track.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    '${stats[track.id]}x',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.yellowGold),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),

          // ─── Radios DAB+ les plus écoutées ─────────────────────────
          if (radioStats.isNotEmpty && savedRadios.isNotEmpty)
            _buildTopRadiosSection(context, ref, radioStats, savedRadios, handler),

          // Humeurs
          const MoodSelectorWidget(),
          const SizedBox(height: 32),

          // ─── Coups de cœur ─────────────────────────────────────────
          if (likedIds.isNotEmpty)
            libraryAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _a) => const SizedBox.shrink(),
              data: (library) {
                final likedTracks = library
                    .where((t) => likedIds.contains(t.id))
                    .toList();
                if (likedTracks.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.favorite_rounded,
                                color: AppColors.error, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Coups de cœur',
                              style:
                                  Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LibraryScreen()),
                            );
                          },
                          child: const Text(
                            'Voir plus',
                            style: TextStyle(color: AppColors.yellowVivid),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...likedTracks.take(5).map((track) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              await handler.loadQueue(likedTracks,
                                  startIndex:
                                      likedTracks.indexOf(track));
                              await handler.play();
                            },
                            child: Row(
                              children: [
                                MiloArtworkWidget(
                                    id: track.id, size: 40),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        track.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        track.artist,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),

          // En-tête Playlists
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Playlists',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              NeoBrutalButton(
                label: 'Nouvelle',
                icon: Icons.add_rounded,
                onPressed: () =>
                    _showCreatePlaylistDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Liste des Playlists
          playlistsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                  color: AppColors.yellowVivid),
            ),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (playlists) {
              if (playlists.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('Aucune playlist créée.'),
                  ),
                );
              }
              return Column(
                children: playlists
                    .map((p) => _PlaylistCard(playlist: p))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEqualizerPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Égaliseur — Oreilles d\'Âne',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.cream,
                    ),
              ),
              const SizedBox(height: 24),
              const MiloEqualizerWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRadiosSection(
    BuildContext context,
    WidgetRef ref,
    Map<String, int> radioStats,
    List<DabRadioStation> savedRadios,
    dynamic handler,
  ) {
    final sorted = radioStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topIds = sorted.take(6).map((e) => e.key).toList();
    final topStations = topIds
        .map((id) {
          try {
            return savedRadios.firstWhere((s) => s.id == id);
          } catch (_) {
            // Chercher dans les stations par défaut
            try {
              return kDabRadioStations.firstWhere((s) => s.id == id);
            } catch (_) {
              return null;
            }
          }
        })
        .where((s) => s != null)
        .toList();

    if (topStations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('📻', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  'Radios favorites',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OpenDabScreen()),
                );
              },
              child: const Text(
                'Voir plus',
                style: TextStyle(color: AppColors.yellowVivid),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: topStations.length,
            separatorBuilder: (_, _a) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final station = topStations[i]!;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  handler.playRadioStation(station, savedRadios.isNotEmpty ? savedRadios : [station]);
                },
                child: SizedBox(
                  width: 90,
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.border, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          station.logoEmoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        station.name,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '${radioStats[station.id]}x',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.yellowGold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundSurface,
        title: const Text('Nouvelle Playlist',
            style: TextStyle(color: AppColors.cream)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.cream),
              decoration: const InputDecoration(
                  labelText: 'Nom',
                  labelStyle: TextStyle(color: AppColors.cream)),
            ),
            TextField(
              controller: descController,
              style: const TextStyle(color: AppColors.cream),
              decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: AppColors.cream)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.cream)),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref.read(playlistsProvider.notifier).addPlaylist(
                    nameController.text, descController.text);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Créer',
                style: TextStyle(color: AppColors.yellowVivid)),
          ),
        ],
      ),
    );
  }
}

class _PlaylistCard extends ConsumerWidget {
  const _PlaylistCard({required this.playlist});

  final PlaylistModel playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PlaylistDetailScreen(playlist: playlist),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.yellowVivid,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: const Icon(Icons.queue_music_rounded,
                  color: AppColors.backgroundDeep),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${playlist.trackIds.length} morceaux',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded,
                  color: AppColors.error),
              onPressed: () {
                ref
                    .read(playlistsProvider.notifier)
                    .deletePlaylist(playlist.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
