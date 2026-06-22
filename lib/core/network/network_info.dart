import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Abstraction over connectivity so repositories can decide between live calls
/// and the offline queue, and so the session layer can sync on reconnect.
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Future<bool> get isConnected async {
    // connectivity_plus is unreliable on web (it can report `none` while the
    // browser is online) and the offline queue isn't meaningful in a browser.
    // Treat web as always connected so real server/CORS errors surface as
    // server errors instead of a misleading "no internet" screen.
    if (kIsWeb) return true;
    return _isOnline(await _connectivity.checkConnectivity());
  }

  @override
  Stream<bool> get onConnectivityChanged => kIsWeb
      ? const Stream<bool>.empty()
      : _connectivity.onConnectivityChanged.map(_isOnline);
}
