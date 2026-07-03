/// États d'humeur dynamiques de la mascotte Milo.
enum MiloMood {
  /// Défaut — joyeux et énergique
  happy,

  /// Genre Metal / Rock — style rock
  rock,

  /// Genre Jazz — posé avec café
  jazz,

  /// BPM lent — balancement relaxant
  chill,

  /// Alarme Ruade — agressif
  kick,

  /// Mode sport — sprint détecté
  sprint,
}

extension MiloMoodX on MiloMood {
  String get label => switch (this) {
        MiloMood.happy => 'Joyeux',
        MiloMood.rock => 'Rock',
        MiloMood.jazz => 'Jazz & Café',
        MiloMood.chill => 'Zen',
        MiloMood.kick => 'RUADE !',
        MiloMood.sprint => 'Sprint !',
      };

  String get emoji => switch (this) {
        MiloMood.happy => '🫏',
        MiloMood.rock => '🤘',
        MiloMood.jazz => '☕',
        MiloMood.chill => '🌿',
        MiloMood.kick => '💥',
        MiloMood.sprint => '🏀',
      };
}
