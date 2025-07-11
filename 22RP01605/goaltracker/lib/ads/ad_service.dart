import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class AdService {
  static Future<InitializationStatus> initialize() {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      throw UnsupportedError(
        'Google Mobile Ads is not supported on web or Windows',
      );
    }
    return MobileAds.instance.initialize();
  }

  static BannerAd createBannerAd({BannerAdListener? listener}) {
    return BannerAd(
      adUnitId:
          'ca-app-pub-3940256099942544/6300978111', // Test banner ad unit ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: listener ?? const BannerAdListener(),
    );
  }

  static InterstitialAd? _interstitialAd;
  static void loadInterstitialAd(VoidCallback onAdLoaded) {
    InterstitialAd.load(
      adUnitId:
          'ca-app-pub-3940256099942544/1033173712', // Test interstitial ad unit ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          onAdLoaded();
        },
        onAdFailedToLoad: (error) {},
      ),
    );
  }

  static void showInterstitialAd() {
    _interstitialAd?.show();
    _interstitialAd = null;
  }
}

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});
  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  late BannerAd _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = AdService.createBannerAd(
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) return const SizedBox(height: 0);
    return SizedBox(
      height: _bannerAd.size.height.toDouble(),
      width: _bannerAd.size.width.toDouble(),
      child: AdWidget(ad: _bannerAd),
    );
  }
}
