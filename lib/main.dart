import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/app.dart';
import 'package:milo/core/audio/audio_handler.dart';
import 'package:milo/core/providers/audio_providers.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  MiloAudioHandler? handler;
  try {
    // Session audio pour lecture arrière-plan
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Initialisation du handler audio avec notification persistante
    handler = await initAudioService();
  } catch (e) {
    debugPrint('Erreur init audio: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        if (handler != null) audioHandlerProvider.overrideWithValue(handler),
      ],
      child: handler == null 
          ? const MaterialApp(home: Scaffold(body: Center(child: Text('Erreur init audio_service')))) 
          : const MiloApp(),
    ),
  );
  
  FlutterNativeSplash.remove();
}
