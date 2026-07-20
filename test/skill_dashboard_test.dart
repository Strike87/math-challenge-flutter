import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/game_data.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:math_challenge/widgets/modals.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'dashboard shows exactly four canonical mastery skills and is read-only',
    (tester) async {
      final state = await _makeState();
      addTearDown(state.dispose);

      state.skillMap = {
        Operation.addition.name: SkillData(mastery: 95, count: 10),
        Operation.subtraction.name: SkillData(mastery: 72, count: 10),
        Operation.multiplication.name: SkillData(mastery: 85, count: 10),
        Operation.division.name: SkillData(mastery: 60, count: 10),
      };

      // Existing canonical aggregate presented as a percentage.
      state.adaptLvlRaw = 7.8;

      final skillMapBefore = {
        for (final entry in state.skillMap.entries)
          entry.key: entry.value.toJson(),
      };
      final scheduleIndexBefore = state.rt.weakSkillsScheduleIndex;

      expect(state.setupWeakSkillsPlan, isNull);

      state.showModal(GameModal.skillDashboard);
      await _pumpDashboard(tester, state);

      expect(find.text('Skills Dashboard'), findsOneWidget);
      expect(find.text('Overall Mastery'), findsOneWidget);
      expect(find.text('78%'), findsOneWidget);
      expect(find.text('YOUR SKILLS'), findsOneWidget);

      for (final skill in [
        'Addition',
        'Subtraction',
        'Multiplication',
        'Division',
      ]) {
        expect(find.text(skill), findsOneWidget);
      }

      for (final percentage in [
        '95%',
        '72%',
        '85%',
        '60%',
      ]) {
        expect(find.text(percentage), findsOneWidget);
      }

      // No fifth canonical mastery skill.
      expect(find.text('Operation Sense'), findsNothing);
      expect(find.text('Logic'), findsNothing);
      expect(find.text('Missing Operation'), findsNothing);

      // Merely opening/rendering the dashboard must not create
      // or consume Weak Skills setup state.
      expect(state.setupWeakSkillsPlan, isNull);
      expect(state.rt.weakSkillsScheduleIndex, scheduleIndexBefore);

      expect(
        {
          for (final entry in state.skillMap.entries)
            entry.key: entry.value.toJson(),
        },
        skillMapBefore,
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dashboard presents focused Weak Skills recommendation without consuming it',
    (tester) async {
      final state = await _makeState();
      addTearDown(state.dispose);

      state.skillMap = {
        Operation.addition.name: SkillData(mastery: 5, count: 3),
        Operation.subtraction.name: SkillData(mastery: 20, count: 3),
        Operation.multiplication.name: SkillData(mastery: 30, count: 3),
        Operation.division.name: SkillData(mastery: 40, count: 3),
      };

      expect(state.setupWeakSkillsPlan, isNull);

      state.showModal(GameModal.skillDashboard);
      await _pumpDashboard(tester, state);

      expect(find.text('Recommended Practice'), findsOneWidget);
      expect(find.text('Build Your Skills'), findsOneWidget);
      expect(find.text('Focus on Addition and Subtraction'), findsOneWidget);

      // Previewing the recommendation must remain read-only.
      expect(state.setupWeakSkillsPlan, isNull);
      expect(state.rt.weakSkillsScheduleIndex, 0);
    },
  );

  testWidgets(
    'dashboard presents fallback recommendation for insufficient evidence',
    (tester) async {
      final state = await _makeState();
      addTearDown(state.dispose);

      state.showModal(GameModal.skillDashboard);
      await _pumpDashboard(tester, state);

      expect(find.text('Build Your Practice Profile'), findsOneWidget);
      expect(find.text('Build Your Skills'), findsOneWidget);
      expect(
        find.text(
          'Practice all four operations to personalize your recommendations.',
        ),
        findsOneWidget,
      );

      expect(state.setupWeakSkillsPlan, isNull);
      expect(state.rt.weakSkillsScheduleIndex, 0);
    },
  );

  testWidgets(
    'recommendation card enters the existing Weak Skills flow',
    (tester) async {
      final state = await _makeState();
      addTearDown(state.dispose);

      state.skillMap = {
        Operation.addition.name: SkillData(mastery: 5, count: 3),
        Operation.subtraction.name: SkillData(mastery: 20, count: 3),
        Operation.multiplication.name: SkillData(mastery: 30, count: 3),
        Operation.division.name: SkillData(mastery: 40, count: 3),
      };

      state.showModal(GameModal.skillDashboard);
      await _pumpDashboard(tester, state);

      expect(state.setupWeakSkillsPlan, isNull);

      final recommendationCard = find.byKey(
        const Key('skill-dashboard-weak-skills-recommendation'),
      );

      await tester.ensureVisible(recommendationCard);
      await tester.pumpAndSettle();

      await tester.tap(recommendationCard);
      await tester.pumpAndSettle();

      expect(state.currentModal, GameModal.weakSkillsPractice);
      expect(state.setupWeakSkillsPlan, isNotNull);
      expect(state.setupWeakSkillsPlan!.isFallback, isFalse);

      // Existing popup/orchestration remains in control.
      expect(find.text('Recommended Practice'), findsOneWidget);
      expect(find.text('Practice areas'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    },
  );
}

Future<void> _pumpDashboard(
  WidgetTester tester,
  GameState state,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;

  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(
          value: state.settings,
        ),
        ChangeNotifierProvider<GameState>.value(
          value: state,
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: ModalRouter(),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Future<GameState> _makeState() async {
  SharedPreferences.setMockInitialValues({});
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
    audio: _NoOpAudioService(),
  );

  await state.load();
  return state;
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
