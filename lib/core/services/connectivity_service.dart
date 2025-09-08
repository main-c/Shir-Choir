import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  /// Vérifie si l'appareil est connecté à Internet
  Future<bool> hasInternetConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result == ConnectivityResult.mobile || 
           result == ConnectivityResult.wifi ||
           result == ConnectivityResult.ethernet;
  }

  /// Stream des changements de connectivité
  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((result) {
      return result == ConnectivityResult.mobile || 
             result == ConnectivityResult.wifi ||
             result == ConnectivityResult.ethernet;
    });
  }
}