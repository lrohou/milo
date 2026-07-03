import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:milo/shared/models/track_model.dart';

/// Service « Ruade » — réveil intelligent avec escalade agressive.
class KickAlarmService {
  KickAlarmService();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  int _snoozeCount = 0;
  bool _isRuadeMode = false;

  int get snoozeCount => _snoozeCount;
  bool get isRuadeMode => _isRuadeMode;

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  /// Programme une alarme Ruade (notification immédiate pour la démo ;
  /// brancher android_alarm_manager_plus pour alarmes exactes en production).
  Future<void> scheduleAlarm(DateTime time) async {
    _snoozeCount = 0;
    _isRuadeMode = false;
    HapticFeedback.mediumImpact();

    await _notifications.show(
      0,
      'Milo — Ruade',
      'Alarme programmée pour ${time.hour}:${time.minute.toString().padLeft(2, '0')}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'milo_alarm',
          'Alarmes Milo',
          channelDescription: 'Réveil Ruade intelligent',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Snooze — après 2 fois, mode Ruade agressif.
  Future<TrackModel?> onSnooze(List<TrackModel> library) async {
    _snoozeCount++;
    HapticFeedback.heavyImpact();

    if (_snoozeCount > 2) {
      _isRuadeMode = true;
      // Piste la plus agressive
      final aggressive = [...library]
        ..sort((a, b) => b.effectiveBpm.compareTo(a.effectiveBpm));
      return aggressive.firstWhere(
        (t) => t.isAggressive,
        orElse: () => aggressive.first,
      );
    }

    // Piste calme
    return library.where((t) => t.isCalm).firstOrNull ??
        library.firstOrNull;
  }

  /// Réinitialise le compteur snooze.
  void reset() {
    _snoozeCount = 0;
    _isRuadeMode = false;
  }
}
