import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/constants/app_constants.dart';

final interstitialAdServiceProvider = Provider<InterstitialAdService>(
  (ref) => InterstitialAdService(),
);

class InterstitialAdService {
  InterstitialAd? _interstitialAd;
  bool _loading = false;
  int _navigationCount = 0;

  Future<void> maybeShowAfterNavigation() async {
    if (!_isSupported) {
      return;
    }

    _navigationCount += 1;
    if (_navigationCount < 3) {
      await _ensureLoaded();
      return;
    }

    _navigationCount = 0;
    await _showOrPreload();
  }

  Future<void> _showOrPreload() async {
    if (_interstitialAd == null) {
      await _ensureLoaded();
    }

    final ad = _interstitialAd;
    if (ad == null) {
      return;
    }

    _interstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ensureLoaded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _ensureLoaded();
      },
    );
    ad.show();
  }

  Future<void> _ensureLoaded() async {
    if (!_isSupported || _loading || _interstitialAd != null) {
      return;
    }

    _loading = true;
    await InterstitialAd.load(
      adUnitId: AppConstants.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _loading = false;
        },
      ),
    );
  }

  bool get _isSupported =>
      !kIsWeb &&
      Platform.isAndroid &&
      AppConstants.interstitialAdUnitId.isNotEmpty;
}
