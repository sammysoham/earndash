import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appNickname = 'EarnDash';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://earndash-api.onrender.com/api',
  );
  static const int coinsPerDollar = 10000;
  static const int minWithdrawalCoins = 50000;
  static const int newUserDailyWithdrawalCapCoins = 200000;
  static const int pendingRewardHoldDays = 14;
  static const String authTokenKey = 'earndash_auth_token';
  static const bool useMockApi = bool.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: false,
  );
  static const String adMobAppId = 'ca-app-pub-5697965850070399~4476598605';
  static const String adMobAndroidRewardedUnitId =
      'ca-app-pub-5697965850070399/3076854626';
  static const String adMobAndroidBannerUnitId =
      'ca-app-pub-5697965850070399/7799700280';
  static const String adMobAndroidRewardedInterstitialUnitId =
      'ca-app-pub-5697965850070399/7206605661';
  static const String adMobAndroidInterstitialUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_INTERSTITIAL_ID',
    defaultValue: 'ca-app-pub-5697965850070399/1151933820',
  );
  static const String adMobAndroidNativeAdvancedUnitId =
      'ca-app-pub-5697965850070399/6197841980';
  static const String adMobIosRewardedUnitId = '';
  static const bool firebaseAuthEnabled = true;
  static const String firebaseGoogleWebClientId =
      '889132772936-bcfo6pee8omn1dju6gqaeot4d4hbncnd.apps.googleusercontent.com';

  static String get rewardedAdUnitId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return adMobIosRewardedUnitId;
      case TargetPlatform.android:
      default:
        return adMobAndroidRewardedUnitId;
    }
  }

  static String get bannerAdUnitId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return adMobAndroidBannerUnitId;
      default:
        return '';
    }
  }

  static String get rewardedInterstitialAdUnitId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return adMobAndroidRewardedInterstitialUnitId;
      default:
        return '';
    }
  }

  static String get interstitialAdUnitId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return adMobAndroidInterstitialUnitId;
      default:
        return '';
    }
  }
}
