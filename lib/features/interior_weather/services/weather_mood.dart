/// Ambiances détectées par la Météo Intérieure.
enum WeatherMood {
  sunny('Soleil', '☀️', 'Musique joyeuse & modes majeurs'),
  lightning('Éclair', '⚡', 'Musique intense & BPM élevé'),
  rain('Pluie', '🌧️', 'Ambiance calme & mélancolique'),
  cloud('Nuage', '☁️', 'Mix équilibré & neutre');

  const WeatherMood(this.label, this.emoji, this.description);

  final String label;
  final String emoji;
  final String description;
}
