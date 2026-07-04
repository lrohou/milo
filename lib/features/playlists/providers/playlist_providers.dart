import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/features/playlists/data/playlist_repository.dart';
import 'package:milo/features/playlists/models/playlist_model.dart';
import 'package:uuid/uuid.dart';

final playlistRepositoryProvider = Provider((ref) => PlaylistRepository());

class PlaylistNotifier extends StateNotifier<AsyncValue<List<PlaylistModel>>> {
  PlaylistNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  final PlaylistRepository _repo;

  Future<void> _load() async {
    try {
      final playlists = await _repo.loadPlaylists();
      state = AsyncValue.data(playlists);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addPlaylist(String name, String description) async {
    final current = state.valueOrNull ?? [];
    final newPlaylist = PlaylistModel(
      id: const Uuid().v4(),
      name: name,
      description: description,
    );
    final updated = [...current, newPlaylist];
    state = AsyncValue.data(updated);
    await _repo.savePlaylists(updated);
  }

  Future<void> updatePlaylist(PlaylistModel playlist) async {
    final current = state.valueOrNull ?? [];
    final updated = current.map((p) => p.id == playlist.id ? playlist : p).toList();
    state = AsyncValue.data(updated);
    await _repo.savePlaylists(updated);
  }

  Future<void> deletePlaylist(String id) async {
    final current = state.valueOrNull ?? [];
    final updated = current.where((p) => p.id != id).toList();
    state = AsyncValue.data(updated);
    await _repo.savePlaylists(updated);
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackId) async {
    final current = state.valueOrNull ?? [];
    final updated = current.map((p) {
      if (p.id == playlistId && !p.trackIds.contains(trackId)) {
        return p.copyWith(trackIds: [...p.trackIds, trackId]);
      }
      return p;
    }).toList();
    state = AsyncValue.data(updated);
    await _repo.savePlaylists(updated);
  }
}

final playlistsProvider = StateNotifierProvider<PlaylistNotifier, AsyncValue<List<PlaylistModel>>>((ref) {
  return PlaylistNotifier(ref.watch(playlistRepositoryProvider));
});
