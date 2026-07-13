import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/game_data.dart';
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

  Future<GameState> makeState({
    bool clearStorage = true,
    Map<String, Object>? initialValues,
  }) async {
    if (clearStorage) {
      SharedPreferences.setMockInitialValues(initialValues ?? {});
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
    );
    await state.load();
    addTearDown(state.dispose);
    return state;
  }

  group('RT-001 adaptive difficulty', () {
    test('uses original mastery thresholds', () async {
      final state = await makeState();
      final skill = state.skillMap[Operation.addition.name]!;

      skill.mastery = 44.9;
      expect(state.debugGetAdaptDiff(Operation.addition), Difficulty.easy);

      skill.mastery = 45;
      expect(state.debugGetAdaptDiff(Operation.addition), Difficulty.medium);

      skill.mastery = 64.9;
      expect(state.debugGetAdaptDiff(Operation.addition), Difficulty.medium);

      skill.mastery = 65;
      expect(state.debugGetAdaptDiff(Operation.addition), Difficulty.hard);

      skill.mastery = 81.9;
      expect(state.debugGetAdaptDiff(Operation.addition), Difficulty.hard);

      skill.mastery = 82;
      expect(state.debugGetAdaptDiff(Operation.addition), Difficulty.expert);

      skill.mastery = 92.9;
      expect(state.debugGetAdaptDiff(Operation.addition), Difficulty.expert);

      skill.mastery = 93;
      expect(state.debugGetAdaptDiff(Operation.addition), Difficulty.insane);
    });

    test('missing operation mastery uses the default easy tier', () async {
      final state = await makeState();
      state.skillMap.remove(Operation.addition.name);

      expect(state.debugGetAdaptDiff(Operation.addition), Difficulty.easy);
    });

    test('secondary nudge preserves zero default and asymmetric bounds',
        () async {
      final state = await makeState();
      for (final testCase in const [
        (mastery: 0.0, correct: true, milliseconds: 1999, expected: 20.6),
        (mastery: 100.0, correct: true, milliseconds: 2001, expected: 100.0),
        (mastery: 0.25, correct: false, milliseconds: 0, expected: 0.0),
      ]) {
        state.skillMap[Operation.addition.name] =
            SkillData(mastery: testCase.mastery);

        state.debugUpdateAdapt(
          testCase.correct,
          testCase.milliseconds,
          Operation.addition,
        );

        expect(
          state.skillMap[Operation.addition.name]!.mastery,
          testCase.expected,
          reason: 'mastery=${testCase.mastery}, correct=${testCase.correct}',
        );
      }
    });

    test('secondary nudge leaves a missing skill entry unchanged', () async {
      final state = await makeState();
      state.skillMap.remove(Operation.addition.name);
      state.adaptLvlRaw = 7.25;
      state.adaptLvl = 7;

      state.debugUpdateAdapt(true, 1000, Operation.addition);

      expect(state.skillMap.containsKey(Operation.addition.name), isFalse);
      expect(state.adaptLvlRaw, 7.25);
      expect(state.adaptLvl, 7);
    });

    test('fast correct answer applies source mastery and confidence formulas',
        () async {
      final state = await makeState();

      state.debugRecordAdaptiveAnswer(
        Operation.addition,
        Difficulty.expert,
        true,
        1400,
      );

      final skill = state.skillMap[Operation.addition.name]!;
      expect(skill.expert, 1);
      expect(skill.correct, 1);
      expect(skill.count, 1);
      expect(skill.mastery, closeTo(27.6, 0.0001));
      expect(skill.confidence, 60);
      expect(state.adaptLvlRaw, closeTo(2.19, 0.0001));
      expect(state.adaptLvl, 2);
    });

    test('normal and slow correct answers use original gain tiers', () async {
      final state = await makeState();

      state.debugRecordAdaptiveAnswer(
        Operation.subtraction,
        Difficulty.medium,
        true,
        2500,
      );
      expect(
        state.skillMap[Operation.subtraction.name]!.mastery,
        closeTo(25.2, 0.0001),
      );
      expect(state.skillMap[Operation.subtraction.name]!.confidence, 57);

      state.skillMap[Operation.multiplication.name] = SkillData();
      state.debugRecordAdaptiveAnswer(
        Operation.multiplication,
        Difficulty.insane,
        true,
        3500,
      );
      final skill = state.skillMap[Operation.multiplication.name]!;
      expect(skill.insane, 1);
      expect(skill.mastery, closeTo(23.2, 0.0001));
      expect(skill.confidence, 55);
    });

    test('wrong and timeout answers use original penalties', () async {
      final state = await makeState();
      state.rt.qTimerLimit = 8;

      state.skillMap[Operation.division.name] = SkillData(
        mastery: 50,
        confidence: 50,
      );
      state.debugRecordAdaptiveAnswer(
        Operation.division,
        Difficulty.hard,
        false,
        4000,
      );
      var skill = state.skillMap[Operation.division.name]!;
      expect(skill.hard, 0);
      expect(skill.correct, 0);
      expect(skill.count, 1);
      expect(skill.mastery, closeTo(45.5, 0.0001));
      expect(skill.confidence, 54);

      state.skillMap[Operation.division.name] = SkillData(
        mastery: 50,
        confidence: 50,
      );
      state.debugRecordAdaptiveAnswer(
        Operation.division,
        Difficulty.hard,
        false,
        9000,
      );
      skill = state.skillMap[Operation.division.name]!;
      expect(skill.mastery, closeTo(47.5, 0.0001));
      expect(skill.confidence, 44);
    });

    test('wrong response uses the exact runtime timeout boundary', () async {
      final state = await makeState();
      state.rt.qTimerLimit = 8;

      state.skillMap[Operation.division.name] = SkillData(
        mastery: 50,
        confidence: 50,
      );
      state.debugUpdateSkillMap(
        Operation.division,
        Difficulty.hard,
        false,
        7999,
      );
      expect(state.skillMap[Operation.division.name]!.mastery, 46);

      state.skillMap[Operation.division.name] = SkillData(
        mastery: 50,
        confidence: 50,
      );
      state.debugUpdateSkillMap(
        Operation.division,
        Difficulty.hard,
        false,
        8000,
      );
      expect(state.skillMap[Operation.division.name]!.mastery, 48);
    });

    test('skill data preserves expert and insane counters in JSON', () {
      final skill = SkillData(expert: 2, insane: 3);

      final restored = SkillData.fromJson(skill.toJson());

      expect(restored.expert, 2);
      expect(restored.insane, 3);
    });

    test('stale adaptive level is corrected from loaded skill mastery',
        () async {
      final state = await makeState(initialValues: {
        'mc_adaptLvl': 0.0,
        'mc_skillMap': jsonEncode({
          'addition': {'mastery': 95},
        }),
      });

      expect(state.adaptLvlRaw, closeTo(3.875, 0.0001));
      expect(state.adaptLvl, 4);
    });

    test('missing adaptive level is recomputed from loaded skill mastery',
        () async {
      final state = await makeState(initialValues: {
        'mc_skillMap': jsonEncode({
          'addition': {'mastery': 95},
        }),
      });

      expect(state.adaptLvlRaw, closeTo(3.875, 0.0001));
      expect(state.adaptLvl, 4);
    });

    test('new skill map uses the default adaptive level', () async {
      final state = await makeState();

      expect(state.adaptLvlRaw, 2);
      expect(state.adaptLvl, 2);
    });

    test('reset all data clears adaptive level and skill mastery', () async {
      final state = await makeState(initialValues: {
        'mc_adaptLvl': 9.0,
        'mc_skillMap': jsonEncode({
          'addition': {'mastery': 95},
        }),
      });

      await state.resetAllData();

      expect(state.adaptLvlRaw, 0);
      expect(state.adaptLvl, 0);
      expect(state.skillMap[Operation.addition.name]!.mastery, 20);
    });

    test('skill mastery persists across a fresh session', () async {
      final state = await makeState();
      state.skillMap[Operation.addition.name]!.mastery = 90;
      state.debugRecordAdaptiveAnswer(
        Operation.addition,
        Difficulty.expert,
        true,
        1400,
      );
      await state.save();

      final restored = await makeState(clearStorage: false);
      expect(restored.skillMap[Operation.addition.name]!.mastery, 97.6);
      expect(restored.adaptLvl, 4);
      expect(restored.debugGetAdaptDiff(Operation.addition), Difficulty.insane);
      expect(restored.debugGetAdaptDiff(Operation.division), Difficulty.easy);
    });
  });
}
