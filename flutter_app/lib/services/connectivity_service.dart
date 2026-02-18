import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;

  ConnectivityService._internal() {
    _init();
  }

  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  ConnectivityResult get connectionStatus => _connectionStatus;

  void _init() {
    // Check initial connectivity
    _checkConnectivity();
    
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results.isNotEmpty ? results.first : ConnectivityResult.none);
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results.isNotEmpty ? results.first : ConnectivityResult.none);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _updateConnectionStatus(ConnectivityResult.none);
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _connectionStatus = result;
    final wasOnline = _isOnline;
    
    // Update online status
    _isOnline = result != ConnectivityResult.none;
    
    // Notify listeners if status changed
    if (wasOnline != _isOnline) {
      debugPrint('Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
      notifyListeners();
    }
  }

  Future<bool> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.isNotEmpty && results.first != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error checking connection: $e');
      return false;
    }
  }

  String getConnectionTypeName() {
    switch (_connectionStatus) {
      case ConnectivityResult.wifi:
        return 'Wi-Fi';
      case ConnectivityResult.mobile:
        return 'Mobil Veri';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Diğer';
      case ConnectivityResult.none:
      default:
        return 'Çevrimdışı';
    }
  }
}
