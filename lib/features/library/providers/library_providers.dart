import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/features/library/data/library_repository.dart';
import 'package:milo/shared/models/track_model.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => LibraryRepository(),
);

/// Bibliothèque locale scannée.
final libraryProvider = FutureProvider<List<TrackModel>>((ref) async {
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.scanLocalLibrary();
});

/// Morceaux filtrés (Météo Intérieure, Pâture Zen, etc.)
final filteredTracksProvider =
    StateProvider<List<TrackModel>?>((ref) => null);

final effectiveLibraryProvider = Provider<List<TrackModel>>((ref) {
  final library = ref.watch(libraryProvider).valueOrNull ?? [];
  final filtered = ref.watch(filteredTracksProvider);
  return filtered ?? library;
});
