import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/features/home/presentation/widgets/mood_selector_widget.dart';
import 'package:milo/features/player/presentation/widgets/milo_equalizer_widget.dart';
import 'package:milo/features/playlists/models/playlist_model.dart';
import 'package:milo/features/playlists/presentation/playlist_detail_screen.dart';
import 'package:milo/features/playlists/providers/playlist_providers.dart';
import 'package:milo/shared/widgets/glass_card.dart';
import 'package:milo/shared/widgets/neo_brutal_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 160),
        children: [
          // Humeurs
          const MoodSelectorWidget(),
          const SizedBox(height: 32),

          // Égaliseur
          Text(
            'Égaliseur',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          const MiloEqualizerWidget(),
          const SizedBox(height: 32),

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
                onPressed: () => _showCreatePlaylistDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Liste des Playlists
          playlistsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.yellowVivid),
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
                children: playlists.map((p) => _PlaylistCard(playlist: p)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundSurface,
        title: const Text('Nouvelle Playlist', style: TextStyle(color: AppColors.cream)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.cream),
              decoration: const InputDecoration(labelText: 'Nom', labelStyle: TextStyle(color: AppColors.cream)),
            ),
            TextField(
              controller: descController,
              style: const TextStyle(color: AppColors.cream),
              decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: AppColors.cream)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler', style: TextStyle(color: AppColors.cream)),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref.read(playlistsProvider.notifier).addPlaylist(nameController.text, descController.text);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Créer', style: TextStyle(color: AppColors.yellowVivid)),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistDetailScreen(playlist: playlist),
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
              child: const Icon(Icons.queue_music_rounded, color: AppColors.backgroundDeep),
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
              icon: const Icon(Icons.delete_rounded, color: AppColors.error),
              onPressed: () {
                ref.read(playlistsProvider.notifier).deletePlaylist(playlist.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
