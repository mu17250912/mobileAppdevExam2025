import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import 'local_storage_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Ad instances
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  
  // Ad states
  bool _isBannerAdReady = false;
  bool _isInterstitialAdReady = false;
  bool _isRewardedAdReady = false;
  
  // Ad unit IDs
  static const String _androidBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _iosBannerId = 'ca-app-pub-3940256099942544/2934735716';
  static const String _androidInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _iosInterstitialId = 'ca-app-pub-3940256099942544/4411468910';
  static const String _androidRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _iosRewardedId = 'ca-app-pub-3940256099942544/1712485313';

  // Getters
  bool get isBannerAdReady => _isBannerAdReady && _bannerAd != null;
  bool get isInterstitialAdReady => _isInterstitialAdReady && _interstitialAd != null;
  bool get isRewardedAdReady => _isRewardedAdReady && _rewardedAd != null;
  BannerAd? get bannerAd => _bannerAd;
  InterstitialAd? get interstitialAd => _interstitialAd;
  RewardedAd? get rewardedAd => _rewardedAd;

  // Initialize ads
  Future<void> initializeAds() async {
    if (kIsWeb) return;
    
    await MobileAds.instance.initialize();
    await _loadBannerAd();
    await _loadInterstitialAd();
    await _loadRewardedAd();
  }

  // Load banner ad
  Future<void> _loadBannerAd() async {
    if (kIsWeb) return;
    
    String adUnitId = Platform.isAndroid ? _androidBannerId : _iosBannerId;
    
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _isBannerAdReady = true;
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isBannerAdReady = false;
        },
      ),
    );
    
    await _bannerAd!.load();
  }

  // Load interstitial ad
  Future<void> _loadInterstitialAd() async {
    if (kIsWeb) return;
    
    String adUnitId = Platform.isAndroid ? _androidInterstitialId : _iosInterstitialId;
    
    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdReady = false;
              _loadInterstitialAd(); // Load next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isInterstitialAdReady = false;
              _loadInterstitialAd(); // Load next ad
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  // Load rewarded ad
  Future<void> _loadRewardedAd() async {
    if (kIsWeb) return;
    
    String adUnitId = Platform.isAndroid ? _androidRewardedId : _iosRewardedId;
    
    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isRewardedAdReady = false;
              _loadRewardedAd(); // Load next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isRewardedAdReady = false;
              _loadRewardedAd(); // Load next ad
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdReady = false;
        },
      ),
    );
  }

  // Show interstitial ad
  Future<void> showInterstitialAd() async {
    if (kIsWeb) return;
    
    // Check if user is premium
    bool isPremium = await LocalStorageService.isPremium();
    if (isPremium) return; // Don't show ads for premium users
    
    if (_isInterstitialAdReady && _interstitialAd != null) {
      await _interstitialAd!.show();
    }
  }

  // Show rewarded ad
  Future<bool> showRewardedAd() async {
    if (kIsWeb) return false;
    
    // Check if user is premium
    bool isPremium = await LocalStorageService.isPremium();
    if (isPremium) return true; // Premium users get rewards without watching ads
    
    if (_isRewardedAdReady && _rewardedAd != null) {
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          // Handle reward
          print('User earned reward: ${reward.amount} ${reward.type}');
        },
      );
      return true;
    }
    return false;
  }

  // Check if ads should be shown (based on premium status)
  Future<bool> shouldShowAds() async {
    if (kIsWeb) return false;
    return !(await LocalStorageService.isPremium());
  }

  // Reload ads
  Future<void> reloadAds() async {
    await _loadBannerAd();
    await _loadInterstitialAd();
    await _loadRewardedAd();
  }

  // Dispose ads
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
} 