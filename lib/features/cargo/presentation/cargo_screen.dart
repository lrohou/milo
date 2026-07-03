import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/features/cargo/services/cargo_p2p_service.dart';
import 'package:milo/features/library/providers/library_providers.dart';
import 'package:milo/shared/models/track_model.dart';
import 'package:milo/shared/widgets/glass_card.dart';
import 'package:milo/shared/widgets/neo_brutal_button.dart';

final cargoServiceProvider = Provider<CargoP2pService>((ref) {
  final service = CargoP2pService();
  ref.onDispose(service.dispose);
  return service;
});

/// UI « Cargo » — radar P2P animé et transfert offline.
class CargoScreen extends ConsumerStatefulWidget {
  const CargoScreen({super.key});

  @override
  ConsumerState<CargoScreen> createState() => _CargoScreenState();
}

class _CargoScreenState extends ConsumerState<CargoScreen>
    with SingleTickerProviderStateMixin {
  bool _scanning = false;
  List<String> _peers = [];
  TrackModel? _selectedTrack;
  late final AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cargo')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GlassCard(
              child: Column(
                children: [
                  Text(
                    'Glisser dans la sacoche',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Partage P2P Bluetooth / Wi-Fi Direct',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // — Radar animé
                  SizedBox(
                    height: 220,
                    child: AnimatedBuilder(
                      animation: _radarController,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _RadarPainter(
                            active: _scanning,
                            sweepAngle: _radarController.value * 2 * math.pi,
                            peers: _peers,
                          ),
                          size: Size.infinite,
                        );
                      },
                    ),
                  ),

                  // — Liste des pairs
                  if (_peers.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.glassBorder),
                    const SizedBox(height: 8),
                    ..._peers.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.yellowVivid.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.person_pin_circle_rounded,
                                  color: AppColors.yellowVivid, size: 24),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge),
                                    Text('Milo à proximité',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                  ],
                                ),
                              ),
                              NeoBrutalButton(
                                label: 'Envoyer',
                                icon: Icons.send_rounded,
                                onPressed: _selectedTrack != null
                                    ? () => _sendTrack(p)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 300.ms).moveX(begin: 20),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // — Sélection du morceau à partager
            GlassCard(
              padding: const EdgeInsets.all(16),
              onTap: () => _showTrackPicker(context),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.yellowVivid,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: const Icon(Icons.music_note_rounded,
                        color: AppColors.backgroundDeep),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _selectedTrack != null
                          ? '${_selectedTrack!.title} — ${_selectedTrack!.artist}'
                          : 'Choisir un morceau à partager',
                      style: Theme.of(context).textTheme.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down_rounded,
                      color: AppColors.cream),
                ],
              ),
            ),

            const Spacer(),

            NeoBrutalButton(
              label: _scanning ? 'Radar actif…' : 'Lancer le radar',
              icon:
                  _scanning ? Icons.radar_rounded : Icons.play_arrow_rounded,
              expanded: true,
              onPressed: _toggleRadar,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleRadar() async {
    HapticFeedback.mediumImpact();
    final service = ref.read(cargoServiceProvider);
    if (_scanning) {
      await service.stop();
      _radarController.stop();
      setState(() {
        _scanning = false;
        _peers = [];
      });
    } else {
      await service.startRadar();
      _radarController.repeat();
      service.peersStream.listen((peers) {
        if (mounted) setState(() => _peers = peers);
      });
      setState(() => _scanning = true);
    }
  }

  void _showTrackPicker(BuildContext context) {
    HapticFeedback.selectionClick();
    final library = ref.read(effectiveLibraryProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: library.length,
          itemBuilder: (_, i) {
            final track = library[i];
            return ListTile(
              leading: const Icon(Icons.music_note_rounded,
                  color: AppColors.yellowVivid),
              title: Text(track.title,
                  style: const TextStyle(color: AppColors.cream)),
              subtitle: Text(track.artist,
                  style: TextStyle(
                      color: AppColors.cream.withValues(alpha: 0.6))),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTrack = track);
                Navigator.pop(ctx);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _sendTrack(String peer) async {
    if (_selectedTrack == null) return;
    HapticFeedback.heavyImpact();
    // Placeholder — connexion réelle via nearby_connections
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Envoi de « ${_selectedTrack!.title} » à $peer…'),
          backgroundColor: AppColors.yellowGold,
        ),
      );
    }
  }
}

/// Radar animé avec sweep circulaire.
class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.active,
    required this.sweepAngle,
    required this.peers,
  });

  final bool active;
  final double sweepAngle;
  final List<String> peers;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) / 2 - 10;

    // Cercles concentriques
    for (var i = 1; i <= 3; i++) {
      final r = maxR * i / 3;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = AppColors.yellowVivid.withValues(alpha: 0.1 + 0.05 * i)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Lignes cardinales
    final axisPaint = Paint()
      ..color = AppColors.cream.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(center.dx, center.dy - maxR),
        Offset(center.dx, center.dy + maxR), axisPaint);
    canvas.drawLine(Offset(center.dx - maxR, center.dy),
        Offset(center.dx + maxR, center.dy), axisPaint);

    if (active) {
      // Sweep radar (arc lumineux)
      final sweepPaint = Paint()
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: sweepAngle - 0.6,
          endAngle: sweepAngle,
          colors: [
            Colors.transparent,
            AppColors.yellowVivid.withValues(alpha: 0.25),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: maxR));
      canvas.drawCircle(center, maxR, sweepPaint);

      // Ligne de sweep
      final lineEnd = center +
          Offset(
            math.cos(sweepAngle) * maxR,
            math.sin(sweepAngle) * maxR,
          );
      canvas.drawLine(
        center,
        lineEnd,
        Paint()
          ..color = AppColors.yellowVivid.withValues(alpha: 0.4)
          ..strokeWidth = 2,
      );

      // Point central actif
      canvas.drawCircle(
        center,
        8,
        Paint()..color = AppColors.yellowVivid,
      );
      canvas.drawCircle(
        center,
        12,
        Paint()
          ..color = AppColors.yellowVivid.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Points des peers
      for (var i = 0; i < peers.length; i++) {
        final angle = (i + 1) * math.pi * 0.7;
        final dist = maxR * 0.4 + (i * maxR * 0.15);
        final peerCenter = center +
            Offset(math.cos(angle) * dist, math.sin(angle) * dist);

        canvas.drawCircle(
          peerCenter,
          8,
          Paint()
            ..color = AppColors.success
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(peerCenter, 5, Paint()..color = AppColors.success);
        canvas.drawCircle(
          peerCenter,
          5,
          Paint()
            ..color = AppColors.border
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    } else {
      // Point central inactif
      canvas.drawCircle(
        center,
        6,
        Paint()..color = AppColors.cream.withValues(alpha: 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      active != oldDelegate.active ||
      sweepAngle != oldDelegate.sweepAngle ||
      peers.length != oldDelegate.peers.length;
}
