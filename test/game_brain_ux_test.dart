import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/features/family/domain/family_eligibility.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/game_data.dart';
import 'package:math_challenge/models/player.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/screens/game_screen.dart' as gameplay;
import 'package:math_challenge/screens/menu_screen.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const globalAudioChannel = MethodChannel('xyz.luan/audioplayers.global');
  const audioChannel = MethodChannel('xyz.luan/audioplayers');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(globalAudioChannel, (_) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, (_) async => null);
  });
  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(globalAudioChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, null);
  });

  test('absent, on, and off preferences reload through local storage',
      () async {
    final absent = await _makeState();
    expect(absent.gameBrainPreference, isFalse);
    expect(absent.effectiveGameBrainEnabled, isFalse);
    expect(await absent.setGameBrainPreference(true), isTrue);
    final onReload = await _reloadState();
    expect(onReload.gameBrainPreference, isTrue);
    expect(onReload.effectiveGameBrainEnabled, isFalse);
    expect(await onReload.setGameBrainPreference(false), isTrue);
    final offReload = await _reloadState();
    expect(offReload.gameBrainPreference, isFalse);
    expect(Storage.getBool(GameState.gameBrainPreferenceStorageKey, true),
        isFalse);
  });

  test('preference remains fail-closed despite family eligibility', () async {
    final state = await _makeState();
    await state.setGameBrainPreference(true);
    for (final range in [
      FamilyAgeRange.teen13to17,
      FamilyAgeRange.adult18plus,
    ]) {
      await state.submitFamilyAgeRange(range);
      expect(state.familyEligibility, FamilyEligibility.eligible);
      expect(state.effectiveGameBrainEnabled, isFalse);
    }
    state.setApprovedGameBrainEligibilityForTesting(true);
    expect(state.effectiveGameBrainEnabled, isTrue);
    state.setApprovedGameBrainEligibilityForTesting(false);
    expect(state.effectiveGameBrainEnabled, isFalse);
  });

  test('GameBrain preference stays outside cloud progress', () async {
    final state = await _makeState();
    await state.setGameBrainPreference(true);
    final payload = state.exportCloudProgress().toJson();
    expect(
        payload.containsKey(GameState.gameBrainPreferenceStorageKey), isFalse);
    expect(payload.toString(), isNot(contains('gameBrain')));
  });

  test('clear isolates preference and reset clears its key', () async {
    final state = await _makeState();
    state
      ..coins = 42
      ..gamesPlayed = 7
      ..adaptive = true
      ..skillMap['addition'] = SkillData(mastery: 77, count: 3)
      ..achievements['first_win'] = true;
    state.settings.toggleDark();
    await state.setGameBrainPreference(true);
    expect(await state.clearGameBrainData(), isTrue);
    expect(state.gameBrainPreference, isFalse);
    expect(
        Storage.containsKey(GameState.gameBrainPreferenceStorageKey), isFalse);
    expect(state.coins, 42);
    expect(state.gamesPlayed, 7);
    expect(state.adaptive, isTrue);
    expect(state.skillMap['addition']!.mastery, 77);
    expect(state.achievements['first_win'], isTrue);
    expect(state.settings.dark, isTrue);
    await state.setGameBrainPreference(true);
    state.setApprovedGameBrainEligibilityForTesting(true);
    await state.resetAllData();
    expect(state.gameBrainPreference, isFalse);
    expect(state.effectiveGameBrainEnabled, isFalse);
    expect(
        Storage.containsKey(GameState.gameBrainPreferenceStorageKey), isFalse);
  });

  test(
      'preference lifecycle preserves adaptive, question, and BRAIN-07 observer',
      () async {
    final state = await _makeState();
    state
      ..adaptive = true
      ..rt.challenge = Operation.addition
      ..mode = GameMode.standard
      ..diff = Difficulty.easy
      ..numType = NumberType.natural
      ..questionCount = 10
      ..startGame();
    state.rt.timer?.cancel();
    final question = state.rt.q;
    expect(state.debugHasContextEvidenceObserver, isTrue);
    expect(state.debugContextEvidenceObservationCount, 0);
    await state.setGameBrainPreference(true);
    expect(state.effectiveGameBrainEnabled, isFalse);
    expect(state.adaptive, isTrue);
    expect(state.rt.q, same(question));
    state.setApprovedGameBrainEligibilityForTesting(true);
    expect(state.effectiveGameBrainEnabled, isTrue);
    expect(state.adaptive, isTrue);
    expect(state.rt.q, same(question));
    state.onAnswer(question!.ans);
    expect(state.debugContextEvidenceObservationCount, 1);
    await state.setGameBrainPreference(false);
    expect(state.adaptive, isTrue);
    expect(state.debugContextEvidenceObservationCount, 1);
  });

  testWidgets(
      'GameBrain preference leaves a seeded standard question sequence unchanged',
      (tester) async {
    final off = await _makeState(
      questionGenerator: QuestionGenerator(rng: Random(1408)),
    );
    final on = await _makeState(
      questionGenerator: QuestionGenerator(rng: Random(1408)),
    );
    await on.setGameBrainPreference(true);
    expect(on.effectiveGameBrainEnabled, isFalse);

    for (final state in [off, on]) {
      state
        ..mode = GameMode.standard
        ..diff = Difficulty.easy
        ..numType = NumberType.natural
        ..adaptive = false
        ..selectedAnswerStyle = AnswerStyle.choice4
        ..questionCount = 10
        ..rt.challenge = Operation.addition
        ..startGame();
    }

    for (var turn = 0; turn < 4; turn++) {
      final offQuestion = off.rt.q!;
      final onQuestion = on.rt.q!;
      expect(_questionSignature(onQuestion), _questionSignature(offQuestion));
      off.onAnswer(offQuestion.ans);
      on.onAnswer(onQuestion.ans);
      if (turn < 3) await tester.pump(const Duration(milliseconds: 1300));
    }
    await tester.pump(const Duration(milliseconds: 1300));
    off.dispose();
    on.dispose();
  });

  for (final dark in [false, true]) {
    testWidgets(
        'menu control and enabled badge are bounded in ${dark ? 'dark' : 'light'} mode',
        (tester) async {
      final state = await _makeState(dark: dark);
      await tester.pumpWidget(_host(state, const MenuScreen()));
      expect(find.byKey(const Key('gamebrain-master-control')), findsOneWidget);
      expect(find.text('GameBrain preference'), findsOneWidget);
      expect(find.text('Saved OFF'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(find.text('Saved ON — not active yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(_host(state, const gameplay.GameScreen()));
      expect(find.byKey(const Key('gamebrain-enabled-badge')), findsNothing);
      state.setApprovedGameBrainEligibilityForTesting(true);
      await tester.pump();
      expect(find.byKey(const Key('gamebrain-enabled-badge')), findsOneWidget);
      expect(find.text('GAMEBRAIN ENABLED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<GameState> _makeState({
  Map<String, Object> values = const {},
  bool dark = false,
  QuestionGenerator? questionGenerator,
}) async {
  SharedPreferences.setMockInitialValues(values);
  await Storage.init();
  return _newState(dark: dark, questionGenerator: questionGenerator);
}

Future<GameState> _reloadState({bool dark = false}) async {
  await Storage.init();
  return _newState(dark: dark);
}

Future<GameState> _newState({
  required bool dark,
  QuestionGenerator? questionGenerator,
}) async {
  final settings = SettingsService()
    ..load(
        dark: dark,
        sound: false,
        vibration: false,
        dyslexia: false,
        colorblind: false,
        lowPerf: true,
        reduceMotion: true,
        animSpeed: 1);
  final state = GameState(
    settings: settings,
    audio: AudioService(settings),
    questionGenerator: questionGenerator,
  );
  await state.load();
  addTearDown(state.dispose);
  return state;
}

String _questionSignature(Question question) =>
    '${question.type.name}|${question.diff?.name}|${question.numType?.name}|'
    '${question.key}|${question.text}|${question.ans}|'
    '${question.choices.join(',')}';

Widget _host(GameState state, Widget child) => MultiProvider(
      providers: [
        ChangeNotifierProvider<GameState>.value(value: state),
        ChangeNotifierProvider<SettingsService>.value(value: state.settings),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
