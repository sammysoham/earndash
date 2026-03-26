import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        return web;
    }
  }

  // Replace these placeholders with your real Firebase project values.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'EARNDASH_WEB_API_KEY',
    appId: '1:000000000000:web:earndash',
    messagingSenderId: '000000000000',
    projectId: 'earndash-demo',
    authDomain: 'earndash-demo.firebaseapp.com',
    storageBucket: 'earndash-demo.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'EARNDASH_ANDROID_API_KEY',
    appId: '1:000000000000:android:earndash',
    messagingSenderId: '000000000000',
    projectId: 'earndash-demo',
    storageBucket: 'earndash-demo.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'EARNDASH_IOS_API_KEY',
    appId: '1:000000000000:ios:earndash',
    messagingSenderId: '000000000000',
    projectId: 'earndash-demo',
    storageBucket: 'earndash-demo.appspot.com',
    iosBundleId: 'com.earndash.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'EARNDASH_MACOS_API_KEY',
    appId: '1:000000000000:macos:earndash',
    messagingSenderId: '000000000000',
    projectId: 'earndash-demo',
    storageBucket: 'earndash-demo.appspot.com',
    iosBundleId: 'com.earndash.app',
  );
}
