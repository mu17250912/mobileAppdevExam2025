import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  bool _isPremium = false;
  BannerAd? _bannerAd;
  bool _adLoaded = false;
  bool _adLoading = false;
  String? _adError;

  @override
  void initState() {
    super.initState();
    _checkPremiumAndLoadAd();
  }

  Future<void> _checkPremiumAndLoadAd() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('AdBanner: No user logged in');
        return;
      }
      
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final isPremium = doc.data()?['premium'] ?? false;
      
      print('AdBanner: User premium status: $isPremium');
      
      if (!mounted) return;
      setState(() {
        _isPremium = isPremium;
      });
      
      if (!isPremium) {
        print('AdBanner: Loading ad for non-premium user');
        setState(() {
          _adLoading = true;
          _adError = null;
        });
        
        final ad = BannerAd(
          adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Official test ad unit
          size: AdSize.banner,
          request: const AdRequest(),
          listener: BannerAdListener(
            onAdLoaded: (ad) {
              print('AdBanner: Ad loaded successfully');
              if (mounted) {
                setState(() {
                  _adLoaded = true;
                  _adLoading = false;
                  _adError = null;
                });
              }
            },
            onAdFailedToLoad: (ad, error) {
              print('AdBanner: Ad failed to load: ${error.message}');
              if (mounted) {
                setState(() {
                  _adLoaded = false;
                  _adLoading = false;
                  _adError = error.message;
                });
              }
              ad.dispose();
            },
          ),
        );
        
        await ad.load();
        
        if (!mounted) {
          ad.dispose();
          return;
        }
        
        setState(() {
          _bannerAd = ad;
        });
      }
    } catch (e) {
      print('AdBanner: Error loading ad: $e');
      if (mounted) {
        setState(() {
          _adLoading = false;
          _adError = e.toString();
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
    // Don't show anything if user is premium
    if (_isPremium) {
      return const SizedBox.shrink();
    }
    
    // Show loading indicator while ad is loading
    if (_adLoading) {
      return Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Loading Ad...',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    
    // Show error message if ad failed to load
    if (_adError != null) {
      return Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Center(
          child: Text(
            'Ad not available',
            style: TextStyle(color: Colors.red[700]),
          ),
        ),
      );
    }
    
    // Show ad if loaded successfully
    if (_bannerAd != null && _adLoaded) {
      return Container(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    
    // Fallback: show a placeholder
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'Advertisement',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
} 