import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/app.dart';
import 'package:milo/core/audio/audio_handler.dart';
import 'package:milo/core/providers/audio_providers.dart';
import 'package:milo/core/widget/milo_widget_service.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  MiloAudioHandler? handler;
  String? initError;
  try {
    // Demander les permissions critiques AVANT d'initialiser les services
    await Permission.notification.request();
    await Permission.audio.request();
    await Permission.storage.request();

    // Session audio pour lecture arrière-plan
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Initialisation du handler audio avec notification persistante
    handler = await initAudioService();
  } catch (e, st) {
    initError = '$e\n$st';
    debugPrint('Erreur init audio: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        if (handler != null) audioHandlerProvider.overrideWithValue(handler),
      ],
      child: handler == null 
          ? MaterialApp(
              home: Scaffold(
                backgroundColor: const Color(0xFF111111),
                body: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Erreur critique (audio_service) :\n\n$initError',
                      style: const TextStyle(color: Color(0xFFFEE402), fontSize: 14),
                    ),
                  ),
                ),
              ),
            ) 
          : const MiloApp(),
    ),
  );
  
  FlutterNativeSplash.remove();
}
