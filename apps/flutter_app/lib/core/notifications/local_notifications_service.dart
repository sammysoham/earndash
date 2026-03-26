import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationsService {
  LocalNotificationsService._();

  static final LocalNotificationsService instance = LocalNotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> showRewardEarned({
    required int coins,
    required String title,
    required String body,
  }) async {
    await _show(
      id: 1001,
      title: title,
      body: '$body +$coins coins',
      channelId: 'earnings',
      channelName: 'Earnings',
    );
  }

  Future<void> showMoveUpdate(String body) async {
    await _show(
      id: 1002,
      title: 'Move & Earn update',
      body: body,
      channelId: 'fitness',
      channelName: 'Fitness',
    );
  }

  Future<void> showWithdrawalSubmitted(int coins) async {
    await _show(
      id: 1003,
      title: 'Withdrawal requested',
      body: '$coins coins sent for admin review.',
      channelId: 'wallet',
      channelName: 'Wallet',
    );
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
  }) async {
    if (kIsWeb) {
      return;
    }
    await initialize();
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
