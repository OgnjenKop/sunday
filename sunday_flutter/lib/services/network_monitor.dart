import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkMonitor extends ChangeNotifier {
  bool _isConnected = true;
  ConnectivityResult _connectionType = ConnectivityResult.none;

  bool get isConnected => _isConnected;
  ConnectivityResult get connectionType => _connectionType;

  NetworkMonitor() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      _updateConnectionStatus(result);
    });
    _init();
  }

  Future<void> _init() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    final newConnectionType = result.isEmpty ? ConnectivityResult.none : result.first;
    final newIsConnected = newConnectionType != ConnectivityResult.none;

    if (newIsConnected != _isConnected || newConnectionType != _connectionType) {
      _isConnected = newIsConnected;
      _connectionType = newConnectionType;
      notifyListeners();
    }
  }
}
