import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../providers/auth_provider.dart';
import '../services/ads_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAd();
    });
  }

  Future<void> _loadAd() async {
    if (_isAdLoading) return;
    
    setState(() {
      _isAdLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      
      // Only show ads for free users
      if (authProvider.userModel?.isPremium == true) {
        setState(() {
          _isAdLoading = false;
        });
        return;
      }

      _bannerAd = await AdsService().loadBannerAd();
      if (_bannerAd != null && mounted) {
        setState(() {
          _isAdLoaded = true;
          _isAdLoading = false;
        });
      } else {
        setState(() {
          _isAdLoading = false;
        });
      }
    } catch (e) {
      print('Error loading banner ad: $e');
      if (mounted) {
        setState(() {
          _isAdLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Don't show ads for premium users
        if (authProvider.userModel?.isPremium == true) {
          return const SizedBox.shrink();
        }

        // Show ad for free users on mobile
        if (_isAdLoaded && _bannerAd != null && !kIsWeb) {
          return Container(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          );
        }

        // Show placeholder for web users or when ad fails to load
        return Container(
          width: 320,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  kIsWeb ? Icons.computer : Icons.mobile_friendly,
                  color: Colors.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  kIsWeb 
                    ? 'Ad Space (Web)' 
                    : _isAdLoading 
                      ? 'Ad Loading...' 
                      : 'Ad not available',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 