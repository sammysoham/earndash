import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import 'firebase_options.dart';

class FirebaseBootstrap {
  static Future<void> initializeIfConfigured() async {
    if (!AppConstants.firebaseAuthEnabled) {
      return;
    }

    if (Firebase.apps.isNotEmpty) {
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      await Firebase.initializeApp();
      return;
    }

    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
}
