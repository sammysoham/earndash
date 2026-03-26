import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app/app.dart';
import 'core/auth/firebase_bootstrap.dart';
import 'core/notifications/local_notifications_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initializeIfConfigured();
  await LocalNotificationsService.instance.initialize();
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }
  runApp(const ProviderScope(child: EarnDashApp()));
}
