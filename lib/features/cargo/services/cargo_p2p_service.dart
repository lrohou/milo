import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nearby_connections/nearby_connections.dart';

/// Service P2P « Cargo » — partage offline via nearby_connections.
class CargoP2pService {
  CargoP2pService({this.userName = 'Milo'});

  final String userName;
  static const _strategy = Strategy.P2P_CLUSTER;
  static const _serviceId = 'com.milo.cargo';

  final _peersController = StreamController<List<String>>.broadcast();
  bool _isAdvertising = false;
  bool _isDiscovering = false;

  Stream<List<String>> get peersStream => _peersController.stream;
  final List<String> _peers = [];

  /// Lance le radar — détection des appareils Milo à proximité.
  Future<void> startRadar() async {
    if (_isDiscovering) return;
    _isDiscovering = true;
    HapticFeedback.mediumImpact();

    await Nearby().startDiscovery(
      userName,
      _strategy,
      onEndpointFound: (id, name, serviceId) {
        if (!_peers.contains(name)) {
          _peers.add(name);
          _peersController.add(List.from(_peers));
          HapticFeedback.lightImpact();
        }
      },
      onEndpointLost: (id) {
        _peers.removeWhere((_) => true);
        _peersController.add([]);
      },
      serviceId: _serviceId,
    );

    await Nearby().startAdvertising(
      userName,
      _strategy,
      onConnectionInitiated: (id, info) {
        Nearby().acceptConnection(
          id,
          onPayLoadRecieved: (endpointId, payload) {},
        );
      },
      onConnectionResult: (id, status) {},
      onDisconnected: (id) {},
      serviceId: _serviceId,
    );
    _isAdvertising = true;
  }

  /// Transfère un fichier audio à un pair connecté.
  Future<void> sendTrack(String endpointId, String filePath) async {
    HapticFeedback.heavyImpact();
    // Payload fichier — nécessite connexion établie au pair
    await Nearby().sendBytesPayload(
      endpointId,
      Uint8List.fromList(filePath.codeUnits),
    );
  }

  Future<void> stop() async {
    if (_isDiscovering) {
      await Nearby().stopDiscovery();
      _isDiscovering = false;
    }
    if (_isAdvertising) {
      await Nearby().stopAdvertising();
      _isAdvertising = false;
    }
    _peers.clear();
    _peersController.add([]);
  }

  void dispose() {
    stop();
    _peersController.close();
  }
}
