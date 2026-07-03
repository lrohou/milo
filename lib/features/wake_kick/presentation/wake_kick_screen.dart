import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/core/providers/audio_providers.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/features/library/providers/library_providers.dart';
import 'package:milo/features/wake_kick/services/kick_alarm_service.dart';
import 'package:milo/shared/widgets/glass_card.dart';
import 'package:milo/shared/widgets/neo_brutal_button.dart';


final kickAlarmServiceProvider = Provider<KickAlarmService>((ref) {
  return KickAlarmService();
});

/// UI « Ruade » — alarme intelligente avec TimePicker et mode agressif.
class WakeKickScreen extends ConsumerStatefulWidget {
  const WakeKickScreen({super.key});

  @override
  ConsumerState<WakeKickScreen> createState() => _WakeKickScreenState();
}

class _WakeKickScreenState extends ConsumerState<WakeKickScreen> {
  TimeOfDay? _selectedTime;

  @override
  Widget build(BuildContext context) {
    final alarm = ref.watch(kickAlarmServiceProvider);

    Widget body = Column(
      children: [
        GlassCard(
          child: Column(
            children: [
              Text(
                alarm.isRuadeMode ? '💥 RUADE !' : '🫏 Ruade',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: alarm.isRuadeMode
                          ? AppColors.error
                          : AppColors.yellowVivid,
                    ),
              ),
              const SizedBox(height: 16),

              // — Compteur snooze visuel
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final active = i < alarm.snoozeCount;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: active
                            ? (alarm.isRuadeMode
                                ? AppColors.error
                                : AppColors.yellowVivid)
                            : AppColors.backgroundSurface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.border,
                          width: 2.5,
                        ),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: (alarm.isRuadeMode
                                          ? AppColors.error
                                          : AppColors.yellowGold)
                                      .withValues(alpha: 0.4),
                                  offset: const Offset(2, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        active ? Icons.alarm_on_rounded : Icons.alarm_rounded,
                        color: active
                            ? AppColors.backgroundDeep
                            : AppColors.cream.withValues(alpha: 0.4),
                        size: 22,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Text(
                'Snooze : ${alarm.snoozeCount}/2',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                alarm.isRuadeMode
                    ? 'Volume max — Rock agressif !'
                    : 'Calme au 1er réveil, agressif après 2 snooze',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // — Sélecteur d'heure
        GlassCard(
          onTap: () => _pickTime(context),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.yellowVivid,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 2.5),
                ),
                child: const Icon(Icons.access_time_rounded,
                    color: AppColors.backgroundDeep, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Heure du réveil',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      _selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'Aucune heure programmée',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_rounded, color: AppColors.cream, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // — Boutons d'action
        NeoBrutalButton(
          label: 'Programmer l\'alarme',
          icon: Icons.alarm_add_rounded,
          expanded: true,
          onPressed: _selectedTime != null
              ? () => _scheduleAlarm(alarm)
              : null,
        ),
        const SizedBox(height: 12),
        NeoBrutalButton(
          label: 'Snooze',
          icon: Icons.snooze_rounded,
          backgroundColor: AppColors.backgroundSurface,
          foregroundColor: AppColors.cream,
          expanded: true,
          onPressed: () => _onSnooze(alarm),
        ),
        const SizedBox(height: 12),
        if (alarm.snoozeCount > 0 || _selectedTime != null)
          NeoBrutalButton(
            label: 'Réinitialiser',
            icon: Icons.refresh_rounded,
            backgroundColor: AppColors.backgroundSurface,
            foregroundColor: AppColors.cream,
            expanded: true,
            onPressed: () {
              HapticFeedback.lightImpact();
              alarm.reset();
              setState(() => _selectedTime = null);
            },
          ),
      ],
    );

    if (alarm.isRuadeMode) {
      body = body
          .animate(onPlay: (c) => c.repeat())
          .shake(hz: 6, rotation: 0.05);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ruade')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: body,
      ),
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    HapticFeedback.selectionClick();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 7, minute: 0),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.backgroundSurface,
              hourMinuteColor: AppColors.backgroundDeep,
              hourMinuteTextColor: AppColors.cream,
              dialHandColor: AppColors.yellowVivid,
              dialBackgroundColor: AppColors.backgroundDeep,
              dialTextColor: AppColors.cream,
              entryModeIconColor: AppColors.yellowVivid,
              dayPeriodColor: AppColors.yellowVivid.withValues(alpha: 0.2),
              dayPeriodTextColor: AppColors.cream,
              helpTextStyle: const TextStyle(color: AppColors.cream),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border, width: 3),
              ),
            ),
            colorScheme: const ColorScheme.dark(
              primary: AppColors.yellowVivid,
              onPrimary: AppColors.backgroundDeep,
              surface: AppColors.backgroundSurface,
              onSurface: AppColors.cream,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      HapticFeedback.mediumImpact();
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _scheduleAlarm(KickAlarmService alarm) async {
    if (_selectedTime == null) return;
    HapticFeedback.heavyImpact();

    await alarm.initialize();
    final now = DateTime.now();
    var target = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }
    await alarm.scheduleAlarm(target);

    if (!mounted) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Alarme programmée pour ${_selectedTime!.format(context)}',
          ),
          backgroundColor: AppColors.backgroundSurface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onSnooze(KickAlarmService alarm) async {
    HapticFeedback.heavyImpact();
    final library = ref.read(effectiveLibraryProvider);
    final track = await alarm.onSnooze(library);

    if (track != null && mounted) {
      // Jouer la piste via le handler audio
      final handler = ref.read(audioHandlerProvider);
      final index = library.indexWhere((t) => t.id == track.id);
      if (index >= 0) {
        await handler.loadQueue(library, startIndex: index);
        await handler.play();

        // Volume max en mode ruade
        if (alarm.isRuadeMode) {
          await handler.player.setVolume(1.0);
        }
      }

      setState(() {}); // Refresh UI

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            alarm.isRuadeMode
                ? '💥 RUADE : ${track.title}'
                : '🌙 Calme : ${track.title}',
          ),
          backgroundColor:
              alarm.isRuadeMode ? AppColors.error : AppColors.backgroundSurface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
