import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../auth/logic/auth_controller.dart';

final rewardedAdCooldownProvider = StateProvider<DateTime?>((ref) => null);
final rewardedAdClockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  while (true) {
    await Future<void>.delayed(const Duration(seconds: 1));
    yield DateTime.now();
  }
});

final rewardedAdServiceProvider = Provider<RewardedAdService>(
  (ref) => RewardedAdService(ref),
);

class RewardedAdService {
  RewardedAdService(this._ref) : _apiClient = _ref.read(apiClientProvider);

  final Ref _ref;
  final ApiClient _apiClient;

  int secondsUntilNextAd() {
    final endsAt = _ref.read(rewardedAdCooldownProvider);
    if (endsAt == null) {
      return 0;
    }

    final remaining = endsAt.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  Future<int> showRewardedAd() async {
    final cooldown = secondsUntilNextAd();
    if (cooldown > 0) {
      throw Exception(
          'Please wait ${cooldown}s before watching another rewarded ad.');
    }

    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS) ||
        AppConstants.rewardedAdUnitId.isEmpty) {
      throw Exception(
          'Rewarded ads are not available on this device right now.');
    }

    return _showNativeRewardedAd();
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
                completer.completeError(
                    Exception('Ad closed before the reward finished.'));
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!completer.isCompleted) {
                completer.completeError(
                  Exception(
                      'This ad could not be shown right now. Please try again shortly.'),
                );
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
            final message = switch (error.code) {
              3 => 'No ad is available right now. Please try again in a bit.',
              2 =>
                'Network issue while loading the ad. Check your connection and try again.',
              1 => 'Ad request was invalid. Please try again shortly.',
              _ => 'Rewarded ad failed to load right now. Please try again.',
            };
            completer.completeError(Exception(message));
          }
        },
      ),
    );

    final reward = await completer.future.timeout(const Duration(seconds: 45));
    rewardedAd?.dispose();
    _ref.read(rewardedAdCooldownProvider.notifier).state = DateTime.now().add(
      const Duration(seconds: 30),
    );
    return reward;
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
