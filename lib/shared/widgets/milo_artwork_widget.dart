import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:milo/core/theme/app_colors.dart';

class MiloArtworkWidget extends StatelessWidget {
  const MiloArtworkWidget({
    super.key,
    required this.id,
    this.size = 48,
    this.borderRadius = 12,
  });

  final String id;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    int? parsedId;
    if (!id.startsWith('demo_')) {
      parsedId = int.tryParse(id);
    }

    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.yellowVivid,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.border,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: AppColors.backgroundDeep,
        size: size * 0.5,
      ),
    );

    if (parsedId == null) {
      return fallback;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.border,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 2),
        child: QueryArtworkWidget(
          id: parsedId,
          type: ArtworkType.AUDIO,
          format: ArtworkFormat.JPEG,
          keepOldArtwork: true,
          artworkFit: BoxFit.cover,
          artworkBorder: BorderRadius.zero,
          nullArtworkWidget: fallback,
        ),
      ),
    );
  }
}
