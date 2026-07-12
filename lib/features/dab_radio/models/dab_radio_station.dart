/// Modèle d'une station radio DAB+.
class DabRadioStation {
  const DabRadioStation({
    required this.id,
    required this.name,
    required this.frequency,
    required this.streamUrl,
    required this.genre,
    this.logoEmoji = '📻',
  });

  final String id;
  final String name;
  final String frequency;
  final String streamUrl;
  final String genre;
  final String logoEmoji;
}

/// Stations françaises disponibles en DAB+ avec flux internet.
const kDabRadioStations = <DabRadioStation>[
  DabRadioStation(
    id: 'france_inter',
    name: 'France Inter',
    frequency: 'DAB+ 5A',
    streamUrl: 'https://icecast.radiofrance.fr/franceinter-midfi.mp3',
    genre: 'Généraliste',
    logoEmoji: '🇫🇷',
  ),
  DabRadioStation(
    id: 'france_info',
    name: 'France Info',
    frequency: 'DAB+ 5A',
    streamUrl: 'https://icecast.radiofrance.fr/franceinfo-midfi.mp3',
    genre: 'Info',
    logoEmoji: '📰',
  ),
  DabRadioStation(
    id: 'fip',
    name: 'FIP',
    frequency: 'DAB+ 5A',
    streamUrl: 'https://icecast.radiofrance.fr/fip-midfi.mp3',
    genre: 'Éclectique',
    logoEmoji: '🎷',
  ),
  DabRadioStation(
    id: 'france_musique',
    name: 'France Musique',
    frequency: 'DAB+ 5A',
    streamUrl: 'https://icecast.radiofrance.fr/francemusique-midfi.mp3',
    genre: 'Classique',
    logoEmoji: '🎻',
  ),
  DabRadioStation(
    id: 'rtl',
    name: 'RTL',
    frequency: 'DAB+ 7B',
    streamUrl: 'https://streaming.radio.grouprtl.fr/rtl-1-48-128',
    genre: 'Généraliste',
    logoEmoji: '📡',
  ),
  DabRadioStation(
    id: 'europe1',
    name: 'Europe 1',
    frequency: 'DAB+ 7B',
    streamUrl: 'https://stream.europe1.fr/europe1.mp3',
    genre: 'Info',
    logoEmoji: '🗞️',
  ),
  DabRadioStation(
    id: 'nrj',
    name: 'NRJ',
    frequency: 'DAB+ 7B',
    streamUrl: 'https://streaming.nrjaudio.fm/oufdf5pmqu8uv',
    genre: 'Hits',
    logoEmoji: '🔥',
  ),
  DabRadioStation(
    id: 'rmc',
    name: 'RMC',
    frequency: 'DAB+ 7B',
    streamUrl: 'https://streaming.radio.grouprtl.fr/rmc-1-48-128',
    genre: 'Talk',
    logoEmoji: '🎙️',
  ),
];
