// ignore_for_file: public_member_api_docs, constant_identifier_names, avoid_web_libraries_in_flutter

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCB7gIfICrZd1mNHXrRRYAS519L4-BgjBM",
    authDomain: "e-library-dd9d4.firebaseapp.com",
    projectId: "e-library-dd9d4",
    storageBucket: "e-library-dd9d4.appspot.com",
    messagingSenderId: "903211584315",
    appId: "1:903211584315:web:3084edc4ed51154b05051e",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyBriyZTG1q9CnJRxynmcKbPhvdmeljCIWk",
    appId: "1:903211584315:android:df644ce5c57abd0405051e",
    messagingSenderId: "903211584315",
    projectId: "e-library-dd9d4",
    storageBucket: "e-library-dd9d4.firebasestorage.app",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyBriyZTG1q9CnJRxynmcKbPhvdmeljCIWk",
    appId: "1:903211584315:ios:df644ce5c57abd0405051e",
    messagingSenderId: "903211584315",
    projectId: "e-library-dd9d4",
    storageBucket: "e-library-dd9d4.firebasestorage.app",
    iosBundleId: "com.example.eLibrary",
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: "AIzaSyBriyZTG1q9CnJRxynmcKbPhvdmeljCIWk",
    appId: "1:903211584315:ios:df644ce5c57abd0405051e",
    messagingSenderId: "903211584315",
    projectId: "e-library-dd9d4",
    storageBucket: "e-library-dd9d4.firebasestorage.app",
    iosBundleId: "com.example.eLibrary",
  );
}
