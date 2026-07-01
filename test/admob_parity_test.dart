import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/services/admob.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const audioGlobalChannel = MethodChannel('xyz.luan/audioplayers.global');
  const audioPlayerChannel = MethodChannel('xyz.luan/audioplayers');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, (_) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioPlayerChannel, (_) async => null);
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioPlayerChannel, null);
  });

  group('RT-051 AdMob parity', () {
    test('banner eligibility is limited to number type and player setup',
        () async {
      final state = await _makeState();

      expect(state.isBannerEligibleFor(GameScreen.numType), isTrue);
      expect(state.isBannerEligibleFor(GameScreen.player), isTrue);
      expect(state.isBannerEligibleFor(GameScreen.menu), isFalse);
      expect(state.isBannerEligibleFor(GameScreen.config), isFalse);
      expect(state.isBannerEligibleFor(GameScreen.game), isFalse);

      state.adsRemoved = true;
      expect(state.isBannerEligibleFor(GameScreen.numType), isFalse);
      expect(state.isBannerEligibleFor(GameScreen.player), isFalse);
    });

    test('banner sync shows only eligible screens and hides elsewhere',
        () async {
      final ads = _FakeAdMobService();
      final state = await _makeState(adService: ads);

      state.currentScreen = GameScreen.numType;
      await state.syncBannerForCurrentScreen();
      expect(ads.bannerShows, 1);
      expect(ads.bannerHides, 0);

      state.currentScreen = GameScreen.game;
      await state.syncBannerForCurrentScreen();
      expect(ads.bannerShows, 1);
      expect(ads.bannerHides, 1);
    });

    test('banner is suppressed while a modal is open and resumes after close',
        () async {
      final ads = _FakeAdMobService();
      final state = await _makeState(adService: ads);
      state.currentScreen = GameScreen.numType;

      await state.syncBannerForCurrentScreen();
      expect(ads.bannerWidget(), isNotNull);
      expect(ads.bannerShows, 1);

      state.showModal(GameModal.coinShop);
      await Future<void>.delayed(Duration.zero);
      expect(state.bannerWidget(), isNull);
      expect(ads.bannerHides, 1);

      state.closeModal();
      await Future<void>.delayed(Duration.zero);
      expect(state.bannerWidget(), isNotNull);
      expect(ads.bannerShows, 2);
    });

    test('completed games persist counter and request interstitial every third',
        () async {
      final ads = _FakeAdMobService();
      final state = await _makeState(adService: ads);

      await state.debugRecordCompletedGameForAds();
      await state.debugRecordCompletedGameForAds();
      expect(ads.interstitialShows, 0);

      await state.debugRecordCompletedGameForAds();
      expect(ads.interstitialShows, 1);
      expect(state.adGameCount, 3);
      expect(Storage.getInt('mc_adGameCount', 0), 3);
    });

    test('adsRemoved disables interstitial requests', () async {
      final ads = _FakeAdMobService();
      final state = await _makeState(
        adService: ads,
        prefs: {'mc_adsRemoved': true},
      );

      await state.debugRecordCompletedGameForAds();
      await state.debugRecordCompletedGameForAds();
      await state.debugRecordCompletedGameForAds();

      expect(state.adGameCount, 0);
      expect(ads.interstitialShows, 0);
    });

    test('rewarded success grants exactly 10 coins and persists cooldown',
        () async {
      final ads = _FakeAdMobService(rewardedResult: true);
      final state = await _makeState(adService: ads, nowMillis: 1000000);

      final claimed = await state.claimRewardedAdCoins(nowMillis: 1000000);

      expect(claimed, isTrue);
      expect(ads.rewardedShows, 1);
      expect(state.coins, GameState.rewardedAdCoins);
      expect(state.lastRewardedAt, 1000000);
      expect(Storage.getInt('mc_lastRewardedAt', 0), 1000000);
      expect(Storage.getInt('mc_coins', 0), GameState.rewardedAdCoins);
    });

    test('rewarded unavailable or error grants nothing', () async {
      final unavailableAds = _FakeAdMobService(rewardedResult: false);
      final unavailableState = await _makeState(adService: unavailableAds);

      expect(await unavailableState.claimRewardedAdCoins(), isFalse);
      expect(unavailableState.coins, 0);
      expect(unavailableState.lastRewardedAt, 0);
      expect(unavailableState.toastMessage,
          'Rewarded ad unavailable. Please try again later.');

      final errorAds = _FakeAdMobService()..throwRewarded = true;
      final errorState = await _makeState(adService: errorAds);

      expect(await errorState.claimRewardedAdCoins(), isFalse);
      expect(errorState.coins, 0);
      expect(errorState.lastRewardedAt, 0);
      expect(errorState.toastMessage,
          'Rewarded ad unavailable. Please try again later.');

      final earlyExitAds = _FakeAdMobService()
        ..rewardedException = const AdMobException(
          AdMobErrorCode.rewardNotEarned,
          'closed',
        );
      final earlyExitState = await _makeState(adService: earlyExitAds);

      expect(await earlyExitState.claimRewardedAdCoins(), isFalse);
      expect(earlyExitState.coins, 0);
      expect(earlyExitState.lastRewardedAt, 0);
      expect(earlyExitState.toastMessage, 'Watch the full ad to earn coins.');
    });

    test('rewarded cooldown blocks repeat claim and persists across reload',
        () async {
      final ads = _FakeAdMobService(rewardedResult: true);
      final state = await _makeState(adService: ads, nowMillis: 1000000);

      expect(await state.claimRewardedAdCoins(nowMillis: 1000000), isTrue);
      expect(await state.claimRewardedAdCoins(nowMillis: 1100000), isFalse);
      expect(ads.rewardedShows, 1);
      expect(state.coins, GameState.rewardedAdCoins);

      final reloaded = await _makeState(
        adService: _FakeAdMobService(rewardedResult: true),
        resetPrefs: false,
        nowMillis: 1100000,
      );
      expect(reloaded.lastRewardedAt, 1000000);
      expect(reloaded.rewardedCooldownRemainingMs(nowMillis: 1100000), 200000);

      expect(await reloaded.claimRewardedAdCoins(nowMillis: 1300000), isTrue);
      expect(reloaded.coins, GameState.rewardedAdCoins * 2);
    });

    test('adsRemoved disables rewarded ad prompts', () async {
      final ads = _FakeAdMobService(rewardedResult: true);
      final state = await _makeState(
        adService: ads,
        prefs: {'mc_adsRemoved': true},
      );

      expect(await state.claimRewardedAdCoins(), isFalse);
      expect(ads.rewardedShows, 0);
      expect(state.coins, 0);
    });

    test('unavailable service and blocked native simulation grant nothing',
        () async {
      final unavailable = await _makeState(
        adService: const UnavailableAdMobService(),
      );

      await unavailable.debugRecordCompletedGameForAds();
      await unavailable.debugRecordCompletedGameForAds();
      await unavailable.debugRecordCompletedGameForAds();
      expect(await unavailable.claimRewardedAdCoins(), isFalse);
      expect(unavailable.coins, 0);

      final nativeBlocked = await _makeState(
        adService: DevAdMobService(nativeRelease: true),
      );
      expect(await nativeBlocked.claimRewardedAdCoins(), isFalse);
      expect(nativeBlocked.coins, 0);
    });

    test('Families-safe request policy is applied by game services', () async {
      final state = await _makeState(adService: DevAdMobService());
      final policy = state.debugAdRequestPolicy;

      expect(policy.childDirected, isTrue);
      expect(policy.nonPersonalizedAds, isTrue);
      expect(policy.maxAdContentRating, 'G');
    });
  });
}

Future<GameState> _makeState({
  Map<String, Object> prefs = const {},
  AdMobService? adService,
  int nowMillis = 1000000,
  bool resetPrefs = true,
}) async {
  if (resetPrefs) {
    SharedPreferences.setMockInitialValues(prefs);
  }
  await Storage.init();
  final settings = SettingsService()
    ..load(
      dark: false,
      sound: false,
      vibration: false,
      dyslexia: false,
      colorblind: false,
      lowPerf: true,
      reduceMotion: true,
      animSpeed: 1,
    );
  final state = GameState(
    settings: settings,
    audio: AudioService(settings),
    adService: adService ?? _FakeAdMobService(),
    nowMillisProvider: () => nowMillis,
  );
  await state.load();
  return state;
}

class _FakeAdMobService implements AdMobService {
  _FakeAdMobService({this.rewardedResult = false});

  bool rewardedResult;
  bool throwRewarded = false;
  AdMobException? rewardedException;
  int bannerShows = 0;
  int bannerHides = 0;
  int interstitialShows = 0;
  int rewardedShows = 0;

  @override
  AdMobRequestPolicy get requestPolicy => AdMobRequestPolicy.familiesSafe;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> showBanner() async {
    bannerShows++;
  }

  @override
  Future<void> hideBanner() async {
    bannerHides++;
  }

  @override
  Widget? bannerWidget() => const SizedBox(key: Key('fakeBanner'));

  @override
  Future<bool> showInterstitial() async {
    interstitialShows++;
    return true;
  }

  @override
  Future<bool> showRewarded() async {
    final exception = rewardedException;
    if (exception != null) throw exception;
    if (throwRewarded) {
      throw const AdMobException(AdMobErrorCode.unavailable, 'No ad loaded');
    }
    rewardedShows++;
    return rewardedResult;
  }
}
