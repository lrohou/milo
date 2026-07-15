import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:milo/features/dab_radio/models/dab_radio_station.dart';
import 'package:milo/core/providers/audio_providers.dart';

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
}

class OpenDabScreen extends ConsumerStatefulWidget {
  const OpenDabScreen({super.key});

  @override
  ConsumerState<OpenDabScreen> createState() => _OpenDabScreenState();
}

class _OpenDabScreenState extends ConsumerState<OpenDabScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DabRadioStation> _searchResults = [];
  bool _isLoading = false;
  String _errorMsg = '';

  Future<void> _searchStations(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMsg = '';
      _searchResults = [];
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
          _errorMsg = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAddCustomStationDialog() {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Stream'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Station Name'),
            ),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(labelText: 'Stream URL'),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final url = urlCtrl.text.trim();
              if (name.isNotEmpty && url.isNotEmpty) {
                final newStation = DabRadioStation(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  frequency: 'Manual',
                  streamUrl: url,
                  genre: 'Custom Stream',
                  logoEmoji: '🔗',
                );
                ref.read(openDabStationsProvider.notifier).addStation(newStation);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Station added')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final savedStations = ref.watch(openDabStationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open DAB (BYOC)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link),
            tooltip: 'Add Custom URL',
            onPressed: _showAddCustomStationDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search Radio-Browser...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _searchStations,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _searchStations(_searchController.text),
                  child: const Text('Search'),
                ),
              ],
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          else if (_errorMsg.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_errorMsg, style: const TextStyle(color: Colors.red)),
            ),

          if (_searchResults.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Search Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final station = _searchResults[index];
                  final isSaved = savedStations.any((s) => s.id == station.id || (s.name == station.name && s.streamUrl == station.streamUrl));

                  return ListTile(
                    leading: Text(station.logoEmoji, style: const TextStyle(fontSize: 24)),
                    title: Text(station.name),
                    subtitle: Text(station.genre, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: isSaved
                        ? const Icon(Icons.check, color: Colors.green)
                        : IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              ref.read(openDabStationsProvider.notifier).addStation(station);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Saved ${station.name}')),
                              );
                            },
                          ),
                  );
                },
              ),
            ),
            const Divider(),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Your Saved Stations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          Expanded(
            child: savedStations.isEmpty
                ? const Center(child: Text('No saved stations yet. Search or add one manually!'))
                : ListView.builder(
                    itemCount: savedStations.length,
                    itemBuilder: (context, index) {
                      final station = savedStations[index];
                      return ListTile(
                        leading: Text(station.logoEmoji, style: const TextStyle(fontSize: 24)),
                        title: Text(station.name),
                        subtitle: Text(station.streamUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          // Play the station
                          ref.read(audioHandlerProvider).playRadioStation(station);
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            ref.read(openDabStationsProvider.notifier).removeStation(station.id);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
