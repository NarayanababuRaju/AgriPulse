// File: lib/firebase_options.dart
// This is a MOCK file for development purposes.
// Run `flutterfire configure` to generate the real file with actual API keys.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // Unsupported platforms for mock
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB_rvzBUHalAf24VIbPmVXqSWlPF398Lc4',
    appId: '1:472219254957:web:ac271c16662c3d40b24624',
    messagingSenderId: '472219254957',
    projectId: 'agri-pulse-firebase',
    authDomain: 'agri-pulse-firebase.firebaseapp.com',
    storageBucket: 'agri-pulse-firebase.firebasestorage.app',
    measurementId: 'G-RD3810L2RT',
  );

}