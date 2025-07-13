import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'analytics_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;
  List<BannerAd> _bannerAds = [];
  List<InterstitialAd> _interstitialAds = [];
  List<RewardedAd> _rewardedAds = [];

  // Ad Unit IDs (Replace with your actual ad unit IDs)
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // Test ID
  static const String interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712'; // Test ID
  static const String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917'; // Test ID

  // Ad placement types
  static const String adTypeBanner = 'banner';
  static const String adTypeInterstitial = 'interstitial';
  static const String adTypeRewarded = 'rewarded';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('Ad service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing ad service: $e');
    }
  }

  // Create and load banner ad
  Future<BannerAd?> createBannerAd({
    AdSize size = AdSize.banner,
    String? adUnitId,
  }) async {
    if (!_isInitialized) return null;

    try {
      final BannerAd bannerAd = BannerAd(
        adUnitId: adUnitId ?? bannerAdUnitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('Banner ad loaded successfully');
            _trackAdViewed(adUnitId ?? bannerAdUnitId, adTypeBanner);
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner ad failed to load: $error');
            ad.dispose();
          },
          onAdClicked: (ad) {
            debugPrint('Banner ad clicked');
            _trackAdClicked(adUnitId ?? bannerAdUnitId, adTypeBanner);
          },
        ),
      );

      await bannerAd.load();
      _bannerAds.add(bannerAd);
      return bannerAd;
    } catch (e) {
      debugPrint('Error creating banner ad: $e');
      return null;
    }
  }

  // Create and load interstitial ad
  Future<InterstitialAd?> createInterstitialAd({
    String? adUnitId,
  }) async {
    if (!_isInitialized) return null;

    try {
      InterstitialAd? interstitialAd;
      await InterstitialAd.load(
        adUnitId: adUnitId ?? interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Interstitial ad loaded successfully');
            interstitialAd = ad;
            _interstitialAds.add(ad);
            _trackAdViewed(adUnitId ?? interstitialAdUnitId, adTypeInterstitial);

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('Interstitial ad dismissed');
                ad.dispose();
                _interstitialAds.remove(ad);
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('Interstitial ad failed to show: $error');
                ad.dispose();
                _interstitialAds.remove(ad);
              },
              onAdClicked: (ad) {
                debugPrint('Interstitial ad clicked');
                _trackAdClicked(adUnitId ?? interstitialAdUnitId, adTypeInterstitial);
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial ad failed to load: $error');
          },
        ),
      );

      return interstitialAd;
    } catch (e) {
      debugPrint('Error creating interstitial ad: $e');
      return null;
    }
  }

  // Create and load rewarded ad
  Future<RewardedAd?> createRewardedAd({
    String? adUnitId,
  }) async {
    if (!_isInitialized) return null;

    try {
      RewardedAd? rewardedAd;
      await RewardedAd.load(
        adUnitId: adUnitId ?? rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Rewarded ad loaded successfully');
            rewardedAd = ad;
            _rewardedAds.add(ad);
            _trackAdViewed(adUnitId ?? rewardedAdUnitId, adTypeRewarded);

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('Rewarded ad dismissed');
                ad.dispose();
                _rewardedAds.remove(ad);
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('Rewarded ad failed to show: $error');
                ad.dispose();
                _rewardedAds.remove(ad);
              },
              onAdClicked: (ad) {
                debugPrint('Rewarded ad clicked');
                _trackAdClicked(adUnitId ?? rewardedAdUnitId, adTypeRewarded);
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('Rewarded ad failed to load: $error');
          },
        ),
      );

      return rewardedAd;
    } catch (e) {
      debugPrint('Error creating rewarded ad: $e');
      return null;
    }
  }

  // Show interstitial ad
  Future<bool> showInterstitialAd() async {
    if (_interstitialAds.isEmpty) {
      await createInterstitialAd();
    }

    if (_interstitialAds.isNotEmpty) {
      await _interstitialAds.first.show();
      return true;
    }

    return false;
  }

  // Show rewarded ad
  Future<bool> showRewardedAd({
    required Function() onRewarded,
  }) async {
    if (_rewardedAds.isEmpty) {
      await createRewardedAd();
    }

    if (_rewardedAds.isNotEmpty) {
      final ad = _rewardedAds.first;
      ad.show(onUserEarnedReward: (ad, reward) {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        onRewarded();
      });
      return true;
    }

    return false;
  }

  // Check if user should see ads (based on subscription)
  Future<bool> shouldShowAds() async {
    // This would typically check user subscription status
    // For now, we'll return true to show ads
    return true;
  }

  // Get ad placement strategy
  Map<String, List<String>> getAdPlacementStrategy() {
    return {
      'home_screen': [adTypeBanner],
      'property_list': [adTypeBanner],
      'property_detail': [adTypeBanner],
      'search_results': [adTypeBanner],
      'after_purchase_request': [adTypeInterstitial],
      'after_payment': [adTypeInterstitial],
      'reward_for_contact': [adTypeRewarded],
    };
  }

  // Track ad view
  void _trackAdViewed(String adUnitId, String adType) {
    AnalyticsService().trackAdViewed(
      adUnitId: adUnitId,
      adType: adType,
    );
  }

  // Track ad click
  void _trackAdClicked(String adUnitId, String adType) {
    AnalyticsService().trackAdClicked(
      adUnitId: adUnitId,
      adType: adType,
    );
  }

  // Dispose all ads
  void dispose() {
    for (final ad in _bannerAds) {
      ad.dispose();
    }
    for (final ad in _interstitialAds) {
      ad.dispose();
    }
    for (final ad in _rewardedAds) {
      ad.dispose();
    }

    _bannerAds.clear();
    _interstitialAds.clear();
    _rewardedAds.clear();
  }

  // Get ad revenue statistics
  Future<Map<String, dynamic>> getAdRevenueStats() async {
    // This would typically fetch data from Google AdMob API
    // For now, we'll return mock data
    return {
      'total_revenue': 0.0,
      'banner_revenue': 0.0,
      'interstitial_revenue': 0.0,
      'rewarded_revenue': 0.0,
      'impressions': 0,
      'clicks': 0,
      'ctr': 0.0,
    };
  }

  // Configure ad targeting
  Future<void> configureAdTargeting({
    String? location,
    int? age,
    String? gender,
    List<String>? interests,
  }) async {
    if (!_isInitialized) return;

    try {
      // Configure ad targeting parameters
      // This would typically set user targeting data
      debugPrint('Ad targeting configured');
    } catch (e) {
      debugPrint('Error configuring ad targeting: $e');
    }
  }

  // Test ad loading
  Future<void> testAdLoading() async {
    debugPrint('Testing ad loading...');
    
    await createBannerAd();
    await createInterstitialAd();
    await createRewardedAd();
    
    debugPrint('Ad loading test completed');
  }
} 