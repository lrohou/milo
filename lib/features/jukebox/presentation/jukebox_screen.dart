import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/core/providers/audio_providers.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/features/jukebox/services/jukebox_server.dart';
import 'package:milo/features/library/providers/library_providers.dart';
import 'package:milo/shared/widgets/glass_card.dart';
import 'package:milo/shared/widgets/neo_brutal_button.dart';
import 'package:milo/shared/widgets/neo_brutal_container.dart';

final jukeboxServerProvider = Provider<JukeboxServer>((ref) {
  final server = JukeboxServer();
  ref.onDispose(() => server.stop());
  return server;
});

/// UI « Charette Jukebox » — serveur local multijoueur avec votes live.
class JukeboxScreen extends ConsumerStatefulWidget {
  const JukeboxScreen({super.key});

  @override
  ConsumerState<JukeboxScreen> createState() => _JukeboxScreenState();
}

class _JukeboxScreenState extends ConsumerState<JukeboxScreen> {
  bool _hosting = false;
  Timer? _pollTimer;
  Map<String, int> _votes = {};
  String? _winnerTrackId;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final server = ref.watch(jukeboxServerProvider);
    final library = ref.watch(effectiveLibraryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Charette Jukebox')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              child: Column(
                children: [
                  const Text('🛒', style: TextStyle(fontSize: 48))
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(begin: -4, end: 4, duration: 1200.ms),
                  const SizedBox(height: 12),
                  Text(
                    'Multijoueur Local',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Les amis sur le même Wi-Fi votent\npour le prochain morceau',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  // — URL du serveur
                  if (_hosting && server.localUrl != null) ...[
                    const SizedBox(height: 20),
                    NeoBrutalContainer(
                      backgroundColor: AppColors.yellowVivid,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Serveur actif',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.backgroundDeep,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            server.localUrl!,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: AppColors.backgroundDeep,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ouvre cette URL sur un autre appareil',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.backgroundDeep
                                      .withValues(alpha: 0.7),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // — Votes en temps réel
            if (_hosting && _votes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Votes en direct',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: _votes.entries.map((entry) {
                    final track = library
                        .where((t) => t.id == entry.key)
                        .firstOrNull;
                    final isWinner = entry.key == _winnerTrackId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            // Icône de vote
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isWinner
                                    ? AppColors.yellowVivid
                                    : AppColors.backgroundSurface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${entry.value}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: isWinner
                                          ? AppColors.backgroundDeep
                                          : AppColors.cream,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track?.title ?? 'Morceau inconnu',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: isWinner
                                              ? AppColors.yellowVivid
                                              : AppColors.cream,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (track != null)
                                    Text(
                                      track.artist,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                ],
                              ),
                            ),
                            if (isWinner)
                              const Icon(Icons.emoji_events_rounded,
                                      color: AppColors.yellowVivid, size: 28)
                                  .animate(onPlay: (c) => c.repeat())
                                  .scale(
                                    begin: const Offset(1, 1),
                                    end: const Offset(1.2, 1.2),
                                    duration: 500.ms,
                                  ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // — Bouton jouer le gagnant
              NeoBrutalButton(
                label: 'Jouer le gagnant',
                icon: Icons.play_arrow_rounded,
                expanded: true,
                backgroundColor: AppColors.yellowGold,
                onPressed: _winnerTrackId != null
                    ? () => _playWinner(server)
                    : null,
              ),
              const SizedBox(height: 12),
            ] else if (_hosting) ...[
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.how_to_vote_rounded,
                        color: AppColors.cream, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'En attente de votes…',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ] else
              const Spacer(),

            NeoBrutalButton(
              label: _hosting ? 'Arrêter le serveur' : 'Héberger la Charette',
              icon: Icons.wifi_tethering_rounded,
              expanded: true,
              onPressed: () => _toggleHost(server),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleHost(JukeboxServer server) async {
    HapticFeedback.mediumImpact();
    if (_hosting) {
      _pollTimer?.cancel();
      await server.stop();
      setState(() {
        _hosting = false;
        _votes = {};
        _winnerTrackId = null;
      });
    } else {
      final library = ref.read(effectiveLibraryProvider);
      await server.start(library);
      _startPolling(server);
      setState(() => _hosting = true);
    }
  }

  void _startPolling(JukeboxServer server) {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !server.isRunning) return;
      final winning = server.getWinningTrack();
      setState(() {
        _votes = {};
        // Reconstruct votes from server
        for (final track in ref.read(effectiveLibraryProvider)) {
          final count = server.getVoteCount(track.id);
          if (count > 0) _votes[track.id] = count;
        }
        _winnerTrackId = winning?.id;
      });
    });
  }

  Future<void> _playWinner(JukeboxServer server) async {
    HapticFeedback.heavyImpact();
    final winning = server.getWinningTrack();
    if (winning != null) {
      final handler = ref.read(audioHandlerProvider);
      final library = ref.read(effectiveLibraryProvider);
      final index = library.indexWhere((t) => t.id == winning.id);
      if (index >= 0) {
        await handler.loadQueue(library, startIndex: index);
        await handler.play();
      }
    }
  }
}
