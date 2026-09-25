import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_run_config.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/screens/config_screen.dart';
import 'package:math_challenge/screens/menu_screen.dart';
import 'package:math_challenge/screens/numtype_screen.dart';
import 'package:math_challenge/screens/player_screen.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:math_challenge/theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<GameState> makeState() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    final state = GameState(
      settings: SettingsService()
        ..load(
          dark: false,
          sound: false,
          vibration: false,
          dyslexia: false,
          colorblind: false,
          lowPerf: true,
          reduceMotion: true,
          animSpeed: 1,
        ),
      audio: _NoOpAudioService(),
    );
    await state.load();
    addTearDown(state.dispose);
    return state;
  }

  test('all supported selections create canonical Target Clash snapshots', () {
    for (final operation in const [
      Operation.addition,
      Operation.subtraction,
      Operation.multiplication,
      Operation.division,
    ]) {
      for (final difficulty in const [
        Difficulty.easy,
        Difficulty.medium,
        Difficulty.hard,
      ]) {
        for (final numberType in const [
          NumberType.natural,
          NumberType.integers,
          NumberType.rationals,
        ]) {
          final config = TargetClashRunConfig.tryCreate(
            operation: operation,
            difficulty: difficulty,
            numberType: numberType,
          )!;
          final snapshot = GameRunSnapshot.targetClash(config);
          expect(snapshot.hasValidTargetClashEnvelope, isTrue);
          expect(
              snapshot.questionTarget,
              difficulty == Difficulty.easy
                  ? 12
                  : difficulty == Difficulty.medium
                      ? 16
                      : 17);
        }
      }
    }
    expect(
        TargetClashRunConfig.tryCreate(
          operation: Operation.mixed,
          difficulty: Difficulty.easy,
          numberType: NumberType.natural,
        ),
        isNull);
    expect(
        TargetClashRunConfig.tryCreate(
          operation: Operation.addition,
          difficulty: Difficulty.easy,
          numberType: NumberType.mixed,
        ),
        isNull);
  });

  test(
      'pending Target Clash setup is fixed, fail-closed, and starts canonically',
      () async {
    final state = await makeState();
    state
      ..setAdaptive(true)
      ..setAnswerStyle(AnswerStyle.trueFalse)
      ..startTargetClashSetup();
    await state.selectNumType(NumberType.natural.name);
    state
      ..setTargetClashOperation(Operation.division)
      ..setOption('diff', Difficulty.hard.name)
      ..setOption('players', 2)
      ..setOption('mode', GameMode.blitz.name)
      ..setOption('q', 25)
      ..setAdaptive(false)
      ..setTimingStyle(TimingStyle.timeBank)
      ..setAnswerStyle(AnswerStyle.choice4);
    await state.selectNumType(NumberType.mixed.name);
    state
      ..setTargetClashOperation(Operation.mixed)
      ..setOption('diff', Difficulty.expert.name);

    expect(state.setupPlayers, 1);
    expect(state.setupMode, GameMode.standard);
    expect(state.setupTimingStyle, TimingStyle.perQuestion);
    expect(state.setupAdaptive, isFalse);
    expect(state.adaptive, isTrue);
    expect(state.selectedAnswerStyle, AnswerStyle.trueFalse);
    expect(
        state.pendingTargetClashConfig,
        isA<TargetClashRunConfig>()
            .having(
                (config) => config.operation, 'operation', Operation.division)
            .having(
                (config) => config.difficulty, 'difficulty', Difficulty.hard)
            .having((config) => config.numberType, 'number type',
                NumberType.natural));

    state.startGame();
    final snapshot = state.activeRunSnapshot!;
    expect(state.currentScreen, GameScreen.game);
    expect(state.isTargetClash, isTrue);
    expect(state.isTargetClashSetup, isFalse);
    expect(snapshot.runType, GameRunType.targetClash);
    expect(snapshot.mode, GameMode.standard);
    expect(snapshot.players, 1);
    expect(snapshot.timingStyle, TimingStyle.perQuestion);
    expect(snapshot.questionTarget, 17);
  });

  test('Target Clash setup back cleanup leaves normal setup untouched',
      () async {
    final state = await makeState();
    state.startTargetClashSetup();
    await state.selectNumType(NumberType.natural.name);
    state.backFromNumType();
    expect(state.currentScreen, GameScreen.menu);
    expect(state.isTargetClashSetup, isFalse);
    state.goToConfig(Operation.addition.name);
    expect(state.isTargetClashSetup, isFalse);
    expect(state.currentScreen, GameScreen.numType);
  });

  testWidgets('menu entry routes Target Clash through number type and config',
      (tester) async {
    final state = await makeState();
    await tester.pumpWidget(_Host(state));
    await tester.pumpAndSettle();
    final entry = find.byKey(const Key('target-clash-challenge-entry'));
    expect(entry, findsOneWidget);
    expect(find.text('Target Clash'), findsOneWidget);
    expect(find.text('Compare • Aim • Strike'), findsOneWidget);
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(state.currentScreen, GameScreen.numType);
    expect(find.byType(NumTypeScreen), findsOneWidget);

    await tester.tap(find.text('Natural Numbers'));
    await tester.pumpAndSettle();
    expect(state.currentScreen, GameScreen.config);
    expect(find.byType(ConfigScreen), findsOneWidget);
    for (final label in const [
      'Addition',
      'Subtraction',
      'Multiplication',
      'Division',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('<   =   >'), findsOneWidget);
    expect(find.text('10'), findsNothing);
    expect(find.text('2 Players'), findsOneWidget);

    state.goToPlayerSetup();
    await tester.pumpAndSettle();
    expect(find.byType(PlayerSetupScreen), findsOneWidget);
    expect(state.setupPlayers, 1);
    state.backFromPlayers();
    expect(state.currentScreen, GameScreen.config);
    expect(state.targetClashSetupNumberType, NumberType.natural);
  });
}

class _Host extends StatelessWidget {
  const _Host(this.state);
  final GameState state;

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: state.settings),
          ChangeNotifierProvider<GameState>.value(value: state),
        ],
        child: MaterialApp(
          theme: AppTheme.light(state.settings),
          home: Scaffold(
            body: Consumer<GameState>(
              builder: (context, gs, _) => switch (gs.currentScreen) {
                GameScreen.menu => const MenuScreen(),
                GameScreen.numType => const NumTypeScreen(),
                GameScreen.config => const ConfigScreen(),
                GameScreen.player => const PlayerSetupScreen(),
                _ => const SizedBox(),
              },
            ),
          ),
        ),
      );
}

class _NoOpAudioService implements AudioService {
  @override
  int get debugTonePlayCount => 0;
  @override
  int get debugVibrationCount => 0;
  @override
  Future<void> init() async {}
  @override
  Future<void> playCorrect() async {}
  @override
  Future<void> playPowerUp() async {}
  @override
  Future<void> playStart() async {}
  @override
  Future<void> playTones(List<List<double>> tones) async {}
  @override
  Future<void> playWrong() async {}
  @override
  void vibrate(int ms) {}
  @override
  void vibrateCorrect() {}
  @override
  void vibratePattern(List<int> pattern) {}
  @override
  void vibratePowerUp() {}
  @override
  void vibrateWrong() {}
}
