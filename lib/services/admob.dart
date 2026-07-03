import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobUnitIds {
  const AdMobUnitIds({
    required this.banner,
    required this.interstitial,
    required this.rewarded,
  });

  static const test = AdMobUnitIds(
    banner: 'ca-app-pub-3940256099942544/6300978111',
    interstitial: 'ca-app-pub-3940256099942544/1033173712',
    rewarded: 'ca-app-pub-3940256099942544/5224354917',
  );

  static const fromEnvironment = AdMobUnitIds(
    banner: String.fromEnvironment('ADMOB_BANNER_ID'),
    interstitial: String.fromEnvironment('ADMOB_INTERSTITIAL_ID'),
    rewarded: String.fromEnvironment('ADMOB_REWARDED_ID'),
  );

  final String banner;
  final String interstitial;
  final String rewarded;

  bool get hasAll =>
      banner.isNotEmpty && interstitial.isNotEmpty && rewarded.isNotEmpty;

  static AdMobUnitIds resolve({
    required bool useTestAds,
    AdMobUnitIds testIds = test,
    AdMobUnitIds productionIds = fromEnvironment,
  }) =>
      useTestAds ? testIds : productionIds;
}

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
  rewardNotEarned,
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

  Widget? bannerWidget();
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

  @override
  Widget? bannerWidget() => null;
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

  @override
  Widget? bannerWidget() => nativeRelease ? null : const SizedBox.shrink();

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
  Future<void>? _bannerShowFuture;
  RewardedAd? _rewardedAd;
  Future<RewardedAd?>? _rewardedLoadFuture;

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
      unawaited(_ensureRewardedLoaded());
    } catch (_) {
      _initialized = false;
    }
  }

  @override
  Future<void> showBanner() async {
    if (!_initialized || bannerAdUnitId.isEmpty) return;
    final pending = _bannerShowFuture;
    if (pending != null) return pending;
    _bannerRequested = true;
    _bannerShowFuture =
        Future<void>.value().whenComplete(() => _bannerShowFuture = null);
    return _bannerShowFuture!;
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
    final ad = _rewardedAd ?? await _ensureRewardedLoaded();
    if (ad == null) return false;
    _rewardedAd = null;
    final completer = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(_ensureRewardedLoaded());
        if (!completer.isCompleted) {
          completer.completeError(
            const AdMobException(
              AdMobErrorCode.rewardNotEarned,
              'Rewarded ad closed before reward.',
            ),
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        unawaited(_ensureRewardedLoaded());
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (ad, reward) {
          if (!completer.isCompleted) completer.complete(true);
        },
      );
    } catch (_) {
      ad.dispose();
      unawaited(_ensureRewardedLoaded());
      if (!completer.isCompleted) completer.complete(false);
    }
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => false,
    );
  }

  Future<RewardedAd?> _ensureRewardedLoaded() {
    if (!_initialized || rewardedAdUnitId.isEmpty) {
      return Future<RewardedAd?>.value(null);
    }
    final ad = _rewardedAd;
    if (ad != null) return Future<RewardedAd?>.value(ad);
    final pending = _rewardedLoadFuture;
    if (pending != null) return pending;

    final completer = Completer<RewardedAd?>();
    _rewardedLoadFuture = completer.future
        .timeout(const Duration(seconds: 8), onTimeout: () => null)
        .whenComplete(() => _rewardedLoadFuture = null);
    try {
      unawaited(
        RewardedAd.load(
          adUnitId: rewardedAdUnitId,
          request: adRequest,
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              _rewardedAd = ad;
              if (!completer.isCompleted) completer.complete(ad);
            },
            onAdFailedToLoad: (_) {
              if (!completer.isCompleted) completer.complete(null);
            },
          ),
        ).catchError((_) {
          if (!completer.isCompleted) completer.complete(null);
        }),
      );
    } catch (_) {
      if (!completer.isCompleted) completer.complete(null);
    }
    return _rewardedLoadFuture!;
  }

  @override
  Widget? bannerWidget() {
    if (!_initialized || bannerAdUnitId.isEmpty) {
      return null;
    }
    return _GoogleBannerAd(
      key: ValueKey('banner-$bannerAdUnitId'),
      adUnitId: bannerAdUnitId,
      request: adRequest,
      visible: _bannerRequested,
    );
  }
}

class _GoogleBannerAd extends StatefulWidget {
  const _GoogleBannerAd({
    super.key,
    required this.adUnitId,
    required this.request,
    required this.visible,
  });

  final String adUnitId;
  final AdRequest request;
  final bool visible;

  @override
  State<_GoogleBannerAd> createState() => _GoogleBannerAdState();
}

class _GoogleBannerAdState extends State<_GoogleBannerAd> {
  BannerAd? _ad;
  Timer? _retryTimer;
  bool _loaded = false;
  int? _width;
  int _loadToken = 0;
  int _retryDelaySeconds = 5;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant _GoogleBannerAd oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adUnitId != widget.adUnitId) {
      _disposeAd();
      unawaited(_load());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width > 0 && width != _width) {
      _width = width;
      _disposeAd();
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _disposeAd();
    super.dispose();
  }

  Future<void> _load() async {
    _retryTimer?.cancel();
    final token = ++_loadToken;
    final width = _width ?? 320;
    var size = AdSize.banner;
    try {
      size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width) ?? size;
    } catch (_) {
      // Keep banner loading best-effort; ad failures should not affect play.
    }
    if (!mounted || token != _loadToken) return;
    final ad = BannerAd(
      size: size,
      adUnitId: widget.adUnitId,
      request: widget.request,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || ad != _ad) return;
          _retryDelaySeconds = 5;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          if (ad == _ad) _ad = null;
          setState(() => _loaded = false);
          final delay = _retryDelaySeconds;
          _retryDelaySeconds = (_retryDelaySeconds * 2).clamp(5, 60).toInt();
          _retryTimer = Timer(Duration(seconds: delay), () {
            unawaited(_load());
          });
        },
      ),
    );
    _ad = ad;
    _loaded = false;
    ad.load();
  }

  void _disposeAd() {
    _loadToken++;
    _ad?.dispose();
    _ad = null;
    _loaded = false;
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    final child = !_loaded || ad == null
        ? const SizedBox.shrink()
        : SizedBox(
            width: ad.size.width.toDouble(),
            height: ad.size.height.toDouble(),
            child: AdWidget(ad: ad),
          );
    return Visibility(
      visible: widget.visible,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      child: child,
    );
  }
}
