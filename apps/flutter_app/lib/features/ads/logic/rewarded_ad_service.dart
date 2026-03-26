import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../auth/logic/auth_controller.dart';

final rewardedAdServiceProvider = Provider<RewardedAdService>(
  (ref) => RewardedAdService(ref.read(apiClientProvider)),
);

class RewardedAdService {
  RewardedAdService(this._apiClient);

  final ApiClient _apiClient;
  final Random _random = Random();

  Future<int> showRewardedAd() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS) ||
        AppConstants.rewardedAdUnitId.isEmpty) {
      return _creditFallbackReward();
    }

    try {
      return await _showNativeRewardedAd();
    } catch (_) {
      return _creditFallbackReward();
    }
  }

  Future<int> showRewardedInterstitialAd() async {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        AppConstants.rewardedInterstitialAdUnitId.isEmpty) {
      return _creditFallbackReward(minCoins: 12, maxCoins: 30);
    }

    try {
      return await _showNativeRewardedInterstitialAd();
    } catch (_) {
      return _creditFallbackReward(minCoins: 12, maxCoins: 30);
    }
  }

  Future<int> _showNativeRewardedAd() async {
    final completer = Completer<int>();
    RewardedAd? rewardedAd;
    var rewardGranted = false;

    await RewardedAd.load(
      adUnitId: AppConstants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          rewardedAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!rewardGranted && !completer.isCompleted) {
                completer.completeError(Exception('Ad closed before reward'));
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!completer.isCompleted) {
                completer.completeError(error);
              }
            },
          );

          ad.show(
            onUserEarnedReward: (_, rewardItem) async {
              rewardGranted = true;
              final reward = rewardItem.amount.round() > 0
                  ? rewardItem.amount.round()
                  : 10;
              final confirmed = await _creditReward(
                adUnitId: AppConstants.rewardedAdUnitId,
                coins: reward,
              );
              if (!completer.isCompleted) {
                completer.complete(confirmed);
              }
            },
          );
        },
        onAdFailedToLoad: (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
      ),
    );

    final reward = await completer.future.timeout(const Duration(seconds: 45));
    rewardedAd?.dispose();
    return reward;
  }

  Future<int> _showNativeRewardedInterstitialAd() async {
    final completer = Completer<int>();
    RewardedInterstitialAd? rewardedInterstitialAd;
    var rewardGranted = false;

    await RewardedInterstitialAd.load(
      adUnitId: AppConstants.rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          rewardedInterstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!rewardGranted && !completer.isCompleted) {
                completer.completeError(Exception('Ad closed before reward'));
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!completer.isCompleted) {
                completer.completeError(error);
              }
            },
          );

          ad.show(
            onUserEarnedReward: (_, rewardItem) async {
              rewardGranted = true;
              final reward = rewardItem.amount.round() > 0
                  ? rewardItem.amount.round()
                  : 20;
              final confirmed = await _creditReward(
                adUnitId: AppConstants.rewardedInterstitialAdUnitId,
                coins: reward,
              );
              if (!completer.isCompleted) {
                completer.complete(confirmed);
              }
            },
          );
        },
        onAdFailedToLoad: (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
      ),
    );

    final reward = await completer.future.timeout(const Duration(seconds: 45));
    rewardedInterstitialAd?.dispose();
    return reward;
  }

  Future<int> _creditFallbackReward({
    int minCoins = 5,
    int maxCoins = 20,
  }) async {
    final reward = minCoins + _random.nextInt(maxCoins - minCoins + 1);
    return _creditReward(
      adUnitId: AppConstants.rewardedAdUnitId,
      coins: reward,
    );
  }

  Future<int> _creditReward({
    required String adUnitId,
    required int coins,
  }) {
    return _apiClient.confirmAdReward(
      adUnitId: adUnitId,
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      coins: coins,
    );
  }
}
