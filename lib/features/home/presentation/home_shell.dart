import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/features/cargo/presentation/cargo_screen.dart';
import 'package:milo/features/jukebox/presentation/jukebox_screen.dart';
import 'package:milo/features/library/presentation/library_screen.dart';
import 'package:milo/features/library/providers/library_providers.dart';
import 'package:milo/features/pasture_zen/presentation/pasture_zen_screen.dart';
import 'package:milo/features/player/presentation/screens/now_playing_screen.dart';
import 'package:milo/features/wake_kick/presentation/wake_kick_screen.dart';
import 'package:milo/core/providers/audio_providers.dart';
import 'package:milo/shared/widgets/glass_card.dart';

/// Coquille de navigation principale Milo.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _tabs = [
    (icon: Icons.play_circle_filled_rounded, label: 'Lecture'),
    (icon: Icons.library_music_rounded, label: 'Bibliothèque'),
    (icon: Icons.grass_rounded, label: 'Pâture'),
    (icon: Icons.explore_rounded, label: 'Modes'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final library = await ref.read(libraryProvider.future);
    if (library.isNotEmpty && mounted) {
      final handler = ref.read(audioHandlerProvider);
      await handler.loadQueue(library);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: [
            const NowPlayingScreen(),
            const LibraryScreen(),
            const PastureZenScreen(),
            _ModesHub(onNavigate: (screen) {
              Navigator.of(context).push(
                PageRouteBuilder<void>(
                  pageBuilder: (ctx, anim, anim2) => screen,
                  transitionsBuilder: (ctx, anim, anim2, child) {
                    return SlideTransition(
                      position: Tween(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: anim,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 3)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) {
            HapticFeedback.selectionClick();
            setState(() => _index = i);
          },
          items: _tabs
              .map(
                (t) => BottomNavigationBarItem(
                  icon: Icon(t.icon),
                  label: t.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _ModesHub extends StatelessWidget {
  const _ModesHub({required this.onNavigate});

  final void Function(Widget screen) onNavigate;

  @override
  Widget build(BuildContext context) {
    final modes = [
      (
        'Cargo — Partage P2P',
        Icons.backpack_rounded,
        const CargoScreen(),
        'Bluetooth / Wi-Fi Direct',
      ),
      (
        'Charette Jukebox',
        Icons.wifi_rounded,
        const JukeboxScreen(),
        'Multijoueur local',
      ),
      (
        'Ruade — Alarme',
        Icons.alarm_rounded,
        const WakeKickScreen(),
        'Réveil intelligent',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
      children: [
        Text('Modes Milo', style: Theme.of(context).textTheme.displayMedium)
            .animate()
            .fadeIn(duration: 400.ms)
            .moveY(begin: -10, end: 0),
        const SizedBox(height: 8),
        Text(
          'Fonctionnalités avancées hors-ligne',
          style: Theme.of(context).textTheme.bodyLarge,
        )
            .animate()
            .fadeIn(delay: 100.ms, duration: 400.ms),
        const SizedBox(height: 32),
        ...List.generate(
          modes.length,
          (i) {
            final m = modes[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                onTap: () => onNavigate(m.$3),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.yellowVivid,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.border,
                          width: 2.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.yellowGold,
                            offset: Offset(3, 3),
                          ),
                        ],
                      ),
                      child: Icon(m.$2,
                          color: AppColors.backgroundDeep, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.$1,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m.$4,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color:
                                        AppColors.cream.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: AppColors.cream),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 200 + i * 100))
                  .moveX(begin: 30, end: 0),
            );
          },
        ),
      ],
    );
  }
}
