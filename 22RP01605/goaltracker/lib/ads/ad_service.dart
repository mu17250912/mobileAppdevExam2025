import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class AdService {
  static Future<InitializationStatus> initialize() async {
    try {
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
        throw UnsupportedError(
          'Google Mobile Ads is not supported on web or Windows',
        );
      }
      return await MobileAds.instance.initialize();
    } catch (e) {
      print('Ad service initialization error: $e');
      rethrow;
    }
  }

  static BannerAd createBannerAd({BannerAdListener? listener}) {
    return BannerAd(
      adUnitId: kDebugMode
          ? 'ca-app-pub-3940256099942544/6300978111' // Test banner ad unit ID
          : 'ca-app-pub-3940256099942544/6300978111', // Replace with your production ad unit ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: listener ?? const BannerAdListener(),
    );
  }

  static InterstitialAd? _interstitialAd;

  static void loadInterstitialAd(VoidCallback onAdLoaded) {
    try {
      InterstitialAd.load(
        adUnitId: kDebugMode
            ? 'ca-app-pub-3940256099942544/1033173712' // Test interstitial ad unit ID
            : 'ca-app-pub-3940256099942544/1033173712', // Replace with your production ad unit ID
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            onAdLoaded();
          },
          onAdFailedToLoad: (error) {
            print('Interstitial ad failed to load: $error');
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      print('Error loading interstitial ad: $e');
    }
  }

  static void showInterstitialAd() {
    try {
      _interstitialAd?.show();
      _interstitialAd = null;
    } catch (e) {
      print('Error showing interstitial ad: $e');
    }
  }
}

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});
  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    try {
      _bannerAd = AdService.createBannerAd(
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            setState(() {
              _isLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            print('Banner ad failed to load: $error');
            ad.dispose();
          },
        ),
      );
      _bannerAd?.load();
    } catch (e) {
      print('Error creating banner ad: $e');
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox(height: 50);
    }
    return SizedBox(
      height: _bannerAd!.size.height.toDouble(),
      width: _bannerAd!.size.width.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
