import 'dart:async';

import 'package:flutter/foundation.dart';
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
    banner: String.fromEnvironment(
      'ADMOB_BANNER_ID',
      defaultValue: 'ca-app-pub-5674349229505017/3485297513',
    ),
    interstitial: String.fromEnvironment(
      'ADMOB_INTERSTITIAL_ID',
      defaultValue: 'ca-app-pub-5674349229505017/9643207834',
    ),
    rewarded: String.fromEnvironment(
      'ADMOB_REWARDED_ID',
      defaultValue: 'ca-app-pub-5674349229505017/9292157969',
    ),
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

  Future<bool> showInterstitialIfReady();

  Future<bool> showRewarded();

  Widget? bannerWidget({bool forceHidden = false});
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
  Future<bool> showInterstitialIfReady() async => false;

  @override
  Future<bool> showRewarded() async => false;

  @override
  Widget? bannerWidget({bool forceHidden = false}) => null;
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
  Future<bool> showInterstitialIfReady() async {
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
  Widget? bannerWidget({bool forceHidden = false}) =>
      nativeRelease ? null : const SizedBox.shrink();

  void _guardNativeReleaseSimulation() {
    if (nativeRelease) {
      throw const AdMobException(
        AdMobErrorCode.nativeSimulationBlocked,
        'Development ad simulation cannot run on native release builds.',
      );
    }
  }
}

typedef InterstitialAdLoader = Future<void> Function({
  required void Function(InterstitialAdHandle ad) onLoaded,
  required void Function() onFailed,
});

class InterstitialAdHandle {
  const InterstitialAdHandle({required this.show, required this.dispose});

  final Future<void> Function({
    required VoidCallback onShowed,
    required VoidCallback onDismissed,
    required VoidCallback onFailedToShow,
  }) show;
  final VoidCallback dispose;
}

class GoogleMobileAdsService implements AdMobService {
  GoogleMobileAdsService({
    this.bannerAdUnitId = '',
    this.interstitialAdUnitId = '',
    this.rewardedAdUnitId = '',
    Future<void> Function()? initializeMobileAds,
    InterstitialAdLoader? interstitialLoader,
    this.interstitialLoadTimeout = const Duration(seconds: 8),
    this.interstitialRetryBaseDelay = const Duration(seconds: 2),
    this.maxInterstitialLoadRetries = 3,
  })  : _initializeMobileAds = initializeMobileAds,
        _interstitialLoader = interstitialLoader;

  final String bannerAdUnitId;
  final String interstitialAdUnitId;
  final String rewardedAdUnitId;
  final Future<void> Function()? _initializeMobileAds;
  final InterstitialAdLoader? _interstitialLoader;
  final Duration interstitialLoadTimeout;
  final Duration interstitialRetryBaseDelay;
  final int maxInterstitialLoadRetries;
  bool _initialized = false;
  Future<void>? _initializationFuture;
  bool _bannerRequested = false;
  Future<void>? _bannerShowFuture;
  RewardedAd? _rewardedAd;
  Future<RewardedAd?>? _rewardedLoadFuture;
  InterstitialAdHandle? _readyInterstitial;
  bool _interstitialLoading = false;
  bool _interstitialShowing = false;
  int _interstitialLoadToken = 0;
  int _interstitialRetryCount = 0;
  Timer? _interstitialLoadTimeoutTimer;
  Timer? _interstitialRetryTimer;
  final Stopwatch _diagnosticClock = Stopwatch()..start();

  @override
  AdMobRequestPolicy get requestPolicy => AdMobRequestPolicy.familiesSafe;

  AdRequest get adRequest =>
      AdRequest(nonPersonalizedAds: requestPolicy.nonPersonalizedAds);

  @override
  Future<void> initialize() {
    if (_initialized) return Future<void>.value();
    return _initializationFuture ??=
        _initialize().whenComplete(() => _initializationFuture = null);
  }

  Future<void> _initialize() async {
    try {
      final initializeMobileAds = _initializeMobileAds;
      if (initializeMobileAds != null) {
        await initializeMobileAds();
      } else {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(
            tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
            maxAdContentRating: MaxAdContentRating.g,
          ),
        );
        await MobileAds.instance.initialize();
      }
      _initialized = true;
      _preloadInterstitial();
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
  Future<bool> showInterstitialIfReady() async {
    final ad = _readyInterstitial;
    _logInterstitial(ad == null ? 'not ready' : 'show requested');
    if (!_initialized) return false;
    if (ad == null) {
      if (!_interstitialShowing) {
        _interstitialRetryCount = 0;
        _preloadInterstitial();
      }
      return false;
    }
    _readyInterstitial = null;
    _interstitialShowing = true;
    final completer = Completer<bool>();

    void finish(bool shown, String event) {
      if (completer.isCompleted) return;
      _logInterstitial(event);
      _interstitialShowing = false;
      ad.dispose();
      completer.complete(shown);
      _preloadInterstitial();
    }

    try {
      await ad.show(
        onShowed: () => _logInterstitial('showed'),
        onDismissed: () => finish(true, 'dismissed'),
        onFailedToShow: () => finish(false, 'failed to show'),
      );
    } catch (_) {
      finish(false, 'show threw');
    }
    return completer.future;
  }

  void _preloadInterstitial() {
    if (!_initialized ||
        interstitialAdUnitId.isEmpty ||
        _readyInterstitial != null ||
        _interstitialLoading) {
      return;
    }
    _interstitialRetryTimer?.cancel();
    _interstitialRetryTimer = null;
    _interstitialLoading = true;
    final token = ++_interstitialLoadToken;
    _logInterstitial('preload requested');
    _interstitialLoadTimeoutTimer?.cancel();
    _interstitialLoadTimeoutTimer = Timer(interstitialLoadTimeout, () {
      if (token != _interstitialLoadToken || !_interstitialLoading) return;
      _interstitialLoading = false;
      _interstitialLoadToken++;
      _logInterstitial('preload timed out');
      _scheduleInterstitialRetry();
    });

    final loader = _interstitialLoader ?? _loadGoogleInterstitial;
    try {
      unawaited(
        loader(
          onLoaded: (ad) {
            if (token != _interstitialLoadToken || !_interstitialLoading) {
              ad.dispose();
              return;
            }
            _interstitialLoadTimeoutTimer?.cancel();
            _interstitialLoading = false;
            _interstitialRetryCount = 0;
            _readyInterstitial = ad;
            _logInterstitial('preload succeeded');
          },
          onFailed: () => _handleInterstitialLoadFailure(token),
        ).catchError((_) => _handleInterstitialLoadFailure(token)),
      );
    } catch (_) {
      _handleInterstitialLoadFailure(token);
    }
  }

  Future<void> _loadGoogleInterstitial({
    required void Function(InterstitialAdHandle ad) onLoaded,
    required VoidCallback onFailed,
  }) =>
      InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: adRequest,
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) => onLoaded(
            InterstitialAdHandle(
              dispose: ad.dispose,
              show: ({
                required onShowed,
                required onDismissed,
                required onFailedToShow,
              }) {
                ad.fullScreenContentCallback = FullScreenContentCallback(
                  onAdShowedFullScreenContent: (_) => onShowed(),
                  onAdDismissedFullScreenContent: (_) => onDismissed(),
                  onAdFailedToShowFullScreenContent: (ad, error) =>
                      onFailedToShow(),
                );
                return ad.show();
              },
            ),
          ),
          onAdFailedToLoad: (_) => onFailed(),
        ),
      );

  void _handleInterstitialLoadFailure(int token) {
    if (token != _interstitialLoadToken || !_interstitialLoading) return;
    _interstitialLoadTimeoutTimer?.cancel();
    _interstitialLoading = false;
    _logInterstitial('preload failed');
    _scheduleInterstitialRetry();
  }

  void _scheduleInterstitialRetry() {
    if (_interstitialRetryCount >= maxInterstitialLoadRetries) return;
    final multiplier = 1 << _interstitialRetryCount;
    _interstitialRetryCount++;
    final delay = interstitialRetryBaseDelay * multiplier;
    _logInterstitial('retry scheduled in ${delay.inMilliseconds}ms');
    _interstitialRetryTimer = Timer(delay, _preloadInterstitial);
  }

  void _logInterstitial(String event) {
    if (kDebugMode) {
      debugPrint(
        '[perf +${_diagnosticClock.elapsedMilliseconds}ms] interstitial $event',
      );
    }
  }

  @override
  Future<bool> showRewarded() async {
    if (!_initialized || rewardedAdUnitId.isEmpty) return false;
    final ad = _rewardedAd ?? await _ensureRewardedLoaded();
    if (ad == null) return false;
    _rewardedAd = null;
    final completer = Completer<bool>();
    var earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(_ensureRewardedLoaded());
        Future<void>.delayed(const Duration(milliseconds: 300), () {
          if (completer.isCompleted) return;
          if (earned) {
            completer.complete(true);
            return;
          }
          completer.completeError(
            const AdMobException(
              AdMobErrorCode.rewardNotEarned,
              'Rewarded ad closed before reward.',
            ),
          );
        });
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
          earned = true;
        },
      );
    } catch (_) {
      ad.dispose();
      unawaited(_ensureRewardedLoaded());
      if (!completer.isCompleted) completer.complete(false);
    }
    return completer.future;
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
  Widget? bannerWidget({bool forceHidden = false}) {
    if (!_initialized || bannerAdUnitId.isEmpty) {
      return null;
    }
    return _GoogleBannerAd(
      key: ValueKey('banner-$bannerAdUnitId'),
      adUnitId: bannerAdUnitId,
      request: adRequest,
      visible: _bannerRequested && !forceHidden,
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
      child: child,
    );
  }
}
