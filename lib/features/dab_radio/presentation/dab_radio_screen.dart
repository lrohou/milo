import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:milo/features/dab_radio/models/dab_radio_station.dart';
import 'package:milo/core/providers/audio_providers.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/shared/widgets/glass_card.dart';

final openDabStationsProvider = StateNotifierProvider<OpenDabStationsNotifier, List<DabRadioStation>>((ref) {
  return OpenDabStationsNotifier();
});

class OpenDabStationsNotifier extends StateNotifier<List<DabRadioStation>> {
  OpenDabStationsNotifier() : super([]) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'open_dab_stations';

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final stations = decoded.map((e) => DabRadioStation(
          id: e['id'] ?? '',
          name: e['name'] ?? '',
          frequency: e['frequency'] ?? 'Open DAB',
          streamUrl: e['streamUrl'] ?? '',
          genre: e['genre'] ?? 'Custom',
          logoEmoji: e['logoEmoji'] ?? '📻',
        )).toList();
        state = stations;
      } catch (e) {
        // Handle error quietly
      }
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> encoded = state.map((e) => {
      'id': e.id,
      'name': e.name,
      'frequency': e.frequency,
      'streamUrl': e.streamUrl,
      'genre': e.genre,
      'logoEmoji': e.logoEmoji,
    }).toList();
    prefs.setString(_prefsKey, jsonEncode(encoded));
  }

  void addStation(DabRadioStation station) {
    if (!state.any((s) => s.id == station.id || (s.name == station.name && s.streamUrl == station.streamUrl))) {
      state = [...state, station];
      _saveToPrefs();
    }
  }

  void removeStation(String id) {
    state = state.where((s) => s.id != id).toList();
    _saveToPrefs();
  }

  void moveStation(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.length) return;
    if (newIndex < 0 || newIndex >= state.length) return;
    final newState = [...state];
    final station = newState.removeAt(oldIndex);
    newState.insert(newIndex, station);
    state = newState;
    _saveToPrefs();
  }

  void updateStation(DabRadioStation station) {
    final index = state.indexWhere((s) => s.id == station.id);
    if (index != -1) {
      final newState = [...state];
      newState[index] = station;
      state = newState;
      _saveToPrefs();
    }
  }
}

class OpenDabScreen extends ConsumerStatefulWidget {
  const OpenDabScreen({super.key});

  @override
  ConsumerState<OpenDabScreen> createState() => _OpenDabScreenState();
}

class _OpenDabScreenState extends ConsumerState<OpenDabScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<DabRadioStation> _searchResults = [];
  bool _isLoading = false;
  String _errorMsg = '';
  bool _showSearchResults = false;

  // Liste des emojis disponibles pour les radios
  static const _availableEmojis = [
    '📻', '🎵', '🎶', '🎤', '🎧', '🎸', '🎹', '🎷', '🎺', '🥁',
    '🌍', '🌎', '🌏', '🇫🇷', '🇬🇧', '🇺🇸', '🇪🇸', '🇩🇪', '🇮🇹', '🇯🇵',
    '📰', '📡', '🗞️', '💬', '🎙️', '🔊', '🔉', '📢', '🔔', '✨',
    '🔥', '💎', '⭐', '🌟', '💫', '🎯', '🎪', '🎭', '🎨', '🎬',
    '❤️', '💙', '💚', '💛', '🧡', '💜', '🖤', '💖', '💝', '🔗',
  ];

  Future<void> _searchStations(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMsg = '';
      _searchResults = [];
      _showSearchResults = true;
    });

    try {
      final url = Uri.parse('https://de1.api.radio-browser.info/json/stations/search?name=${Uri.encodeComponent(query)}&limit=20');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final results = data.map((json) {
          return DabRadioStation(
            id: json['stationuuid'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            name: json['name']?.toString().trim() ?? 'Unknown Station',
            frequency: 'Open DAB',
            streamUrl: json['url_resolved'] ?? json['url'] ?? '',
            genre: (json['tags'] != null && json['tags'].toString().isNotEmpty) 
                ? json['tags'].toString().split(',').first 
                : 'Custom',
            logoEmoji: '🌍',
          );
        }).where((s) => s.streamUrl.isNotEmpty).toList();

        setState(() {
          _searchResults = results;
        });
      } else {
        setState(() {
          _errorMsg = 'Erreur serveur: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Erreur: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAddStationMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ajouter une radio',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.cream,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.yellowVivid,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.search, color: AppColors.backgroundDeep),
                ),
                title: const Text('Rechercher sur Radio-Browser', style: TextStyle(color: AppColors.cream)),
                subtitle: Text('Parcourir des milliers de stations', style: TextStyle(color: AppColors.cream.withValues(alpha: 0.6))),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSearchDialog();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.yellowVivid,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_link, color: AppColors.backgroundDeep),
                ),
                title: const Text('Ajouter une URL personnalisée', style: TextStyle(color: AppColors.cream)),
                subtitle: Text('Entrer manuellement un flux audio', style: TextStyle(color: AppColors.cream.withValues(alpha: 0.6))),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddCustomStationDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog() {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (ctx, scrollController) => Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cream.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rechercher une radio',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.cream),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    style: const TextStyle(color: AppColors.cream),
                    decoration: InputDecoration(
                      hintText: 'Nom de la station...',
                      hintStyle: TextStyle(color: AppColors.cream.withValues(alpha: 0.5)),
                      prefixIcon: const Icon(Icons.search, color: AppColors.yellowVivid),
                      filled: true,
                      fillColor: AppColors.backgroundDeep,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.yellowVivid, width: 2),
                      ),
                    ),
                    onSubmitted: (val) async {
                      await _searchStations(val);
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.yellowVivid,
                      foregroundColor: AppColors.backgroundDeep,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      await _searchStations(searchCtrl.text);
                      setModalState(() {});
                    },
                    child: const Text('Rechercher', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const CircularProgressIndicator(color: AppColors.yellowVivid)
                  else if (_errorMsg.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_errorMsg, style: const TextStyle(color: AppColors.error)),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final station = _searchResults[index];
                          final savedStations = ref.watch(openDabStationsProvider);
                          final isSaved = savedStations.any((s) => s.id == station.id || (s.name == station.name && s.streamUrl == station.streamUrl));
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              onTap: () {
                                if (!isSaved) {
                                  _showEmojiPickerForStation(station, (emoji) {
                                    final stationWithEmoji = DabRadioStation(
                                      id: station.id,
                                      name: station.name,
                                      frequency: station.frequency,
                                      streamUrl: station.streamUrl,
                                      genre: station.genre,
                                      logoEmoji: emoji,
                                    );
                                    ref.read(openDabStationsProvider.notifier).addStation(stationWithEmoji);
                                    setModalState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${station.name} ajoutée')),
                                    );
                                  });
                                }
                              },
                              child: Row(
                                children: [
                                  Text(station.logoEmoji, style: const TextStyle(fontSize: 28)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          station.name,
                                          style: const TextStyle(color: AppColors.cream, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          station.genre,
                                          style: TextStyle(color: AppColors.cream.withValues(alpha: 0.6), fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSaved)
                                    const Icon(Icons.check_circle, color: AppColors.success)
                                  else
                                    const Icon(Icons.add_circle_outline, color: AppColors.yellowVivid),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEmojiPickerForStation(DabRadioStation station, void Function(String emoji) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choisir un emoji pour "${station.name}"',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.cream),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableEmojis.map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      onSelect(emoji);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundDeep,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCustomStationDialog() {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String selectedEmoji = '📻';
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.backgroundSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Ajouter un flux personnalisé', style: TextStyle(color: AppColors.cream)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: ctx,
                      backgroundColor: AppColors.backgroundSurface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (emojiCtx) => SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Choisir un emoji', style: TextStyle(color: AppColors.cream, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _availableEmojis.map((emoji) {
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.pop(emojiCtx);
                                      setDialogState(() => selectedEmoji = emoji);
                                    },
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: selectedEmoji == emoji ? AppColors.yellowVivid : AppColors.backgroundDeep,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: selectedEmoji == emoji ? AppColors.yellowGold : AppColors.border,
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDeep,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: Center(
                      child: Text(selectedEmoji, style: const TextStyle(fontSize: 40)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Appuyer pour changer', style: TextStyle(color: AppColors.cream.withValues(alpha: 0.5), fontSize: 12)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: AppColors.cream),
                  decoration: InputDecoration(
                    labelText: 'Nom de la station',
                    labelStyle: TextStyle(color: AppColors.cream.withValues(alpha: 0.7)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.yellowVivid, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlCtrl,
                  style: const TextStyle(color: AppColors.cream),
                  decoration: InputDecoration(
                    labelText: 'URL du flux audio',
                    labelStyle: TextStyle(color: AppColors.cream.withValues(alpha: 0.7)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.yellowVivid, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: AppColors.cream)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellowVivid,
                foregroundColor: AppColors.backgroundDeep,
              ),
              onPressed: () {
                final name = nameCtrl.text.trim();
                final url = urlCtrl.text.trim();
                if (name.isNotEmpty && url.isNotEmpty) {
                  final newStation = DabRadioStation(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    frequency: 'Manuel',
                    streamUrl: url,
                    genre: 'Personnalisé',
                    logoEmoji: selectedEmoji,
                  );
                  ref.read(openDabStationsProvider.notifier).addStation(newStation);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Station ajoutée')),
                  );
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStationOptionsMenu(DabRadioStation station, int index) {
    final savedStations = ref.read(openDabStationsProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(station.logoEmoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name,
                          style: const TextStyle(color: AppColors.cream, fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          station.genre,
                          style: TextStyle(color: AppColors.cream.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _OptionTile(
                icon: Icons.play_arrow_rounded,
                label: 'Lire',
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(audioHandlerProvider).playRadioStation(station, savedStations);
                },
              ),
              _OptionTile(
                icon: Icons.edit_rounded,
                label: 'Modifier l\'emoji',
                onTap: () {
                  Navigator.pop(ctx);
                  _showEmojiPickerForStation(station, (emoji) {
                    final updatedStation = DabRadioStation(
                      id: station.id,
                      name: station.name,
                      frequency: station.frequency,
                      streamUrl: station.streamUrl,
                      genre: station.genre,
                      logoEmoji: emoji,
                    );
                    ref.read(openDabStationsProvider.notifier).updateStation(updatedStation);
                  });
                },
              ),
              if (index > 0)
                _OptionTile(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Monter',
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(openDabStationsProvider.notifier).moveStation(index, index - 1);
                  },
                ),
              if (index < savedStations.length - 1)
                _OptionTile(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Descendre',
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(openDabStationsProvider.notifier).moveStation(index, index + 1);
                  },
                ),
              _OptionTile(
                icon: Icons.delete_rounded,
                iconColor: AppColors.error,
                label: 'Supprimer',
                labelColor: AppColors.error,
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteStation(station);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteStation(DabRadioStation station) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer la station ?', style: TextStyle(color: AppColors.cream)),
        content: Text(
          'Voulez-vous vraiment supprimer "${station.name}" de votre liste ?',
          style: TextStyle(color: AppColors.cream.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: AppColors.cream)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.cream,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(openDabStationsProvider.notifier).removeStation(station.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${station.name} supprimée')),
              );
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savedStations = ref.watch(openDabStationsProvider);
    final filteredStations = _searchQuery.isEmpty
        ? savedStations
        : savedStations.where((s) =>
            s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s.genre.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Radios DAB+'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Ajouter une radio',
            onPressed: _showAddStationMenu,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
        children: [
          // Barre de recherche (même style que la bibliothèque)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: AppColors.cream),
              decoration: InputDecoration(
                hintText: 'Rechercher une radio...',
                hintStyle: TextStyle(color: AppColors.cream.withValues(alpha: 0.5)),
                prefixIcon: const Icon(Icons.search, color: AppColors.yellowVivid),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.cream),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.backgroundSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.yellowVivid, width: 2),
                ),
              ),
            ),
          ),

          // Liste des stations
          Expanded(
            child: filteredStations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📻', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Aucune radio trouvée'
                              : 'Aucune radio enregistrée',
                          style: TextStyle(color: AppColors.cream.withValues(alpha: 0.7), fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        if (_searchQuery.isEmpty)
                          TextButton.icon(
                            onPressed: _showAddStationMenu,
                            icon: const Icon(Icons.add, color: AppColors.yellowVivid),
                            label: const Text('Ajouter une radio', style: TextStyle(color: AppColors.yellowVivid)),
                          ),
                      ],
                    ),
                  )
                : _searchQuery.isEmpty
                    // Mode réordonnancement par glisser-déposer (long press)
                    ? ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                        itemCount: savedStations.length,
                        onReorder: (oldIndex, newIndex) {
                          HapticFeedback.mediumImpact();
                          // ReorderableListView ajuste newIndex si on descend un élément
                          if (newIndex > oldIndex) newIndex--;
                          ref.read(openDabStationsProvider.notifier).moveStation(oldIndex, newIndex);
                        },
                        proxyDecorator: (child, index, animation) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) {
                              final animValue = Curves.easeInOut.transform(animation.value);
                              final scale = 1.0 + (animValue * 0.05);
                              final elevation = animValue * 8;
                              return Transform.scale(
                                scale: scale,
                                child: Material(
                                  color: Colors.transparent,
                                  elevation: elevation,
                                  shadowColor: AppColors.yellowVivid.withValues(alpha: 0.3),
                                  child: child,
                                ),
                              );
                            },
                            child: child,
                          );
                        },
                        itemBuilder: (context, index) {
                          final station = savedStations[index];
                          return _ReorderableRadioTile(
                            key: ValueKey(station.id),
                            station: station,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref.read(audioHandlerProvider).playRadioStation(station, savedStations);
                            },
                            onOptions: () => _showStationOptionsMenu(station, index),
                          );
                        },
                      )
                    // Mode recherche - liste non réordonnançable
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                        itemCount: filteredStations.length,
                        itemBuilder: (context, index) {
                          final station = filteredStations[index];
                          final realIndex = savedStations.indexOf(station);
                          return _RadioTile(
                            station: station,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref.read(audioHandlerProvider).playRadioStation(station, savedStations);
                            },
                            onOptions: () => _showStationOptionsMenu(station, realIndex),
                          );
                        },
                      ),
          ),
        ],
      ),
          // Barre de contrôle audio en bas
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _DabAudioControlBar(),
          ),
        ],
      ),
    );
  }
}

/// Barre de contrôle audio affichée en bas de l'écran DAB Radio.
class _DabAudioControlBar extends ConsumerWidget {
  const _DabAudioControlBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(currentTrackProvider);
    final playbackAsync = ref.watch(playbackStateProvider);
    final handler = ref.watch(audioHandlerProvider);

    final media = mediaAsync.valueOrNull;
    final isPlaying = playbackAsync.valueOrNull?.playing ?? false;
    final isRadio = media?.extras?['isRadio'] == true;

    if (media == null || !isRadio) return const SizedBox.shrink();

    final radioEmoji = media.extras?['emoji'] as String? ?? '📻';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.backgroundDeep,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Center(
                child: Text(radioEmoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    media.title,
                    style: const TextStyle(
                      color: AppColors.cream,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    media.artist ?? 'Radio DAB+',
                    style: TextStyle(
                      color: AppColors.cream.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded,
                  color: AppColors.cream, size: 28),
              onPressed: () => handler.skipToPrevious(),
            ),
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: AppColors.yellowVivid,
                size: 32,
              ),
              onPressed: () {
                if (isPlaying) {
                  handler.pause();
                } else {
                  handler.play();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded,
                  color: AppColors.cream, size: 28),
              onPressed: () => handler.skipToNext(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioTile extends StatelessWidget {
  const _RadioTile({
    required this.station,
    required this.onTap,
    required this.onOptions,
  });

  final DabRadioStation station;
  final VoidCallback onTap;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        onTap: onTap,
        child: Row(
          children: [
            // Emoji container (similaire à MiloArtworkWidget)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.backgroundDeep,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Center(
                child: Text(
                  station.logoEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    child: _MarqueeText(
                      text: station.name,
                      style: Theme.of(context).textTheme.titleLarge!,
                    ),
                  ),
                  Text(
                    '${station.frequency} · ${station.genre}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.cream),
              onPressed: onOptions,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget radio avec support de drag-and-drop via long press
class _ReorderableRadioTile extends StatelessWidget {
  const _ReorderableRadioTile({
    super.key,
    required this.station,
    required this.onTap,
    required this.onOptions,
  });

  final DabRadioStation station;
  final VoidCallback onTap;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        onTap: onTap,
        child: Row(
          children: [
            // Icône de drag (visible pour indiquer la possibilité de réordonner)
            ReorderableDragStartListener(
              index: 0, // L'index sera géré par le parent
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: AppColors.cream.withValues(alpha: 0.4),
                  size: 20,
                ),
              ),
            ),
            // Emoji container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.backgroundDeep,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Center(
                child: Text(
                  station.logoEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    child: _MarqueeText(
                      text: station.name,
                      style: Theme.of(context).textTheme.titleLarge!,
                    ),
                  ),
                  Text(
                    '${station.frequency} · ${station.genre}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.cream),
              onPressed: onOptions,
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.cream),
      title: Text(label, style: TextStyle(color: labelColor ?? AppColors.cream)),
      onTap: onTap,
    );
  }
}

/// Widget texte défilant pour les noms longs
class _MarqueeText extends StatefulWidget {
  const _MarqueeText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _needsScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndScroll());
  }

  @override
  void didUpdateWidget(_MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _scrollController.jumpTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndScroll());
    }
  }

  void _checkAndScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    _needsScroll = _scrollController.position.maxScrollExtent > 0;
    if (_needsScroll) {
      _startScrolling();
    }
  }

  Future<void> _startScrolling() async {
    while (mounted && _scrollController.hasClients && _needsScroll) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || !_scrollController.hasClients) return;
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(
          milliseconds: (_scrollController.position.maxScrollExtent * 30).toInt(),
        ),
        curve: Curves.linear,
      );
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || !_scrollController.hasClients) return;
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
      ),
    );
  }
}
