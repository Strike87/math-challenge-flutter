import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobRequestPolicy {
  final bool childDirected;
  final bool nonPersonalizedAds;
  final String maxAdContentRating;

  const AdMobRequestPolicy({
    required this.childDirected,
    required this.nonPersonalizedAds,
    required this.maxAdContentRating,
  });

  static const familiesSafe = AdMobRequestPolicy(
    childDirected: true,
    nonPersonalizedAds: true,
    maxAdContentRating: 'G',
  );
}

enum AdMobErrorCode {
  unavailable,
  nativeSimulationBlocked,
  unknown,
}

class AdMobException implements Exception {
  final AdMobErrorCode code;
  final String message;

  const AdMobException(this.code, this.message);

  @override
  String toString() => 'AdMobException($code): $message';
}

abstract class AdMobService {
  AdMobRequestPolicy get requestPolicy;

  Future<void> initialize();

  Future<void> showBanner();

  Future<void> hideBanner();

  Future<bool> showInterstitial();

  Future<bool> showRewarded();
}

class UnavailableAdMobService implements AdMobService {
  const UnavailableAdMobService();

  @override
  AdMobRequestPolicy get requestPolicy => AdMobRequestPolicy.familiesSafe;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> showBanner() async {}

  @override
  Future<void> hideBanner() async {}

  @override
  Future<bool> showInterstitial() async => false;

  @override
  Future<bool> showRewarded() async => false;
}

class DevAdMobService implements AdMobService {
  DevAdMobService({
    this.nativeRelease = false,
    this.interstitialAvailable = true,
    this.rewardedAvailable = true,
  });

  final bool nativeRelease;
  bool interstitialAvailable;
  bool rewardedAvailable;
  int bannerShows = 0;
  int bannerHides = 0;
  int interstitialShows = 0;
  int rewardedShows = 0;

  @override
  AdMobRequestPolicy get requestPolicy => AdMobRequestPolicy.familiesSafe;

  @override
  Future<void> initialize() async {
    _guardNativeReleaseSimulation();
  }

  @override
  Future<void> showBanner() async {
    _guardNativeReleaseSimulation();
    bannerShows++;
  }

  @override
  Future<void> hideBanner() async {
    bannerHides++;
  }

  @override
  Future<bool> showInterstitial() async {
    _guardNativeReleaseSimulation();
    interstitialShows++;
    return interstitialAvailable;
  }

  @override
  Future<bool> showRewarded() async {
    _guardNativeReleaseSimulation();
    rewardedShows++;
    return rewardedAvailable;
  }

  void _guardNativeReleaseSimulation() {
    if (nativeRelease) {
      throw const AdMobException(
        AdMobErrorCode.nativeSimulationBlocked,
        'Development ad simulation cannot run on native release builds.',
      );
    }
  }
}

class GoogleMobileAdsService implements AdMobService {
  GoogleMobileAdsService({
    this.bannerAdUnitId = '',
    this.interstitialAdUnitId = '',
    this.rewardedAdUnitId = '',
  });

  final String bannerAdUnitId;
  final String interstitialAdUnitId;
  final String rewardedAdUnitId;
  bool _initialized = false;
  bool _bannerRequested = false;

  @override
  AdMobRequestPolicy get requestPolicy => AdMobRequestPolicy.familiesSafe;

  AdRequest get adRequest =>
      AdRequest(nonPersonalizedAds: requestPolicy.nonPersonalizedAds);

  @override
  Future<void> initialize() async {
    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
          maxAdContentRating: MaxAdContentRating.g,
        ),
      );
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  @override
  Future<void> showBanner() async {
    if (!_initialized || bannerAdUnitId.isEmpty) return;
    _bannerRequested = true;
  }

  @override
  Future<void> hideBanner() async {
    _bannerRequested = false;
  }

  bool get bannerRequested => _bannerRequested;

  @override
  Future<bool> showInterstitial() async {
    if (!_initialized || interstitialAdUnitId.isEmpty) return false;
    final completer = Completer<bool>();
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: adRequest,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
          );
          ad.show();
          if (!completer.isCompleted) completer.complete(true);
        },
        onAdFailedToLoad: (_) {
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );
    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => false,
    );
  }

  @override
  Future<bool> showRewarded() async {
    if (!_initialized || rewardedAdUnitId.isEmpty) return false;
    final completer = Completer<bool>();
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: adRequest,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
          );
          ad.show(
            onUserEarnedReward: (ad, reward) {
              if (!completer.isCompleted) completer.complete(true);
            },
          );
        },
        onAdFailedToLoad: (_) {
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => false,
    );
  }
}
