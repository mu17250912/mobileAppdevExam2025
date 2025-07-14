import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  final AnalyticsService _analytics = AnalyticsService();
  bool _isInitialized = false;
  int _interstitialLoadAttempts = 0;
  int _rewardedAdLoadAttempts = 0;
  static const int maxFailedLoadAttempts = 3;

  // Ad unit IDs (replace with your actual AdMob IDs)
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // Test ID
  static const String interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712'; // Test ID
  static const String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917'; // Test ID

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize with a timeout to prevent hanging
      await MobileAds.instance.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('AdService: Mobile Ads initialization timed out');
          throw Exception('Mobile Ads initialization timed out');
        },
      );
      _isInitialized = true;
      print('AdService: Google Mobile Ads initialized successfully');
      
      // Load initial ads with error handling
      try {
        _loadInterstitialAd();
      } catch (e) {
        print('AdService: Failed to load interstitial ad: $e');
      }
      
      try {
        _loadRewardedAd();
      } catch (e) {
        print('AdService: Failed to load rewarded ad: $e');
      }
    } catch (e) {
      print('AdService: Failed to initialize ads: $e');
      // Don't throw the error, just log it and continue
      _isInitialized = false;
    }
  }

  // Banner Ad
  Future<Widget?> loadBannerAd() async {
    if (!_isInitialized) return null;

    try {
      final bannerAd = BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            print('AdService: Banner ad loaded successfully');
            _analytics.trackAdLoaded('banner');
          },
          onAdFailedToLoad: (ad, error) {
            print('AdService: Banner ad failed to load: $error');
            ad.dispose();
          },
          onAdClicked: (ad) {
            print('AdService: Banner ad clicked');
            _analytics.trackAdClick('banner');
          },
        ),
      );

      await bannerAd.load();
      return Container(
        alignment: Alignment.center,
        width: bannerAd.size.width.toDouble(),
        height: bannerAd.size.height.toDouble(),
        child: AdWidget(ad: bannerAd),
      );
    } catch (e) {
      print('AdService: Error loading banner ad: $e');
      return null;
    }
  }

  // Interstitial Ad
  void _loadInterstitialAd() {
    if (_interstitialLoadAttempts >= maxFailedLoadAttempts) {
      print('AdService: Max interstitial load attempts reached');
      return;
    }

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
          print('AdService: Interstitial ad loaded successfully');
          
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('AdService: Interstitial ad failed to show: $error');
              ad.dispose();
              _loadInterstitialAd();
            },
            onAdClicked: (ad) {
              print('AdService: Interstitial ad clicked');
              _analytics.trackAdClick('interstitial');
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('AdService: Interstitial ad failed to load: $error');
          _interstitialLoadAttempts += 1;
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<void> showInterstitialAd() async {
    if (_interstitialAd == null) {
      print('AdService: Interstitial ad not ready');
      return;
    }

    try {
      await _interstitialAd!.show();
      _analytics.trackAdShown('interstitial');
    } catch (e) {
      print('AdService: Error showing interstitial ad: $e');
    }
  }

  // Rewarded Ad
  void _loadRewardedAd() {
    if (_rewardedAdLoadAttempts >= maxFailedLoadAttempts) {
      print('AdService: Max rewarded ad load attempts reached');
      return;
    }

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedAdLoadAttempts = 0;
          print('AdService: Rewarded ad loaded successfully');
          
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('AdService: Rewarded ad failed to show: $error');
              ad.dispose();
              _loadRewardedAd();
            },
            onAdClicked: (ad) {
              print('AdService: Rewarded ad clicked');
              _analytics.trackAdClick('rewarded');
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('AdService: Rewarded ad failed to load: $error');
          _rewardedAdLoadAttempts += 1;
          _rewardedAd = null;
        },
      ),
    );
  }

  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null) {
      print('AdService: Rewarded ad not ready');
      return false;
    }

    try {
      bool rewardEarned = false;
      
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          rewardEarned = true;
          print('AdService: User earned reward: ${reward.amount} ${reward.type}');
          _analytics.trackAdRewardEarned(reward.amount.toString());
        },
      );
      
      _analytics.trackAdShown('rewarded');
      return rewardEarned;
    } catch (e) {
      print('AdService: Error showing rewarded ad: $e');
      return false;
    }
  }

  // Check if user should see ads
  Future<bool> shouldShowAds() async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool('isPremium') ?? false;
    return !isPremium;
  }

  // Get ad frequency based on user activity
  Future<int> getAdFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    final adShownCount = prefs.getInt('ad_shown_count') ?? 0;
    
    // Show ads every 3-5 actions for free users
    if (adShownCount < 10) return 3;
    if (adShownCount < 50) return 4;
    return 5;
  }

  // Track ad shown
  Future<void> trackAdShown() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt('ad_shown_count') ?? 0;
    await prefs.setInt('ad_shown_count', currentCount + 1);
  }

  // Reset ad counter (for premium users)
  Future<void> resetAdCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ad_shown_count', 0);
  }

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
} 