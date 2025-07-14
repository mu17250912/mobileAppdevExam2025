import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/premium_provider.dart';
import '../services/ad_service.dart';

class AdBannerWidget extends StatefulWidget {
  final double? height;
  final EdgeInsets? margin;
  final bool showIfPremium;

  const AdBannerWidget({
    Key? key,
    this.height,
    this.margin,
    this.showIfPremium = false,
  }) : super(key: key);

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  final AdService _adService = AdService();
  Widget? _adWidget;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final shouldShowAds = await _adService.shouldShowAds();
    
    if (!shouldShowAds && !widget.showIfPremium) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final adWidget = await _adService.loadBannerAd();
    
    if (mounted) {
      setState(() {
        _adWidget = adWidget;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumProvider>(
      builder: (context, premiumProvider, child) {
        // Don't show ads for premium users unless explicitly requested
        if (premiumProvider.isPremium && !widget.showIfPremium) {
          return const SizedBox.shrink();
        }

        if (_isLoading) {
          return Container(
            height: widget.height ?? 50,
            margin: widget.margin,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (_adWidget == null) {
          return const SizedBox.shrink();
        }

        return Container(
          height: widget.height,
          margin: widget.margin,
          child: _adWidget,
        );
      },
    );
  }
}

class InterstitialAdManager {
  static final AdService _adService = AdService();
  static int _actionCount = 0;

  static Future<void> showAdIfNeeded() async {
    final shouldShowAds = await _adService.shouldShowAds();
    if (!shouldShowAds) return;

    _actionCount++;
    final frequency = await _adService.getAdFrequency();
    
    if (_actionCount >= frequency) {
      await _adService.showInterstitialAd();
      await _adService.trackAdShown();
      _actionCount = 0;
    }
  }

  static Future<bool> showRewardedAd() async {
    final shouldShowAds = await _adService.shouldShowAds();
    if (!shouldShowAds) return true; // Premium users get reward for free

    return await _adService.showRewardedAd();
  }

  static void resetCounter() {
    _actionCount = 0;
  }
} 