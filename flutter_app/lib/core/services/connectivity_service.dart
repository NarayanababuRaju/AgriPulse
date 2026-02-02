import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((results) {
       // connectivity_plus 6.0+ returns List<ConnectivityResult>
       // We consider it connected if it's NOT just [none]
       return !results.contains(ConnectivityResult.none);
    });
  }
  
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }
}

final connectivityProvider = StreamProvider<bool>((ref) {
  return ConnectivityService().connectivityStream;
});
