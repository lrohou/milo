import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/app.dart';
import 'package:milo/core/audio/audio_handler.dart';
import 'package:milo/core/providers/audio_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Session audio pour lecture arrière-plan
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  // Initialisation du handler audio avec notification persistante
  final handler = await initAudioService();

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(handler),
      ],
      child: const MiloApp(),
    ),
  );
}
