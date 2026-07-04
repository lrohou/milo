import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/core/providers/audio_providers.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/features/library/providers/library_providers.dart';
import 'package:milo/features/playlists/models/playlist_model.dart';
import 'package:milo/features/playlists/providers/playlist_providers.dart';
import 'package:milo/shared/widgets/milo_artwork_widget.dart';
import 'package:milo/shared/widgets/neo_brutal_button.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  const PlaylistDetailScreen({super.key, required this.playlist});

  final PlaylistModel playlist;

  @override
  ConsumerState<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final playlists = ref.watch(playlistsProvider).valueOrNull ?? [];
    final currentPlaylist = playlists.firstWhere(
      (p) => p.id == widget.playlist.id,
      orElse: () => widget.playlist,
    );

    final library = ref.watch(effectiveLibraryProvider);
    final playlistTracks = library.where((t) => currentPlaylist.trackIds.contains(t.id)).toList();
    
    final searchResults = _searchQuery.isEmpty 
        ? [] 
        : library.where((t) => 
            !currentPlaylist.trackIds.contains(t.id) &&
            (t.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
             t.artist.toLowerCase().contains(_searchQuery.toLowerCase()))
          ).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(currentPlaylist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            onPressed: () {
              ref.read(playlistsProvider.notifier).deletePlaylist(currentPlaylist.id);
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (playlistTracks.isNotEmpty)
            NeoBrutalButton(
              label: 'Jouer la Playlist',
              icon: Icons.play_arrow_rounded,
              backgroundColor: AppColors.yellowVivid,
              foregroundColor: AppColors.backgroundDeep,
              onPressed: () async {
                HapticFeedback.heavyImpact();
                final handler = ref.read(audioHandlerProvider);
                await handler.loadQueue(playlistTracks);
                await handler.play();
              },
            ),
          const SizedBox(height: 24),
          Text(
            'Titres (${playlistTracks.length})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (playlistTracks.isEmpty)
            const Text('Aucune musique dans cette playlist.')
          else
            ...playlistTracks.map((track) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: MiloArtworkWidget(id: track.id, size: 48),
              title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                onPressed: () {
                  ref.read(playlistsProvider.notifier).removeTrackFromPlaylist(currentPlaylist.id, track.id);
                },
              ),
            )),

          const SizedBox(height: 32),
          Text(
            'Ajouter des musiques',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            style: const TextStyle(color: AppColors.cream),
            decoration: InputDecoration(
              hintText: 'Rechercher une musique...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: AppColors.cream),
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
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 16),
          if (_searchQuery.isNotEmpty) ...[
            if (searchResults.isEmpty)
              const Text('Aucun résultat trouvé.')
            else
              ...searchResults.map((track) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: MiloArtworkWidget(id: track.id, size: 48),
                title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.yellowVivid),
                  onPressed: () {
                    ref.read(playlistsProvider.notifier).addTrackToPlaylist(currentPlaylist.id, track.id);
                  },
                ),
              )),
          ],
        ],
      ),
    );
  }
}
