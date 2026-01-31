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
    apiKey: 'mock-api-key',
    appId: 'mock-app-id',
    messagingSenderId: 'mock-sender-id',
    projectId: 'mock-project-id',
    authDomain: 'mock-project-id.firebaseapp.com',
    storageBucket: 'mock-project-id.appspot.com',
  );
}
