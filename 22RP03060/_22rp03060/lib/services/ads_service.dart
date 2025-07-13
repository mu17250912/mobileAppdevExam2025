import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class AdsService {
  static final AdsService _instance = AdsService._internal();
  factory AdsService() => _instance;
  AdsService._internal();

  bool _isInitialized = false;
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;

  // Test ad unit IDs - replace with real ones for production
  static const String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Only initialize on mobile platforms
      if (!kIsWeb) {
        await MobileAds.instance.initialize();
      }
      _isInitialized = true;
      print('Ads service initialized successfully');
    } catch (e) {
      print('Error initializing ads service: $e');
      // Mark as initialized even if it fails to prevent repeated attempts
      _isInitialized = true;
    }
  }

  String get bannerAdUnitId {
    if (kIsWeb) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Web test ad
    } else {
      return _bannerAdUnitId;
    }
  }

  String get interstitialAdUnitId {
    if (kIsWeb) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Web test ad
    } else {
      return _interstitialAdUnitId;
    }
  }

  Future<BannerAd?> loadBannerAd() async {
    if (!_isInitialized) await initialize();

    // Return null for web platform since ads don't work on web
    if (kIsWeb) {
      print('Banner ads not supported on web platform');
      return null;
    }

    try {
      _bannerAd = BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            print('Banner ad loaded successfully');
          },
          onAdFailedToLoad: (ad, error) {
            print('Banner ad failed to load: $error');
            ad.dispose();
          },
        ),
      );

      await _bannerAd!.load();
      return _bannerAd;
    } catch (e) {
      print('Error loading banner ad: $e');
      return null;
    }
  }

  Future<InterstitialAd?> loadInterstitialAd() async {
    if (!_isInitialized) await initialize();

    // Return null for web platform since ads don't work on web
    if (kIsWeb) {
      print('Interstitial ads not supported on web platform');
      return null;
    }

    try {
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            print('Interstitial ad loaded successfully');
          },
          onAdFailedToLoad: (error) {
            print('Interstitial ad failed to load: $error');
            _interstitialAd = null;
          },
        ),
      );
      return _interstitialAd;
    } catch (e) {
      print('Error loading interstitial ad: $e');
      return null;
    }
  }

  Future<void> showInterstitialAd() async {
    if (_interstitialAd != null) {
      await _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      print('No interstitial ad available to show');
    }
  }

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
  }
} 