import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/core/providers/audio_providers.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/features/library/providers/library_providers.dart';

class MoodSelectorWidget extends ConsumerWidget {
  const MoodSelectorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Humeur',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _MoodIcon(
              emoji: '☀️',
              label: 'Joyeux',
              onTap: () => _playMood(ref, context, 'Joyeux'),
            ),
            _MoodIcon(
              emoji: '🧘',
              label: 'Calme',
              onTap: () => _playMood(ref, context, 'Calme'),
            ),
            _MoodIcon(
              emoji: '⚡',
              label: 'Énergique',
              onTap: () => _playMood(ref, context, 'Énergique'),
            ),
            _MoodIcon(
              emoji: '🌧️',
              label: 'Mélanco',
              onTap: () => _playMood(ref, context, 'Mélancolique'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _playMood(WidgetRef ref, BuildContext context, String mood) async {
    HapticFeedback.selectionClick();
    final allTracks = ref.read(effectiveLibraryProvider);
    if (allTracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bibliothèque vide !')),
      );
      return;
    }

    List<dynamic> filtered = [];
    switch (mood) {
      case 'Joyeux':
        filtered = allTracks.where((t) => t.effectiveBpm >= 100 && (t.genre?.contains('Pop') ?? false)).toList();
        if (filtered.isEmpty) filtered = allTracks.where((t) => t.effectiveBpm >= 100).toList();
        break;
      case 'Calme':
        filtered = allTracks.where((t) => t.effectiveBpm <= 90).toList();
        break;
      case 'Énergique':
        filtered = allTracks.where((t) => t.effectiveBpm >= 130).toList();
        break;
      case 'Mélancolique':
        filtered = allTracks.where((t) => t.effectiveBpm <= 100 && ((t.genre?.contains('Ambient') ?? false) || (t.genre?.contains('Jazz') ?? false))).toList();
        if (filtered.isEmpty) filtered = allTracks.where((t) => t.effectiveBpm <= 100).toList();
        break;
    }

    if (filtered.isEmpty) {
      filtered = List.from(allTracks); // Fallback
    }

    filtered.shuffle();
    final handler = ref.read(audioHandlerProvider);
    await handler.loadQueue(filtered.cast());
    await handler.play();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lecture : $mood (${filtered.length} titres)')),
      );
    }
  }
}

class _MoodIcon extends StatelessWidget {
  const _MoodIcon({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.backgroundSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
