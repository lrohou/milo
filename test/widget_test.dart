
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milo/app.dart';
import 'package:milo/core/audio/audio_handler.dart';
import 'package:milo/core/providers/audio_providers.dart';

void main() {
  testWidgets('Milo app smoke test', (tester) async {
    final handler = MiloAudioHandler();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioHandlerProvider.overrideWithValue(handler),
        ],
        child: const MiloApp(),
      ),
    );

    expect(find.text('Lecture'), findsOneWidget);
    expect(find.text('Bibliothèque'), findsOneWidget);
  });
}
