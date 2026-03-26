import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/constants/app_constants.dart';

class BannerAdStrip extends StatefulWidget {
  const BannerAdStrip({super.key});

  @override
  State<BannerAdStrip> createState() => _BannerAdStripState();
}

class _BannerAdStripState extends State<BannerAdStrip> {
  BannerAd? _bannerAd;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadBanner() async {
    if (kIsWeb || !Platform.isAndroid || AppConstants.bannerAdUnitId.isEmpty) {
      return;
    }

    final banner = BannerAd(
      adUnitId: AppConstants.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );

    await banner.load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _bannerAd == null) {
      return Container(
        height: 72,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF102218),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          children: [
            Icon(Icons.campaign_outlined, color: Color(0xFF7CFFB2)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Banner slot reserved for Android live ads.',
                style: TextStyle(color: Color(0xFF9CB1AA)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: _bannerAd!.size.height.toDouble() + 20,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF102218),
        borderRadius: BorderRadius.circular(24),
      ),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
