@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/features/operation_quest/domain/operation_quest.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:math_challenge/theme.dart';
import 'package:math_challenge/game_config.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/player.dart';

import 'package:math_challenge/screens/menu_screen.dart';
import 'package:math_challenge/screens/numtype_screen.dart';
import 'package:math_challenge/screens/config_screen.dart';
import 'package:math_challenge/screens/player_screen.dart';
import 'package:math_challenge/screens/game_screen.dart' as game_screen;
import 'package:math_challenge/widgets/celebration_overlay.dart';
import 'package:math_challenge/widgets/modals.dart';

Future<void> loadAppFonts() async {
  final fontLoader = FontLoader('Baloo2');
  fontLoader.addFont(rootBundle.load('assets/fonts/Baloo2-Bold.ttf'));
  fontLoader.addFont(rootBundle.load('assets/fonts/Baloo2-ExtraBold.ttf'));
  fontLoader.addFont(rootBundle.load('assets/fonts/Baloo2-Black.ttf'));
  await fontLoader.load();

  final fontLoader2 = FontLoader('PlusJakartaSans');
  fontLoader2
      .addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Medium.ttf'));
  fontLoader2
      .addFont(rootBundle.load('assets/fonts/PlusJakartaSans-SemiBold.ttf'));
  fontLoader2.addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Bold.ttf'));
  fontLoader2
      .addFont(rootBundle.load('assets/fonts/PlusJakartaSans-ExtraBold.ttf'));
  await fontLoader2.load();
}

Future<void> setTestDevice(
  WidgetTester tester, {
  required Size logicalSize,
  double devicePixelRatio = 1.0,
}) async {
  tester.view.devicePixelRatio = devicePixelRatio;
  tester.view.physicalSize = logicalSize * devicePixelRatio;

  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void expectNoVisualException(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}

class TestAppWrapper extends StatelessWidget {
  final Widget child;
  final GameState state;

  const TestAppWrapper({
    super.key,
    required this.child,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(value: state.settings),
        Provider<AudioService>.value(value: state.audio),
        ChangeNotifierProvider<GameState>.value(value: state),
      ],
      child: Consumer<SettingsService>(
        builder: (context, s, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(s),
          darkTheme: AppTheme.dark(s),
          themeMode: s.dark ? ThemeMode.dark : ThemeMode.light,
          home: child,
        ),
      ),
    );
  }
}

class TestAppShell extends StatelessWidget {
  const TestAppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final s = context.watch<SettingsService>();
    return Scaffold(
      backgroundColor: s.bg,
      body: Stack(
        children: [
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
          _screenFor(state.currentScreen),
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
          const ModalRouter(),
          CelebrationOverlay(state: state, settings: s),
        ],
      ),
    );
  }

  Widget _screenFor(GameScreen s) {
    switch (s) {
      case GameScreen.menu:
        return const MenuScreen();
      case GameScreen.numType:
        return const NumTypeScreen();
      case GameScreen.config:
        return const ConfigScreen();
      case GameScreen.player:
        return const PlayerSetupScreen();
      case GameScreen.game:
        return const game_screen.GameScreen();
    }
  }
}

class MockAudioService implements AudioService {
  @override
  int get debugTonePlayCount => 0;
  @override
  int get debugVibrationCount => 0;

  @override
  Future<void> init() async {}
  @override
  Future<void> playTones(List<List<double>> tones) async {}
  @override
  Future<void> playCorrect() async {}
  @override
  Future<void> playWrong() async {}
  @override
  Future<void> playStart() async {}
  @override
  Future<void> playPowerUp() async {}
  @override
  void vibrate(int ms) {}
  @override
  void vibratePattern(List<int> pattern) {}
  @override
  void vibrateCorrect() {}
  @override
  void vibrateWrong() {}
  @override
  void vibratePowerUp() {}
}

Future<GameState> _makeState([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues(prefs);
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
  final state = GameState(settings: settings, audio: MockAudioService());
  await state.load();
  state.dailyBoss = GameConfig.dailyBosses.first;
  state.dailyBossDateKey = '2026-06-28';
  addTearDown(state.dispose);
  return state;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  group('RT-040: Visual Parity', () {
    const phoneSize = Size(390, 844);
    const tabletSize = Size(834, 1194);

    testWidgets('1. Main menu phone layout (light & dark)', (tester) async {
      final state = await _makeState({'mc_dark': false});
      state.currentScreen = GameScreen.menu;
      await setTestDevice(tester, logicalSize: phoneSize);
      await tester.pumpWidget(
          TestAppWrapper(state: state, child: const TestAppShell()));
      await tester.pumpAndSettle();
      expect(find.text('MATH'), findsOneWidget);
      expect(find.text('CHALLENGE'), findsOneWidget);
      expect(find.text('BOSS BATTLE EDITION'), findsOneWidget);
      expect(find.text('Operation Quest'), findsOneWidget);
      expectNoVisualException(tester);
      await expectLater(find.byType(TestAppShell),
          matchesGoldenFile('goldens/01_menu_phone_light.png'));

      state.settings.toggleDark();
      await tester.pumpAndSettle();
      expect(find.text('Operation Quest'), findsOneWidget);
      expectNoVisualException(tester);
      await expectLater(find.byType(TestAppShell),
          matchesGoldenFile('goldens/01_menu_phone_dark.png'));
    });

    testWidgets('2. Main menu tablet layout (light & dark)', (tester) async {
      final state = await _makeState({'mc_dark': false});
      state.currentScreen = GameScreen.menu;
      await setTestDevice(tester, logicalSize: tabletSize);
      await tester.pumpWidget(
          TestAppWrapper(state: state, child: const TestAppShell()));
      await tester.pumpAndSettle();
      expect(find.text('Operation Quest'), findsOneWidget);
      expectNoVisualException(tester);
      await expectLater(find.byType(TestAppShell),
          matchesGoldenFile('goldens/02_menu_tablet_light.png'));

      state.settings.toggleDark();
      await tester.pumpAndSettle();
      expectNoVisualException(tester);
      await expectLater(find.byType(TestAppShell),
          matchesGoldenFile('goldens/02_menu_tablet_dark.png'));
    });

    testWidgets('2b. Operation Quest map shows all trails and lock states',
        (tester) async {
      final state = await _makeState({
        'mc_dark': false,
        'mc_operationQuestProgress':
            '{"version":1,"stars":{"addition_easy":2,"addition_medium":1}}',
      });
      state.currentScreen = GameScreen.menu;
      state.showOperationQuest();
      await setTestDevice(tester, logicalSize: phoneSize);
      await tester.pumpWidget(
          TestAppWrapper(state: state, child: const TestAppShell()));
      await tester.pumpAndSettle();
      expect(find.text('➕ Addition Trail'), findsOneWidget);
      expect(find.text('➖ Subtraction Trail'), findsOneWidget);
      expect(find.text('✖️ Multiplication Trail'), findsOneWidget);
      expect(find.text('➗ Division Trail'), findsOneWidget);
      expect(find.text('🧮 Mixed Operations Trail'), findsOneWidget);
      expect(find.text('❔ Missing Operation Trail'), findsOneWidget);
      expect(find.text('🔢 Missing Number Trail'), findsOneWidget);
      expect(find.text('First Differences'), findsOneWidget);
      expectNoVisualException(tester);
      await expectLater(
        find.byType(TestAppShell),
        matchesGoldenFile('goldens/02b_operation_quest_map_phone.png'),
      );
    });

    testWidgets('3. Number type screen (locked & unlocked states)',
        (tester) async {
      final state = await _makeState({
        'mc_dark': false,
        'mc_numTypeUnlocked_integers': 1,
        'mc_numTypeUnlocked_rationals': 0,
      });
      state.currentScreen = GameScreen.numType;
      await setTestDevice(tester, logicalSize: phoneSize);
      await tester.pumpWidget(
          TestAppWrapper(state: state, child: const TestAppShell()));
      await tester.pumpAndSettle();
      expect(find.text('Natural Numbers'), findsOneWidget);
      expect(find.text('Integers'), findsOneWidget);
      expect(find.text('Rationals / Decimals'), findsOneWidget);
      expect(find.textContaining('1200'), findsOneWidget);
      expectNoVisualException(tester);
      await expectLater(find.byType(TestAppShell),
          matchesGoldenFile('goldens/03_numtype_locked_unlocked.png'));
    });

    testWidgets('4. Config screen 1P mode grid', (tester) async {
      final state = await _makeState({'mc_dark': false});
      state.setOption('players', 1);
      state.currentScreen = GameScreen.config;
      await setTestDevice(tester, logicalSize: phoneSize);
      await tester.pumpWidget(
          TestAppWrapper(state: state, child: const TestAppShell()));
      await tester.pumpAndSettle();
      expect(find.text('Players'), findsOneWidget);
      expect(find.text('Game Mode'), findsOneWidget);
      expect(find.text('Difficulty'), findsOneWidget);
      expect(find.text('Number of Questions'), findsOneWidget);
      expectNoVisualException(tester);
      await expectLater(find.byType(TestAppShell),
          matchesGoldenFile('goldens/04_config_1p.png'));
    });

    testWidgets('5. Config screen 2P mode grid with restricted modes greyed',
        (tester) async {
      final state = await _makeState({'mc_dark': false});
      state.setOption('players', 2);
      state.currentScreen = GameScreen.config;
      await setTestDevice(tester, logicalSize: phoneSize);
      await tester.pumpWidget(
          TestAppWrapper(state: state, child: const TestAppShell()));
      await tester.pumpAndSettle();
      expect(find.text('Standard', skipOffstage: false), findsWidgets);
      expect(find.text('Blitz', skipOffstage: false), findsWidgets);
      expectNoVisualException(tester);
      await expectLater(find.byType(TestAppShell),
          matchesGoldenFile('goldens/05_config_2p_standard_only.png'));
    });

    testWidgets('6. Player setup 1P layout', (tester) async {
      final state = await _makeState({'mc_dark': false});
      state.setOption('players', 1);
      state.currentScreen = GameScreen.player;
      await setTestDevice(tester, logicalSize: phoneSize);
      await tester.pumpWidget(
          TestAppWrapper(state: state, child: const TestAppShell()));
      await tester.pumpAndSettle();
      expect(find.text('Tap to change'), findsOneWidget);
      expect(find.text('🎨 Customize Avatar'), findsOneWidget);
      expectNoVisualException(tester);
      await expectLater(find.byType(TestAppShell),
          matchesGoldenFile('goldens/06_player_setup_1p.png'));
    });

    testWidgets('7. Player setup 2P layout', (tester) async {
      final state = await _makeState({'mc_dark': false});
      state.setOption('players', 2);
      state.currentScreen = GameScreen.player;
      await setTestDevice(tester, logicalSize: phoneSize);
      await tester.pumpWidget(
          TestAppWrapper(state: state, child: const TestAppShell()));
      await tester.pumpAndSettle();
      expect(find.text('Player 1 Setup'), findsOneWidget);
      expect(find.text('Tap to change'), findsOneWidget);
      expect(find.text('🎨 Customize Avatar'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expectNoVisualException(tester);
      await expectLater(find.byType(TestAppShell),
          matchesGoldenFile('goldens/07_player_setup_2p.png'));
    });

    testWidgets('8. Gameplay HUD/question/answers/power-ups', (tester) async {
      final state = await _makeState({'mc_dark': false});
      state.setOption('players', 1);

      // Build a deterministic GameState manually instead of calling startGame()
      state.currentScreen = GameScreen.game;
      state.p[1].resetForGame(isSinglePlayer: true, isMasterOrBoss: false);
      state.p[1].pups = [
        PowerUp.time,
        PowerUp.time,
        PowerUp.fifty,
        PowerUp.freeze,
        PowerUp.freeze,
        PowerUp.freeze,
        PowerUp.freeze,
        PowerUp.freeze,
      ];

      state.rt = RuntimeState()
        ..challenge = Operation.addition
        ..gameActive = true
        ..state = 'playing'
        ..isWarmUp = false
        ..maxTurns = 10
        ..accepting = true
        ..q = const Question(
          type: Operation.addition,
          key: '5+3',
          text: '5 + 3',
          ans: 8,
          choices: [6, 7, 8, 9],
          diff: Difficulty.easy,
          numType: NumberType.natural,
        );

      await setTestDevice(tester, logicalSize: phoneSize);
      await tester.pumpWidget(
          TestAppWrapper(state: state, child: const TestAppShell()));
      await tester.pumpAndSettle();
      expect(find.text('5 + 3', findRichText: true), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('50/50'), findsOneWidget);
      expectNoVisualException(tester);
      await expectLater(find.byType(TestAppShell),
          matchesGoldenFile('goldens/08_gameplay_light.png'));

      state.settings.toggleDark();
      await tester.pumpAndSettle();
      expectNoVisualException(tester);
      await expectLater(find.byType(TestAppShell),
          matchesGoldenFile('goldens/08_gameplay_dark.png'));

      state.rt.timer?.cancel();
    });

    testWidgets('9. Daily Boss screen/modal', (tester) async {
      final state = await _makeState({'mc_dark': false});
      state.currentScreen = GameScreen.menu;
      state.showModal(GameModal.dailyBoss);
      await setTestDevice(tester, logicalSize: phoneSize);
      await tester.pumpWidget(
          TestAppWrapper(state: state, child: const TestAppShell()));
      await tester.pumpAndSettle();
      expect(find.text('Mission'), findsOneWidget);
      expect(find.text('Rules'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsWidgets);
      expectNoVisualException(tester);
      await expectLater(find.byType(TestAppShell),
          matchesGoldenFile('goldens/09_daily_boss_modal.png'));
    });

    testWidgets('10. Stage cleared modal uses real Master stage state',
        (tester) async {
      final state = await _makeState({'mc_dark': false});
      state.debugSetMasterStage(1);
      state.currentScreen = GameScreen.game;
      state.p[1].resetForGame(
        isSinglePlayer: true,
        isMasterOrBoss: true,
      );
      state.rt = RuntimeState()
        ..challenge = Operation.master
        ..gameActive = true
        ..state = 'playing'
        ..isWarmUp = false
        ..maxTurns = state.currentMasterLevel!.goal
        ..accepting = true
        ..q = const Question(
          type: Operation.subtraction,
          key: '9-4',
          text: '9 - 4',
          ans: 5,
          choices: [3, 4, 5, 6],
          diff: Difficulty.medium,
          numType: NumberType.natural,
        );
      state.showModal(GameModal.stageCleared);
      await setTestDevice(tester, logicalSize: phoneSize);
      await tester.pumpWidget(
          TestAppWrapper(state: state, child: const TestAppShell()));
      await tester.pumpAndSettle();
      expect(find.text('The Jungle Cleared! 🌟'), findsOneWidget);
      expect(find.textContaining('You defeated the Gorilla!'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsWidgets);
      expectNoVisualException(tester);
      await expectLater(find.byType(TestAppShell),
          matchesGoldenFile('goldens/10_win_modal.png'));
    });

    testWidgets('11. Avatar Builder modal', (tester) async {
      final state = await _makeState({'mc_dark': false});
      state.currentScreen = GameScreen.player;
      state.showModal(GameModal.avatarBuilder);
      await setTestDevice(tester, logicalSize: phoneSize);
      await tester.pumpWidget(
          TestAppWrapper(state: state, child: const TestAppShell()));
      await tester.pumpAndSettle();
      expect(find.text('Avatar Builder'), findsOneWidget);
      expect(find.text('Base'), findsWidgets);
      expect(find.text('Hat'), findsWidgets);
      expect(find.text('Accessory'), findsOneWidget);
      expect(find.text('Color'), findsWidgets);
      expect(find.byType(SingleChildScrollView), findsWidgets);
      expectNoVisualException(tester);
      await expectLater(find.byType(TestAppShell),
          matchesGoldenFile('goldens/11_avatar_builder_modal.png'));
    });

    testWidgets('12. Coin Shop modal', (tester) async {
      final state = await _makeState({'mc_dark': false});
      state.currentScreen = GameScreen.menu;
      state.showModal(GameModal.coinShop);
      await setTestDevice(tester, logicalSize: phoneSize);
      await tester.pumpWidget(
          TestAppWrapper(state: state, child: const TestAppShell()));
      await tester.pumpAndSettle();
      expect(find.text('Coin Shop'), findsOneWidget);
      expect(find.byKey(const Key('shopHub_avatars')), findsOneWidget);
      expect(find.byKey(const Key('shopHub_hats')), findsOneWidget);
      expect(find.byKey(const Key('shopHub_packs')), findsOneWidget);
      expect(find.byKey(const Key('shopHub_buy')), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsWidgets);
      expectNoVisualException(tester);
      await expectLater(find.byType(TestAppShell),
          matchesGoldenFile('goldens/12_coin_shop_modal.png'));
    });

    testWidgets(
        '13. Settings modal preserves approved avatar tile in light & dark',
        (tester) async {
      final state = await _makeState({'mc_dark': false});
      state.currentScreen = GameScreen.menu;
      state.showModal(GameModal.settings);
      await setTestDevice(tester, logicalSize: phoneSize);
      await tester.pumpWidget(
          TestAppWrapper(state: state, child: const TestAppShell()));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Player Avatar'), findsOneWidget);
      expect(find.text('Default Avatar'), findsOneWidget);
      expect(find.text('Tap to change'), findsOneWidget);
      expect(find.text('Tap to change • unlocked emojis only'), findsNothing);
      expect(find.byType(SingleChildScrollView), findsWidgets);
      expectNoVisualException(tester);
      await expectLater(find.byType(TestAppShell),
          matchesGoldenFile('goldens/13_settings_modal_light.png'));

      state.settings.toggleDark();
      await tester.pumpAndSettle();
      expect(find.text('Player Avatar'), findsOneWidget);
      expectNoVisualException(tester);
      await expectLater(find.byType(TestAppShell),
          matchesGoldenFile('goldens/13_settings_modal_dark.png'));
    });

    testWidgets('14. Missing Operation Quest gameplay uses operator symbols',
        (tester) async {
      final state = await _makeState({
        'mc_dark': false,
        'mc_operationQuestProgress':
            '{"version":1,"stars":{"missing_operation_medium":1}}',
      });
      state
          .startOperationQuestStage(OperationQuestStageId.missingOperationHard);
      state.startGame();
      state.rt.timer?.cancel();
      state.rt.timer = null;
      state.rt.timerDurationMs = 0;
      state.rt.timerStart = 0;
      state.rt.q = Question(
        type: Operation.addition,
        key: 'visual-missing-operation',
        text: '90 ? 9 = 99',
        ans: 0,
        choices: [0, 1, 2, 3],
        diff: Difficulty.hard,
        numType: NumberType.natural,
      );
      await setTestDevice(tester, logicalSize: phoneSize);
      await tester.pumpWidget(
          TestAppWrapper(state: state, child: const TestAppShell()));
      await tester.pumpAndSettle();
      expect(find.text('?', findRichText: true), findsWidgets);
      for (final symbol in ['+', '−', '×', '÷']) {
        expect(find.text(symbol), findsOneWidget);
      }
      expectNoVisualException(tester);
      await expectLater(
        find.byType(TestAppShell),
        matchesGoldenFile('goldens/14_missing_operation_gameplay.png'),
      );
      state.rt.timer?.cancel();
    });

    testWidgets('15. True/False gameplay', (tester) async {
      final state = await _makeState({'mc_dark': false});
      state.setOption('players', 1);
      state.currentScreen = GameScreen.game;
      state.p[1].resetForGame(isSinglePlayer: true, isMasterOrBoss: false);
      state.p[1].pups = [PowerUp.time, PowerUp.fifty, PowerUp.fifty];
      state.rt = RuntimeState()
        ..challenge = Operation.subtraction
        ..answerStyle = AnswerStyle.trueFalse
        ..proposedAnswer = 8
        ..proposedTruth = false
        ..gameActive = true
        ..state = 'playing'
        ..isWarmUp = false
        ..maxTurns = 10
        ..accepting = true
        ..q = const Question(
          type: Operation.subtraction,
          key: 'visual-true-false',
          text: '12 - 5 = ?',
          ans: 7,
          choices: [6, 7, 8, 9],
          diff: Difficulty.easy,
          numType: NumberType.natural,
        );

      await setTestDevice(tester, logicalSize: phoneSize);
      await tester.pumpWidget(
          TestAppWrapper(state: state, child: const TestAppShell()));
      await tester.pumpAndSettle();

      expect(find.text('12 - 5 = 8', findRichText: true), findsOneWidget);
      expect(find.text('?', findRichText: true), findsNothing);
      expect(find.byKey(const Key('answer-true')), findsOneWidget);
      expect(find.byKey(const Key('answer-false')), findsOneWidget);
      expect(find.byKey(const Key('powerup-fifty-count')), findsNothing);
      expectNoVisualException(tester);
      await expectLater(
        find.byType(TestAppShell),
        matchesGoldenFile('goldens/15_true_false_gameplay.png'),
      );
    });
  });
}
