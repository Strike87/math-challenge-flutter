import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'engine/game_state.dart' as gs;
import 'game_config.dart';
import 'services/storage.dart';
import 'services/settings.dart';
import 'services/audio.dart';
import 'services/admob.dart';
import 'services/iap.dart';
import 'screens/menu_screen.dart';
import 'screens/numtype_screen.dart';
import 'screens/config_screen.dart';
import 'screens/player_screen.dart';
import 'screens/game_screen.dart' as game_screen;
import 'theme.dart';
import 'widgets/celebration_overlay.dart';
import 'widgets/modals.dart';

const _prodBannerAdUnitId = 'ca-app-pub-5674349229505017/3485297513';
const _prodInterstitialAdUnitId = 'ca-app-pub-5674349229505017/9643207834';
const _prodRewardedAdUnitId = 'ca-app-pub-5674349229505017/9292157969';

const _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
const _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
const _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  final adService = GoogleMobileAdsService(
    bannerAdUnitId: const String.fromEnvironment(
      'ADMOB_BANNER_AD_UNIT_ID',
      defaultValue: kReleaseMode ? _prodBannerAdUnitId : _testBannerAdUnitId,
    ),
    interstitialAdUnitId: const String.fromEnvironment(
      'ADMOB_INTERSTITIAL_AD_UNIT_ID',
      defaultValue:
          kReleaseMode ? _prodInterstitialAdUnitId : _testInterstitialAdUnitId,
    ),
    rewardedAdUnitId: const String.fromEnvironment(
      'ADMOB_REWARDED_AD_UNIT_ID',
      defaultValue:
          kReleaseMode ? _prodRewardedAdUnitId : _testRewardedAdUnitId,
    ),
  );
  await adService.initialize();
  final iapAdapter = NativeIapPurchaseAdapter();
  unawaited(iapAdapter.initialize().catchError((_) {}));
  runApp(MathChallengeApp(adService: adService, iapAdapter: iapAdapter));
}

class MathChallengeApp extends StatelessWidget {
  const MathChallengeApp({
    super.key,
    required this.adService,
    required this.iapAdapter,
  });

  final AdMobService adService;
  final NativeIapPurchaseAdapter iapAdapter;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsService()),
        Provider<AudioService>(create: (ctx) {
          final s = ctx.read<SettingsService>();
          s.load(
            dark: Storage.getBool('mc_dark', false),
            sound: Storage.getBool('mc_sound', true),
            vibration: Storage.getBool('mc_vibration', true),
            dyslexia: Storage.getBool('mc_dyslexia', false),
            colorblind: Storage.getBool('mc_colorblind', false),
            lowPerf: Storage.getBool('mc_lowPerf', false),
            reduceMotion: Storage.getBool('mc_reduceMotion', false),
            animSpeed: Storage.getDouble('mc_animSpeed', 1.0),
          );
          return AudioService(s);
        }),
        ChangeNotifierProvider(create: (ctx) {
          final s = ctx.read<SettingsService>();
          final a = ctx.read<AudioService>();
          final state = gs.GameState(
            settings: s,
            audio: a,
            adService: adService,
            iapAdapter: iapAdapter,
            iapPurchaseStream: iapAdapter.purchaseStream,
          );
          state.load();
          return state;
        }),
      ],
      child: Consumer<SettingsService>(
        builder: (context, s, _) => MaterialApp(
          title: 'Math Challenge: Boss Battle Edition',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(s),
          darkTheme: AppTheme.dark(s),
          themeMode: s.dark ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) => _MotionSettingsBridge(
            settings: s,
            child: child ?? const SizedBox.shrink(),
          ),
          home: const _AppShell(),
        ),
      ),
    );
  }
}

class _MotionSettingsBridge extends StatefulWidget {
  const _MotionSettingsBridge({
    required this.settings,
    required this.child,
  });

  final SettingsService settings;
  final Widget child;

  @override
  State<_MotionSettingsBridge> createState() => _MotionSettingsBridgeState();
}

class _MotionSettingsBridgeState extends State<_MotionSettingsBridge> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mq = MediaQuery.of(context);
    widget.settings.setPlatformReduceMotion(
      mq.disableAnimations || mq.accessibleNavigation,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<gs.GameState>();
    final s = context.watch<SettingsService>();
    final banner = state.bannerWidget();
    return Scaffold(
      backgroundColor: s.bg,
      body: Stack(
        children: [
          // Mesh background — soft radial gradients to match the original theme.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.2,
                  colors: [
                    const Color(GameConfig.mango)
                        .withValues(alpha: s.dark ? 0.28 : 0.32),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomRight,
                  radius: 1.2,
                  colors: [
                    const Color(GameConfig.sky)
                        .withValues(alpha: s.dark ? 0.24 : 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Foreground screens
          _screenFor(state.currentScreen),
          if (banner != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Center(child: banner),
              ),
            ),
          // Toast
          if (state.toastVisible)
            Positioned(
              top: 56,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: state.toastVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(GameConfig.coral),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(GameConfig.coral)
                              .withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      state.toastMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Modal layer
          const ModalRouter(),
          CelebrationOverlay(state: state, settings: s),
        ],
      ),
    );
  }

  Widget _screenFor(gs.GameScreen s) {
    switch (s) {
      case gs.GameScreen.menu:
        return const MenuScreen();
      case gs.GameScreen.numType:
        return const NumTypeScreen();
      case gs.GameScreen.config:
        return const ConfigScreen();
      case gs.GameScreen.player:
        return const PlayerSetupScreen();
      case gs.GameScreen.game:
        return const game_screen.GameScreen();
    }
  }
}
