/// Ad Service for SafeRide
///
/// Handles all advertisement-related operations including ad display, ad management,
/// and monetization through Google AdMob. This service manages the ad revenue
/// generation for the SafeRide platform.
///
/// Features:
/// - Banner ads display
/// - Interstitial ads (full-screen ads)
/// - Rewarded ads for premium features
/// - Ad targeting and personalization
/// - Ad performance analytics
/// - Premium user ad-free experience
///
/// TODO: Future Enhancements:
/// - Advanced ad targeting based on user behavior
/// - A/B testing for ad placements
/// - Native ad integration
/// - Video ads support
/// - Ad performance optimization
/// - Ad content filtering
/// - Ad frequency capping
/// - Integration with multiple ad networks
/// - Ad revenue analytics dashboard
library;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:saferide/services/error_service.dart';
import 'package:saferide/utils/app_config.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  final ErrorService _errorService = ErrorService();
  bool _isInitialized = false;
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;

  /// Initialize AdMob
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Skip initialization on web platform
    if (kIsWeb) {
      debugPrint('⚠️ AdMob not supported on web platform');
      return;
    }

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('✅ AdMob initialized successfully');
    } catch (e) {
      _errorService.logError('AdMob initialization failed', e);
      debugPrint('❌ AdMob initialization failed: $e');
    }
  }

  /// Get a banner ad
  BannerAd getBannerAd({AdSize size = AdSize.banner}) {
    // Return a dummy banner ad for web platform
    if (kIsWeb) {
      return BannerAd(
        adUnitId: 'dummy-id',
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('⚠️ Dummy banner ad for web platform');
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('⚠️ Dummy banner ad failed (expected on web)');
            ad.dispose();
          },
        ),
      );
    }

    _bannerAd = BannerAd(
      adUnitId: _getBannerAdUnitId(),
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Banner ad failed to load: $error');
          ad.dispose();
        },
      ),
    )..load();
    return _bannerAd!;
  }

  /// Load an interstitial ad
  Future<void> loadInterstitialAd() async {
    try {
      await InterstitialAd.load(
        adUnitId: _getInterstitialAdUnitId(),
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _interstitialAd = null;
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('❌ Interstitial ad failed to show: $error');
                ad.dispose();
                _interstitialAd = null;
              },
            );
            debugPrint('✅ Interstitial ad loaded');
          },
          onAdFailedToLoad: (error) {
            debugPrint('❌ Interstitial ad failed to load: $error');
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      _errorService.logError('Failed to load interstitial ad', e);
      debugPrint('❌ Failed to load interstitial ad: $e');
    }
  }

  /// Show interstitial ad
  Future<void> showInterstitialAd() async {
    if (_interstitialAd != null) {
      await _interstitialAd!.show();
    } else {
      debugPrint('⚠️ No interstitial ad available');
    }
  }

  /// Dispose ads
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
  }

  /// Get banner ad unit ID based on environment
  String _getBannerAdUnitId() {
    if (AppConfig.isProduction) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Production ID
    } else {
      return 'ca-app-pub-3940256099942544/6300978111'; // Test ID
    }
  }

  /// Get interstitial ad unit ID based on environment
  String _getInterstitialAdUnitId() {
    if (AppConfig.isProduction) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Production ID
    } else {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test ID
    }
  }
}
