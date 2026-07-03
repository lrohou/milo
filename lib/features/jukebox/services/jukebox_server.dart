import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:milo/shared/models/track_model.dart';

/// Vote d'un participant à la Charette Jukebox.
class JukeboxVote {
  const JukeboxVote({required this.trackId, required this.voterName});

  final String trackId;
  final String voterName;
}

/// Serveur local léger (shelf) — file d'attente collaborative sur Wi-Fi.
class JukeboxServer {
  JukeboxServer({this.port = 8080});

  final int port;
  HttpServer? _server;
  final List<JukeboxVote> _votes = [];
  List<TrackModel> _queue = [];

  bool get isRunning => _server != null;
  String? get localUrl => _server != null ? 'http://0.0.0.0:$port' : null;

  Future<void> start(List<TrackModel> initialQueue) async {
    _queue = List.from(initialQueue);
    final router = Router()
      ..get('/', _homePage)
      ..get('/api/queue', _getQueue)
      ..get('/api/votes', _getVotes)
      ..post('/api/vote', _postVote);

    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router.call);

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  }

  Response _homePage(Request request) {
    return Response.ok(
      _htmlPage(),
      headers: {'Content-Type': 'text/html; charset=utf-8'},
    );
  }

  Response _getQueue(Request request) {
    return Response.ok(
      jsonEncode(_queue.map((t) => {'id': t.id, 'title': t.title, 'artist': t.artist}).toList()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Response _getVotes(Request request) {
    final tally = <String, int>{};
    for (final v in _votes) {
      tally[v.trackId] = (tally[v.trackId] ?? 0) + 1;
    }
    return Response.ok(jsonEncode(tally), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _postVote(Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    _votes.add(JukeboxVote(
      trackId: data['trackId'] as String,
      voterName: data['voterName'] as String? ?? 'Anonyme',
    ));
    return Response.ok('{"ok":true}');
  }

  /// Morceau le plus voté dans la file.
  TrackModel? getWinningTrack() {
    if (_queue.isEmpty) return null;
    final tally = <String, int>{};
    for (final v in _votes) {
      tally[v.trackId] = (tally[v.trackId] ?? 0) + 1;
    }
    if (tally.isEmpty) return _queue.first;

    final winnerId = tally.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return _queue.cast<TrackModel?>().firstWhere(
          (t) => t!.id == winnerId,
          orElse: () => _queue.first,
        );
  }

  /// Nombre de votes pour un trackId donné.
  int getVoteCount(String trackId) {
    return _votes.where((v) => v.trackId == trackId).length;
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _votes.clear();
  }

  String _htmlPage() => '''
<!DOCTYPE html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Milo — Charette Jukebox</title>
<style>
  body{font-family:system-ui;background:#111;color:#FFFED5;padding:24px}
  h1{color:#FEE402} .track{padding:16px;margin:8px 0;background:#1C1C1C;border:3px solid #111;border-radius:12px}
  button{background:#FEE402;color:#111;border:3px solid #111;padding:12px 24px;font-weight:bold;border-radius:8px;cursor:pointer}
</style></head><body>
<h1>🫏 Charette Jukebox</h1>
<p>Vote pour le prochain morceau !</p>
<div id="queue"></div>
<script>
fetch('/api/queue').then(r=>r.json()).then(tracks=>{
  document.getElementById('queue').innerHTML=tracks.map(t=>
    '<div class="track"><strong>'+t.title+'</strong><br>'+t.artist+
    '<br><button onclick="vote(\\''+t.id+'\\')">Voter</button></div>'
  ).join('');
});
function vote(id){fetch('/api/vote',{method:'POST',headers:{'Content-Type':'application/json'},
  body:JSON.stringify({trackId:id,voterName:prompt('Ton prénom')||'Anonyme'})}).then(()=>alert('Vote enregistré !'));}
</script></body></html>''';
}
