import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:milo/features/playlists/models/playlist_model.dart';

class PlaylistRepository {
  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/milo_playlists.json');
  }

  Future<List<PlaylistModel>> loadPlaylists() async {
    try {
      final file = await _file;
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((e) => PlaylistModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePlaylists(List<PlaylistModel> playlists) async {
    final file = await _file;
    final jsonList = playlists.map((p) => p.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }
}
