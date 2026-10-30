import 'dart:async';
import 'dart:io';
import 'dart:math';

// ignore: depend_on_referenced_packages
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:ui' as ui;
import 'package:math_challenge/game_config.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/family/domain/family_eligibility.dart';
import 'package:math_challenge/features/target_clash/domain/presentation_answer.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_run_config.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_runtime_state.dart';
import 'package:math_challenge/main.dart' as app;
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/math_fact.dart';
import 'package:math_challenge/models/player.dart';
import 'package:math_challenge/services/admob.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/iap.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _root = ValueKey('target-clash-v5-capture-root');

Future<void> _loadFonts() async {
  final baloo = FontLoader('Baloo2')
    ..addFont(rootBundle.load('assets/fonts/Baloo2-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Baloo2-ExtraBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Baloo2-Black.ttf'));
  await baloo.load();
  final jakarta = FontLoader('PlusJakartaSans')
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-ExtraBold.ttf'));
  await jakarta.load();
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await materialIcons.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AudioplayersPlatformInterface.instance = _SilentAudioplayersPlatform();
  setUpAll(_loadFonts);

  TargetClashRunConfig config([Difficulty difficulty = Difficulty.easy]) =>
      TargetClashRunConfig.tryCreate(
        operation: Operation.addition,
        difficulty: difficulty,
        numberType: NumberType.integers,
      )!;

  void resolve(GameState state) {
    state.onTargetClashAnswer(state.targetClashQuestion!.correctAnswer);
    state.debugCompleteTargetClashRevealForTest();
  }

  Finder answerControl(GameState state) =>
      switch (state.targetClashQuestion!.correctAnswer) {
        PresentationAnswer.lessThan =>
          find.byKey(const Key('target-clash-relation-less')),
        PresentationAnswer.equalTo =>
          find.byKey(const Key('target-clash-relation-equal')),
        PresentationAnswer.greaterThan =>
          find.byKey(const Key('target-clash-relation-greater')),
      };

  Future<GameState> longNegativeBossFeverState() async {
    final settings = SettingsService();
    settings.load(
      dark: false,
      sound: false,
      vibration: false,
      dyslexia: false,
      colorblind: false,
      lowPerf: true,
      reduceMotion: true,
      animSpeed: 1,
      notify: false,
    );
    final state = GameState(
      settings: settings,
      audio: _NoOpAudioService(),
      adService: const UnavailableAdMobService(),
      iapAdapter: DevIapPurchaseAdapter(isNativeRelease: false),
      questionGenerator: _LongNegativeQuestionGenerator(mixedSignDirect: true),
    );
    state.debugStartTargetClashForTest(config(Difficulty.hard));
    for (var i = 0; i < 9; i++) {
      resolve(state);
    }
    expect(state.targetClashRuntime!.phase, TargetClashPhase.boss);
    expect(state.targetClashRuntime!.isFeverActive, isTrue);
    expect(state.targetClashRuntime!.feverRemaining, 3);
    return state;
  }

  GameState captureState({
    bool dark = false,
    bool lowPerf = true,
    bool reduceMotion = true,
  }) {
    final settings = SettingsService();
    settings.load(
      dark: dark,
      sound: false,
      vibration: false,
      dyslexia: false,
      colorblind: false,
      lowPerf: lowPerf,
      reduceMotion: reduceMotion,
      animSpeed: 1,
      notify: false,
    );
    return GameState(
      settings: settings,
      audio: _NoOpAudioService(),
      adService: const UnavailableAdMobService(),
      iapAdapter: DevIapPurchaseAdapter(isNativeRelease: false),
      questionGenerator: _LongNegativeQuestionGenerator(anchorResult: 12),
    );
  }

  Future<GameState> animatedState({
    Difficulty difficulty = Difficulty.easy,
    bool reduceMotion = false,
  }) async {
    final state = captureState(lowPerf: false, reduceMotion: reduceMotion);
    state.debugStartTargetClashForTest(config(difficulty));
    return state;
  }

  Future<void> prepareApp({
    required bool dark,
    bool lowPerf = true,
    bool reduceMotion = true,
  }) async {
    SharedPreferences.setMockInitialValues({
      GameState.familyGateVersionStorageKey: GameState.familyGateSchemaVersion,
      GameState.familyAgeRangeStorageKey: FamilyAgeRange.adult18plus.name,
      'mc_dark': dark,
      'mc_sound': false,
      'mc_vibration': false,
      'mc_lowPerf': lowPerf,
      'mc_reduceMotion': reduceMotion,
    });
    await Storage.init();
    await Storage.setBool('mc_dark', dark);
    await Storage.setBool('mc_lowPerf', lowPerf);
    await Storage.setBool('mc_reduceMotion', reduceMotion);
  }

  Widget host({GameState? testGameState}) => RepaintBoundary(
        key: _root,
        child: app.MathChallengeApp(
          adService: UnavailableAdMobService(),
          iapAdapter: DevIapPurchaseAdapter(isNativeRelease: false),
          testGameState: testGameState,
        ),
      );

  void viewport(WidgetTester tester, Size size, {double safeBottom = 0}) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    tester.view.padding = FakeViewPadding(bottom: safeBottom);
    tester.platformDispatcher.textScaleFactorTestValue = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  void installAudioMocks() {
    const audioGlobal = MethodChannel('xyz.luan/audioplayers.global');
    const audioGlobalEvents =
        EventChannel('xyz.luan/audioplayers.global/events');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(audioGlobal, (_) async => null);
    messenger.setMockStreamHandler(
      audioGlobalEvents,
      const MockStreamHandler.inline(onListen: _ignoreAudioEvents),
    );
  }

  Future<void> syncInjectedSettings(
      WidgetTester tester, GameState injected) async {
    final appSettings = Provider.of<SettingsService>(
      tester.element(find.byType(Scaffold)),
      listen: false,
    );
    final settings = injected.settings;
    appSettings.load(
      dark: settings.dark,
      sound: settings.sound,
      vibration: settings.vibration,
      dyslexia: settings.dyslexia,
      colorblind: settings.colorblind,
      lowPerf: settings.lowPerf,
      reduceMotion: settings.manualReduceMotion,
      animSpeed: settings.animSpeed,
    );
    await tester.pump();
  }

  Future<GameState> mountInjected(
    WidgetTester tester,
    GameState state, {
    Size size = const Size(390, 844),
    bool reduceMotion = false,
  }) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await prepareApp(
      dark: false,
      lowPerf: false,
      reduceMotion: reduceMotion,
    );
    viewport(tester, size);
    installAudioMocks();
    await tester.pumpWidget(host(testGameState: state));
    await tester.pump();
    await syncInjectedSettings(tester, state);
    final mounted = Provider.of<GameState>(
      tester.element(find.byType(Scaffold)),
      listen: false,
    );
    expect(mounted, same(state));
    return mounted;
  }

  Future<File> capture(WidgetTester tester, String name) async {
    // ignore: avoid_print
    print('TC_V5_CAPTURE $name pump:before');
    await tester.pump();
    // ignore: avoid_print
    print('TC_V5_CAPTURE $name pump:after');
    expect(tester.takeException(), isNull);
    final output = Platform.environment['TC_V5_CAPTURE_DIR'];
    expect(output, isNotNull,
        reason: 'The disposable CI capture directory must be supplied.');
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(_root));
    final result = await tester.runAsync(() async {
      ui.Image? image;
      try {
        // ignore: avoid_print
        print('TC_V5_CAPTURE $name toImage:before');
        image = await boundary.toImage(pixelRatio: 1.0);
        // ignore: avoid_print
        print(
            'TC_V5_CAPTURE $name toImage:after ${image.width}x${image.height}');
        final expectedSize = tester.view.physicalSize;
        if (image.width != expectedSize.width ||
            image.height != expectedSize.height) {
          throw StateError(
              'Expected ${expectedSize.width}x${expectedSize.height}, got ${image.width}x${image.height}.');
        }
        // ignore: avoid_print
        print('TC_V5_CAPTURE $name toByteData:before');
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        // ignore: avoid_print
        print('TC_V5_CAPTURE $name toByteData:after');
        if (bytes == null) {
          throw StateError('PNG encoding returned no bytes.');
        }
        final png = List<int>.of(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        final file = File('$output/$name');
        // ignore: avoid_print
        print('TC_V5_CAPTURE $name file-create:before');
        await file.parent.create(recursive: true);
        // ignore: avoid_print
        print('TC_V5_CAPTURE $name file-create:after');
        // ignore: avoid_print
        print('TC_V5_CAPTURE $name file-write:before');
        await file.writeAsBytes(png, flush: true);
        // ignore: avoid_print
        print('TC_V5_CAPTURE $name file-write:after');
        if (!await file.exists()) {
          throw StateError('Capture file was not written: ${file.path}');
        }
        return (file: file, width: image.width, height: image.height);
      } finally {
        image?.dispose();
        // ignore: avoid_print
        print('TC_V5_CAPTURE $name image-dispose:after');
      }
    });
    expect(result, isNotNull);
    // This is retained in the CI test log beside the artifact name.
    // ignore: avoid_print
    print('TC_V5_CAPTURE $name complete ${result!.width}x${result.height}');
    expect(tester.takeException(), isNull);
    return result.file;
  }

  Color segmentColor(WidgetTester tester, int index) {
    final segment = tester.widget<AnimatedContainer>(
      find.byKey(Key('target-clash-power-segment-$index')),
    );
    return (segment.decoration! as BoxDecoration).color!;
  }

  void expectNativeRelationGlyph(
      WidgetTester tester, Finder answer, double scale) {
    final richText =
        find.descendant(of: answer, matching: find.byType(RichText));
    final paragraph = tester.renderObject<RenderParagraph>(richText);
    expect(paragraph.textScaler.scale(36), closeTo(36 * scale, .01));
    expect(MediaQuery.textScalerOf(tester.element(richText)).scale(36),
        closeTo(36 * scale, .01));
    final natural = TextPainter(
      text: paragraph.text,
      textDirection: paragraph.textDirection,
      textAlign: paragraph.textAlign,
      textScaler: paragraph.textScaler,
      locale: paragraph.locale,
      textHeightBehavior: paragraph.textHeightBehavior,
    )..layout();
    try {
      final origin = paragraph.localToGlobal(Offset.zero);
      final nativeBounds = origin & natural.size;
      final renderedBounds = origin & paragraph.size;
      final buttonBounds = tester.getRect(answer).inflate(.01);
      // The native Baloo glyph must fit without shrinking accessibility text.
      expect(paragraph.size.height, greaterThanOrEqualTo(natural.height - .01),
          reason: 'The relation paragraph must retain its native line height.');
      expect(paragraph.size.width, greaterThanOrEqualTo(natural.width - .01));
      for (final bounds in [nativeBounds, renderedBounds]) {
        expect(buttonBounds.contains(bounds.topLeft), isTrue);
        expect(buttonBounds.contains(bounds.bottomRight), isTrue,
            reason: 'The complete scaled relation glyph must fit its button.');
      }
      // ignore: avoid_print
      print('TC_RELATION_GLYPH ${paragraph.text.toPlainText()} scale=$scale '
          'native=${natural.size} rendered=${paragraph.size} '
          'button=${tester.getSize(answer)}');
    } finally {
      natural.dispose();
    }
  }

  Future<void> capturePhase(
    WidgetTester tester,
    String name, {
    required Difficulty difficulty,
    required int resolves,
    required TargetClashPhase expectedPhase,
    required bool expectedFever,
    bool dark = false,
    Size size = const Size(390, 844),
    bool reveal = false,
    Future<void> Function(WidgetTester tester)? beforeCapture,
  }) async {
    installAudioMocks();
    await prepareApp(dark: dark);
    viewport(tester, size);
    final injected = captureState(dark: dark);
    await tester.pumpWidget(host(testGameState: injected));
    await tester.pump();
    await syncInjectedSettings(tester, injected);
    final current = Provider.of<GameState>(
      tester.element(find.byType(Scaffold)),
      listen: false,
    );
    var ready = false;
    for (var attempt = 0; attempt < 4 && !ready; attempt++) {
      current.debugStartTargetClashForTest(config(difficulty));
      ready = current.targetClashQuestion != null;
      for (var i = 0; i < resolves && ready; i++) {
        resolve(current);
        ready = current.targetClashQuestion != null;
      }
    }
    expect(ready, isTrue,
        reason: 'The real app shell did not prepare a Target Clash question.');
    expect(current.targetClashRuntime!.phase, expectedPhase);
    expect(current.targetClashRuntime!.isFeverActive, expectedFever);
    if (reveal) {
      current.onTargetClashAnswer(current.targetClashQuestion!.correctAnswer);
      expect(current.targetClashReveal, isNotNull);
    }
    // ignore: avoid_print
    print('TC_V5_CAPTURE $name pumpWidget:before');
    await tester.pump();
    // ignore: avoid_print
    print('TC_V5_CAPTURE $name pumpWidget:after');
    if (beforeCapture != null) {
      await beforeCapture(tester);
      expect(tester.takeException(), isNull);
    }
    await capture(tester, name);
    // ignore: avoid_print
    print('TC_V5_CAPTURE $name phase-cleanup:before');
    await current.quitToMenu();
    // ignore: avoid_print
    print('TC_V5_CAPTURE $name phase-cleanup:after');
  }

  Future<void> captureLongNegativeBossFever(
    WidgetTester tester,
    String name, {
    required Size size,
  }) async {
    await prepareApp(dark: false);
    viewport(tester, size, safeBottom: 24);
    installAudioMocks();
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    final injected = await longNegativeBossFeverState();
    await tester.pumpWidget(host(testGameState: injected));
    await tester.pump();
    await syncInjectedSettings(tester, injected);
    final mounted = Provider.of<GameState>(
      tester.element(find.byType(Scaffold)),
      listen: false,
    );
    expect(mounted, same(injected));
    expect(mounted.targetClashRuntime!.phase, TargetClashPhase.boss);
    expect(mounted.targetClashRuntime!.isFeverActive, isTrue);
    await tester.pump();
    final viewportBounds = Rect.fromLTWH(0, 0, size.width, size.height);
    final expression = find.byKey(const Key('target-clash-expression'));
    final prompt = find.text('Choose the correct relation');
    final scrollable = find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        )
        .last;
    final position = tester.state<ScrollableState>(scrollable).position;
    expect(position.pixels, 0,
        reason: 'The initial AppShell capture must retain offset zero.');
    final promptBounds = tester.getRect(prompt);
    expect(viewportBounds.contains(promptBounds.topLeft), isTrue,
        reason: 'The initial capture must show the complete prompt.');
    expect(viewportBounds.contains(promptBounds.bottomRight), isTrue,
        reason: 'The prompt must not be clipped at 1.5x text scale.');
    expect(tester.view.padding.bottom, 24,
        reason: 'The evidence fixture must use a realistic 24px bottom inset.');
    final expressionBounds = tester.getRect(expression);
    expect(viewportBounds.contains(expressionBounds.topLeft), isTrue,
        reason: 'The complete long-negative expression must be reachable.');
    expect(viewportBounds.contains(expressionBounds.bottomRight), isTrue,
        reason: 'The complete long-negative expression must not be clipped.');
    final initial = await capture(tester, name);
    final requiresScrollableAnswers = size == const Size(320, 568);
    if (requiresScrollableAnswers) {
      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pump();
      expect(position.pixels, greaterThan(0),
          reason: 'The compact answers evidence must use a genuine user-style '
              'scroll.');
    }
    for (final key in const [
      Key('target-clash-relation-less'),
      Key('target-clash-relation-equal'),
      Key('target-clash-relation-greater'),
    ]) {
      final answer = find.byKey(key);
      final answerBounds = tester.getRect(answer);
      expect(viewportBounds.contains(answerBounds.topLeft), isTrue,
          reason: '$key must be reachable.');
      expect(viewportBounds.contains(answerBounds.bottomRight), isTrue,
          reason: '$key must not be clipped.');
    }
    if (requiresScrollableAnswers) {
      final answers = await capture(
          tester, name.replaceFirst('.png', '_answers_reachable.png'));
      final initialLength = initial.lengthSync();
      final answersLength = answers.lengthSync();
      expect(initialLength, isNot(answersLength),
          reason: 'Initial and scrolled evidence must be distinct PNG frames.');
      // ignore: avoid_print
      print(
        'TC_V5_CAPTURE_BYTE_COMPARE initial=$initialLength '
        'answers=$answersLength distinct=true',
      );
    }
    await mounted.quitToMenu();
  }

  for (final dark in [false, true]) {
    for (final viewportCase in const [
      (Size(320, 568), 1.5),
      (Size(360, 800), 1.0),
      (Size(360, 800), 1.5),
      (Size(390, 844), 1.0),
      (Size(390, 844), 1.5),
    ]) {
      final size = viewportCase.$1;
      final scale = viewportCase.$2;
      final theme = dark ? 'dark' : 'light';
      final suffix =
          '${theme}_${size.width.toInt()}x${size.height.toInt()}_${scale.toString().replaceAll('.', '_')}x';
      testWidgets('captures icon arsenal matrix $suffix', (tester) async {
        installAudioMocks();
        await prepareApp(dark: dark);
        viewport(tester, size, safeBottom: 24);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        final state = captureState(dark: dark);
        state.debugStartTargetClashForTest(config());
        await tester.pumpWidget(host(testGameState: state));
        await tester.pump();
        await syncInjectedSettings(tester, state);
        await tester.pump();
        final row = find.byKey(const Key('target-clash-arsenal-row'));
        final buttons =
            find.descendant(of: row, matching: find.byType(OutlinedButton));
        expect(buttons, findsNWidgets(4));
        expect(find.descendant(of: row, matching: find.byType(Text)),
            findsNothing);
        expect(find.descendant(of: row, matching: find.byType(Scrollable)),
            findsNothing);
        final bounds =
            List.generate(4, (index) => tester.getRect(buttons.at(index)));
        for (var index = 0; index < bounds.length; index++) {
          final rect = bounds[index];
          expect(rect.top, bounds.first.top);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(buttons.at(index).hitTestable(), findsOneWidget);
          if (index > 0)
            expect(bounds[index - 1].right, lessThanOrEqualTo(rect.left));
        }
        expect(tester.getRect(find.byKey(const Key('target-clash-hud'))).bottom,
            lessThanOrEqualTo(tester.getRect(row).top));
        expect(
            tester.getRect(row).bottom,
            lessThanOrEqualTo(tester
                .getRect(find.byKey(const Key('target-clash-question-panel')))
                .top));
        await capture(tester, 'arsenal_icon_$suffix.png');
        final question = find.byKey(const Key('target-clash-question-panel'));
        await tester.ensureVisible(question);
        await tester.pump();
        final questionBounds = tester.getRect(question);
        expect(questionBounds.top, greaterThanOrEqualTo(0));
        expect(questionBounds.bottom, lessThanOrEqualTo(size.height - 24));
        expect(find.byKey(const Key('target-clash-expression')).hitTestable(),
            findsOneWidget);
        for (final key in const [
          Key('target-clash-relation-less'),
          Key('target-clash-relation-equal'),
          Key('target-clash-relation-greater')
        ]) {
          final answer = find.descendant(
              of: find.byKey(key), matching: find.byType(OutlinedButton));
          await tester.ensureVisible(answer);
          await tester.pump();
          final rect = tester.getRect(answer);
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(answer.hitTestable(), findsOneWidget);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.bottom, lessThanOrEqualTo(size.height - 24));
          expectNativeRelationGlyph(tester, answer, scale);
        }
        final answerRects = ['less', 'equal', 'greater']
            .map((id) =>
                tester.getRect(find.byKey(Key('target-clash-relation-$id'))))
            .toList();
        expect(answerRects[0].right, lessThanOrEqualTo(answerRects[1].left));
        expect(answerRects[1].right, lessThanOrEqualTo(answerRects[2].left));
        await capture(tester, 'arsenal_icon_${suffix}_answers.png');
        if (size == const Size(320, 568)) {
          state.onTargetClashAnswer(state.targetClashQuestion!.correctAnswer);
          await tester.pump();
          expect(state.targetClashReveal, isNotNull);
          for (final key in const [
            Key('target-clash-relation-less'),
            Key('target-clash-relation-equal'),
            Key('target-clash-relation-greater'),
          ]) {
            final answer = find.descendant(
                of: find.byKey(key), matching: find.byType(OutlinedButton));
            await tester.ensureVisible(answer);
            await tester.pump();
            expectNativeRelationGlyph(tester, answer, scale);
          }
          await capture(tester, 'arsenal_icon_${suffix}_reveal_answers.png');
        }
        expect(tester.takeException(), isNull);
        await state.quitToMenu();
      });
    }
  }

  testWidgets(
      'captures icon arsenal available armed consumed and memory states',
      (tester) async {
    final state = await longNegativeBossFeverState();
    await mountInjected(tester, state, reduceMotion: true);
    await capture(tester, 'arsenal_icon_boss_available_390x844.png');
    expect(state.activateClashLens(), isTrue);
    expect(state.activateClashScan(), isTrue);
    expect(state.activateClashGuard(), isTrue);
    await tester.pump();
    await capture(tester, 'arsenal_icon_boss_armed_390x844.png');
    resolve(state);
    await tester.pump();
    await capture(tester, 'arsenal_icon_boss_consumed_390x844.png');
    state.debugStartTargetClashForTest(config(Difficulty.medium));
    while (!state.targetClashRuntime!.isTriple) {
      resolve(state);
    }
    resolve(state);
    await tester.pump();
    expect(state.clashTripleHistory, hasLength(1));
    await capture(tester, 'arsenal_icon_memory_available_390x844.png');
    await state.quitToMenu();
  });

  testWidgets('captures ordinary light 390x844', (tester) async {
    await capturePhase(
      tester,
      'ordinary_light_390x844.png',
      difficulty: Difficulty.easy,
      resolves: 0,
      expectedPhase: TargetClashPhase.ordinaryStage1,
      expectedFever: false,
    );
  });

  testWidgets('captures ordinary dark 390x844', (tester) async {
    await capturePhase(
      tester,
      'ordinary_dark_390x844.png',
      difficulty: Difficulty.easy,
      resolves: 0,
      expectedPhase: TargetClashPhase.ordinaryStage1,
      expectedFever: false,
      dark: true,
    );
  });

  testWidgets('captures visible empty Clash Power tracks in both themes',
      (tester) async {
    await capturePhase(
      tester,
      'power_empty_light_390x844.png',
      difficulty: Difficulty.easy,
      resolves: 0,
      expectedPhase: TargetClashPhase.ordinaryStage1,
      expectedFever: false,
      beforeCapture: (tester) async {
        expect(segmentColor(tester, 0), isNot(Colors.transparent));
      },
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await capturePhase(
      tester,
      'power_empty_dark_390x844.png',
      difficulty: Difficulty.easy,
      resolves: 0,
      expectedPhase: TargetClashPhase.ordinaryStage1,
      expectedFever: false,
      dark: true,
      beforeCapture: (tester) async {
        await tester.pump(const Duration(milliseconds: 220));
        final darkTrack = segmentColor(tester, 0);
        expect(darkTrack, isNot(Colors.transparent));
      },
    );
  });

  testWidgets('captures dark Clash Power at zero, three, and six',
      (tester) async {
    await capturePhase(
      tester,
      'power_0_dark_390x844.png',
      difficulty: Difficulty.easy,
      resolves: 0,
      expectedPhase: TargetClashPhase.ordinaryStage1,
      expectedFever: false,
      dark: true,
      beforeCapture: (tester) async {
        final empty = segmentColor(tester, 0);
        expect(empty, isNot(Colors.white));
        for (var i = 1; i < 6; i++) {
          expect(segmentColor(tester, i), empty);
        }
      },
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await capturePhase(
      tester,
      'power_3_dark_390x844.png',
      difficulty: Difficulty.easy,
      resolves: 0,
      expectedPhase: TargetClashPhase.ordinaryStage1,
      expectedFever: false,
      dark: true,
      beforeCapture: (tester) async {
        final state = Provider.of<GameState>(
          tester.element(find.byType(Scaffold)),
          listen: false,
        );
        resolve(state);
        resolve(state);
        expect(state.targetClashQuestion!.correctAnswer,
            PresentationAnswer.equalTo);
        state.onTargetClashAnswer(PresentationAnswer.lessThan);
        state.debugCompleteTargetClashRevealForTest();
        resolve(state);
        await tester.pump();
        expect(state.targetClashRuntime!.clashPower, 3);
        expect(state.targetClashReveal, isNull);
        expect(segmentColor(tester, 2), isNot(segmentColor(tester, 3)));
      },
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await capturePhase(
      tester,
      'power_6_dark_390x844.png',
      difficulty: Difficulty.easy,
      resolves: 5,
      expectedPhase: TargetClashPhase.ordinaryStage2,
      expectedFever: false,
      dark: true,
      beforeCapture: (tester) async {
        final state = Provider.of<GameState>(
          tester.element(find.byType(Scaffold)),
          listen: false,
        );
        expect(state.targetClashRuntime!.clashPower, 6);
        expect(state.targetClashRuntime!.isPowerShotReady, isTrue);
        for (var i = 1; i < 6; i++) {
          expect(segmentColor(tester, i), segmentColor(tester, 0));
        }
      },
    );
  });

  testWidgets('captures triple clash light 390x844', (tester) async {
    await capturePhase(
      tester,
      'triple_light_390x844.png',
      difficulty: Difficulty.medium,
      resolves: 6,
      expectedPhase: TargetClashPhase.triple,
      expectedFever: false,
    );
  });

  testWidgets('captures triple clash dark 390x844', (tester) async {
    await capturePhase(
      tester,
      'triple_dark_390x844.png',
      difficulty: Difficulty.medium,
      resolves: 6,
      expectedPhase: TargetClashPhase.triple,
      expectedFever: false,
      dark: true,
    );
  });

  testWidgets('captures fever light 390x844', (tester) async {
    await capturePhase(
      tester,
      'fever_light_390x844.png',
      difficulty: Difficulty.hard,
      resolves: 9,
      expectedPhase: TargetClashPhase.boss,
      expectedFever: true,
    );
  });

  testWidgets('captures boss light 390x844', (tester) async {
    await capturePhase(
      tester,
      'boss_light_390x844.png',
      difficulty: Difficulty.medium,
      resolves: 9,
      expectedPhase: TargetClashPhase.boss,
      expectedFever: false,
    );
  });

  testWidgets('captures final target light 390x844', (tester) async {
    await capturePhase(
      tester,
      'final_target_light_390x844.png',
      difficulty: Difficulty.easy,
      resolves: 9,
      expectedPhase: TargetClashPhase.finalTarget,
      expectedFever: false,
    );
  });

  testWidgets('captures boss dark 390x844', (tester) async {
    await capturePhase(
      tester,
      'boss_dark_390x844.png',
      difficulty: Difficulty.medium,
      resolves: 9,
      expectedPhase: TargetClashPhase.boss,
      expectedFever: false,
      dark: true,
    );
  });

  testWidgets('captures fever dark 390x844', (tester) async {
    await capturePhase(
      tester,
      'fever_dark_390x844.png',
      difficulty: Difficulty.hard,
      resolves: 9,
      expectedPhase: TargetClashPhase.boss,
      expectedFever: true,
      dark: true,
    );
  });

  for (final size in const [Size(320, 568), Size(360, 800)]) {
    testWidgets('captures ordinary light $size', (tester) async {
      await capturePhase(
        tester,
        'ordinary_light_${size.width.toInt()}x${size.height.toInt()}.png',
        difficulty: Difficulty.easy,
        resolves: 0,
        expectedPhase: TargetClashPhase.ordinaryStage1,
        expectedFever: false,
        size: size,
      );
    });
  }

  testWidgets('captures landscape answers after supported scroll',
      (tester) async {
    await capturePhase(
      tester,
      'ordinary_light_844x390_answers_visible.png',
      difficulty: Difficulty.easy,
      resolves: 0,
      expectedPhase: TargetClashPhase.ordinaryStage1,
      expectedFever: false,
      size: const Size(844, 390),
      beforeCapture: (tester) async {
        await tester.drag(
          find.byType(SingleChildScrollView).last,
          const Offset(0, -300),
        );
        await tester.pump();

        final viewport = const Rect.fromLTWH(0, 0, 844, 390);
        for (final key in const [
          Key('target-clash-relation-less'),
          Key('target-clash-relation-equal'),
          Key('target-clash-relation-greater'),
        ]) {
          final bounds = tester.getRect(find.byKey(key));
          expect(viewport.contains(bounds.topLeft), isTrue,
              reason: '$key must be reachable after scrolling.');
          expect(viewport.contains(bounds.bottomRight), isTrue,
              reason: '$key must be fully visible after scrolling.');
        }
      },
    );
  });

  testWidgets('captures canonical reveal light 390x844', (tester) async {
    await capturePhase(
      tester,
      'reveal_light_390x844.png',
      difficulty: Difficulty.easy,
      resolves: 0,
      expectedPhase: TargetClashPhase.ordinaryStage1,
      expectedFever: false,
      reveal: true,
    );
  });

  for (final size in const [Size(320, 568), Size(360, 800), Size(390, 844)]) {
    testWidgets('captures injected long-negative Boss Fever $size',
        (tester) async {
      await captureLongNegativeBossFever(
        tester,
        'boss_fever_long_negative_${size.width.toInt()}x${size.height.toInt()}.png',
        size: size,
      );
      final expression = find.byKey(const Key('target-clash-expression'));
      expect(expression, findsOneWidget);
      final bounds = tester.getRect(expression);
      expect(bounds.width, greaterThan(0));
    });
  }

  testWidgets('captures finite authoritative premium motion frames',
      (tester) async {
    final ordinary = await animatedState();
    await mountInjected(tester, ordinary);
    final answer = answerControl(ordinary);
    final press = await tester.startGesture(tester.getCenter(answer));
    await tester.pump();
    await capture(tester, 'motion_answer_pointer_down.png');
    await press.up();
    await tester.pump();
    expect(ordinary.targetClashReveal, isNotNull);
    await capture(tester, 'motion_answer_reveal_feedback.png');
    expect(ordinary.targetClashRuntime!.clashPower, 1);
    await capture(tester, 'motion_power_fill_start.png');
    await tester.pump(const Duration(milliseconds: 100));
    await capture(tester, 'motion_power_fill_mid.png');
    await tester.pump(const Duration(milliseconds: 140));
    await capture(tester, 'motion_power_fill_settled.png');
    ordinary.debugCompleteTargetClashRevealForTest();
    await tester.pump();
    await capture(tester, 'motion_question_transition_immediate.png');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Choose the correct relation'), findsOneWidget);
    expect(find.byKey(const Key('target-clash-expression')), findsOneWidget);
    await capture(tester, 'motion_question_transition_mid.png');
    await tester.pump(const Duration(milliseconds: 140));
    expect(find.text('Choose the correct relation'), findsOneWidget);
    expect(find.byKey(const Key('target-clash-expression')), findsOneWidget);
    await capture(tester, 'motion_question_transition_settled.png');
    await ordinary.quitToMenu();

    final boss = await animatedState(difficulty: Difficulty.hard);
    await mountInjected(tester, boss);
    for (var i = 0; i < 9; i++) {
      resolve(boss);
    }
    await tester.pump();
    expect(boss.targetClashRuntime!.phase, TargetClashPhase.boss);
    expect(boss.targetClashRuntime!.isFeverActive, isTrue);
    final healthBefore = boss.targetClashRuntime!.bossHealth;
    await capture(tester, 'motion_boss_health_before.png');
    boss.onTargetClashAnswer(boss.targetClashQuestion!.correctAnswer);
    await tester.pump();
    expect(boss.targetClashRuntime!.bossHealth, lessThan(healthBefore));
    await capture(tester, 'motion_boss_health_damage.png');
    await tester.pump(const Duration(milliseconds: 100));
    await capture(tester, 'motion_boss_health_100ms.png');
    await tester.pump(const Duration(milliseconds: 140));
    await capture(tester, 'motion_boss_health_settled.png');
    boss.debugCompleteTargetClashRevealForTest();
    await boss.quitToMenu();

    final entries = await animatedState(difficulty: Difficulty.hard);
    await mountInjected(tester, entries);
    entries.debugStartTargetClashForTest(config(Difficulty.hard));
    for (var i = 0; i < 6; i++) {
      resolve(entries);
    }
    await tester.pump();
    expect(entries.targetClashRuntime!.isTriple, isTrue);
    final tripleHud = tester.widget<AnimatedContainer>(
      find.byKey(const Key('target-clash-hud')),
    );
    expect(
      (tripleHud.decoration! as BoxDecoration).color,
      isNot(const Color(GameConfig.grape)),
      reason: 'Triple Grape must stay a focused phase accent, not a HUD wash.',
    );
    await capture(tester, 'motion_triple_entry_immediate.png');
    await tester.pump(const Duration(milliseconds: 220));
    await capture(tester, 'motion_triple_entry_settled.png');
    for (var i = 0; i < 3; i++) {
      resolve(entries);
    }
    await tester.pump();
    expect(entries.targetClashRuntime!.isFeverActive, isTrue);
    final fever = tester.widget<AnimatedContainer>(
      find.byKey(const Key('target-clash-fever')),
    );
    expect(
      ((fever.decoration! as BoxDecoration).color!.toARGB32()),
      const Color(GameConfig.mango).withValues(alpha: .34).toARGB32(),
      reason: 'Fever entry must use Mango rather than a lingering Triple tint.',
    );
    await capture(tester, 'motion_fever_entry_immediate.png');
    await tester.pump(const Duration(milliseconds: 220));
    expect(entries.targetClashReveal, isNull);
    expect(find.byKey(const Key('target-clash-expression')), findsOneWidget);
    expect(find.text('Choose the correct relation'), findsOneWidget);
    for (final key in const [
      Key('target-clash-relation-less'),
      Key('target-clash-relation-equal'),
      Key('target-clash-relation-greater'),
    ]) {
      expect(
        tester
            .widget<OutlinedButton>(find.descendant(
              of: find.byKey(key),
              matching: find.byType(OutlinedButton),
            ))
            .onPressed,
        isNotNull,
      );
    }
    await capture(tester, 'motion_fever_entry_settled.png');
    await entries.quitToMenu();
  });

  testWidgets('captures reduced-motion equivalent and disposes pending effects',
      (tester) async {
    final reduced = await animatedState(reduceMotion: true);
    await mountInjected(tester, reduced, reduceMotion: true);
    reduced.onTargetClashAnswer(reduced.targetClashQuestion!.correctAnswer);
    await tester.pump();
    await capture(tester, 'motion_reduced_reveal_static.png');
    reduced.debugCompleteTargetClashRevealForTest();
    await reduced.quitToMenu();

    final pending = await animatedState(difficulty: Difficulty.hard);
    await mountInjected(tester, pending);
    var reachedTriple = false;
    for (var attempt = 0; attempt < 4 && !reachedTriple; attempt++) {
      pending.debugStartTargetClashForTest(config(Difficulty.hard));
      for (var i = 0; i < 6 && pending.targetClashQuestion != null; i++) {
        resolve(pending);
      }
      reachedTriple = pending.targetClashRuntime?.isTriple ?? false;
    }
    expect(reachedTriple, isTrue);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('test injection is isolated from the following default app',
      (tester) async {
    await prepareApp(dark: false);
    viewport(tester, const Size(390, 844));
    installAudioMocks();
    final injected = await longNegativeBossFeverState();
    await tester.pumpWidget(host(testGameState: injected));
    await tester.pump();
    expect(
      Provider.of<GameState>(tester.element(find.byType(Scaffold)),
          listen: false),
      same(injected),
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.pumpWidget(host());
    await tester.pump();
    final fresh = Provider.of<GameState>(
      tester.element(find.byType(Scaffold)),
      listen: false,
    );
    expect(fresh, isNot(same(injected)));
    expect(fresh.targetClashRuntime, isNull);
  });

  testWidgets('release build rejects test GameState injection', (tester) async {
    if (!kReleaseMode) return;
    await prepareApp(dark: false);
    viewport(tester, const Size(390, 844));
    installAudioMocks();
    final injected = await longNegativeBossFeverState();
    try {
      await tester.pumpWidget(host(testGameState: injected));
      expect(tester.takeException(), isA<StateError>());
    } finally {
      injected.dispose();
    }
  });
}

final class _NoOpAudioService implements AudioService {
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

final class _LongNegativeQuestionGenerator extends QuestionGenerator {
  _LongNegativeQuestionGenerator({
    this.anchorResult = -135,
    this.mixedSignDirect = false,
  }) : super(rng: Random(1));

  final num anchorResult;
  final bool mixedSignDirect;

  @override
  Question build({
    required Operation type,
    required Difficulty diff,
    required NumberType numType,
    bool integerQuest = false,
    bool decimalQuest = false,
  }) =>
      _directQuestion(result: anchorResult, diff: diff, numType: numType);

  @override
  Question? buildDirectForResult({
    required Operation type,
    required Difficulty diff,
    required NumberType numType,
    required num result,
  }) {
    return result == -136
        ? _longNegativeQuestion(diff: diff, numType: numType)
        : _directQuestion(result: result, diff: diff, numType: numType);
  }

  Question _longNegativeQuestion({
    required Difficulty diff,
    required NumberType numType,
  }) {
    const result = -136;
    return Question(
      type: Operation.addition,
      key: 'long-negative',
      text: '-67 + -69',
      ans: result,
      choices: const [result],
      diff: diff,
      numType: numType,
      fact: const MathFact(
        operation: Operation.addition,
        left: -67,
        right: -69,
        result: result,
        representation: FactRepresentation.direct,
        difficulty: Difficulty.hard,
        numberType: NumberType.integers,
      ),
    );
  }

  Question _directQuestion({
    required num result,
    required Difficulty diff,
    required NumberType numType,
  }) {
    final left =
        mixedSignDirect ? (result >= 0 ? result + 1 : result - 1) : result;
    final right = mixedSignDirect ? (result >= 0 ? -1 : 1) : 0;
    return Question(
      type: Operation.addition,
      key: 'direct:$result',
      text: '$left + $right',
      ans: result,
      choices: [result],
      diff: diff,
      numType: numType,
      fact: MathFact(
        operation: Operation.addition,
        left: left,
        right: right,
        result: result,
        representation: FactRepresentation.direct,
        difficulty: diff,
        numberType: numType,
      ),
    );
  }
}

void _ignoreAudioEvents(Object? _, MockStreamHandlerEventSink __) {}

final class _SilentAudioplayersPlatform extends AudioplayersPlatformInterface {
  final _events = <String, StreamController<AudioEvent>>{};

  @override
  Future<void> create(String playerId) async {
    _events[playerId] = StreamController<AudioEvent>.broadcast();
  }

  @override
  Future<void> dispose(String playerId) async {
    await _events.remove(playerId)?.close();
  }

  @override
  Future<void> emitError(String playerId, String code, String message) async {}

  @override
  Future<void> emitLog(String playerId, String message) async {}

  @override
  Future<int?> getCurrentPosition(String playerId) async => 0;

  @override
  Future<int?> getDuration(String playerId) async => 0;

  @override
  Stream<AudioEvent> getEventStream(String playerId) =>
      _events[playerId]?.stream ?? const Stream<AudioEvent>.empty();

  @override
  Future<void> pause(String playerId) async {}

  @override
  Future<void> release(String playerId) async {}

  @override
  Future<void> resume(String playerId) async {}

  @override
  Future<void> seek(String playerId, Duration position) async {}

  @override
  Future<void> setAudioContext(
      String playerId, AudioContext audioContext) async {}

  @override
  Future<void> setBalance(String playerId, double balance) async {}

  @override
  Future<void> setPlaybackRate(String playerId, double playbackRate) async {}

  @override
  Future<void> setPlayerMode(String playerId, PlayerMode playerMode) async {}

  @override
  Future<void> setReleaseMode(String playerId, ReleaseMode releaseMode) async {}

  @override
  Future<void> setSourceBytes(String playerId, Uint8List bytes,
      {String? mimeType}) async {}

  @override
  Future<void> setSourceUrl(String playerId, String url,
      {bool? isLocal, String? mimeType}) async {}

  @override
  Future<void> setVolume(String playerId, double volume) async {}

  @override
  Future<void> stop(String playerId) async {}
}
