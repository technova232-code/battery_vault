import 'package:flutter/foundation.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class AdsService {
  // Replace with your Unity Ads Game ID
  static const String _gameId = 'YOUR_UNITY_GAME_ID';
  static const String _bannerAdUnitId = 'Banner_Android';
  static const String _interstitialAdUnitId = 'Interstitial_Android';
  static const String _rewardedAdUnitId = 'Rewarded_Android';

  static bool _isInitialized = false;
  static bool _interstitialReady = false;

  static Future<void> initialize() async {
    try {
      await UnityAds.init(
        gameId: _gameId,
        testMode: kDebugMode,
        onComplete: () {
          _isInitialized = true;
          debugPrint('Unity Ads: Initialized successfully');
          _loadInterstitial();
        },
        onFailed: (error, message) {
          debugPrint('Unity Ads: Init failed - $message');
        },
      );
    } catch (e) {
      debugPrint('Unity Ads: Exception - $e');
    }
  }

  static void _loadInterstitial() {
    UnityAds.load(
      placementId: _interstitialAdUnitId,
      onComplete: (placementId) {
        _interstitialReady = true;
        debugPrint('Unity Ads: Interstitial loaded');
      },
      onFailed: (placementId, error, message) {
        debugPrint('Unity Ads: Interstitial load failed - $message');
      },
    );
  }

  static Future<void> showInterstitial() async {
    if (!_isInitialized || !_interstitialReady) return;
    UnityAds.showVideoAd(
      placementId: _interstitialAdUnitId,
      onComplete: (placementId) {
        _interstitialReady = false;
        _loadInterstitial();
      },
      onFailed: (placementId, error, message) {
        debugPrint('Unity Ads: Show failed - $message');
      },
      onStart: (placementId) => debugPrint('Ad started'),
      onClick: (placementId) => debugPrint('Ad clicked'),
    );
  }

  static String get bannerAdUnitId => _bannerAdUnitId;
  static bool get isInitialized => _isInitialized;
}
