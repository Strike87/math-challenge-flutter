import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/study/p1_f01_study_evaluator.dart';
import 'package:math_challenge/features/game_brain/study/wilson_precision_evaluator.dart';

void main() {
  group('P1 Study evaluator', () {
    test('unavailable or duplicate measurement abstains before failures', () {
      final result = evaluateP1Study(_snapshot(
        available: false,
        windows: [
          _window(1, [_opportunity(1), _opportunity(1)])
        ],
      ));

      expect(result.status, P1StudyEvaluationStatus.inconclusive);
      expect(result.inconclusiveReason,
          P1StudyInconclusiveReason.measurementUnavailable);
    });

    test('raw records retain missing linkage and unclean windows outside valid',
        () {
      final result = evaluateP1Study(_snapshot(windows: [
        _window(1, [_opportunity(1, acceptedQeoLink: false)]),
        _window(2, [_opportunity(1)], clean: false),
        _window(3, _balanced(1, 1)),
      ]));

      expect(result.metrics.rawOpportunityCount, 5);
      expect(result.metrics.validOpportunityCount, 3);
      expect(result.metrics.missingOpportunityCount, 2);
      expect(result.inconclusiveReason,
          P1StudyInconclusiveReason.missingnessAboveThreshold);
    });

    test('legal membership and exact fourteen dimension support are enforced',
        () {
      final qualifying = _window(1, _balanced(1, 8));
      final qualifyingSecond = _window(2, _balanced(1, 8));
      final changedRoute =
          _window(3, _balanced(1, 8), route: 'replayCarriedConfiguration');
      final changedRouteSecond =
          _window(4, _balanced(1, 8), route: 'replayCarriedConfiguration');
      final illegal = _window(5, [
        _opportunity(1,
            legal: {P1StudyCandidate.easy}, executed: P1StudyCandidate.medium),
      ]);
      final result = evaluateP1Study(_snapshot(
        windows: [
          qualifying,
          qualifyingSecond,
          changedRoute,
          changedRouteSecond,
          illegal,
        ],
      ));

      expect(result.metrics.validOpportunityCount, 96);
      expect(result.metrics.missingOpportunityCount, 1);
      expect(result.metrics.qualifyingStratumCount, 2);
    });

    test(
        'unordered equal legal sets pool while different legal sets remain distinct',
        () {
      final first = {
        P1StudyCandidate.easy,
        P1StudyCandidate.medium,
        P1StudyCandidate.hard,
      };
      final reordered = <P1StudyCandidate>{}
        ..add(P1StudyCandidate.hard)
        ..add(P1StudyCandidate.easy)
        ..add(P1StudyCandidate.medium);
      final different = {P1StudyCandidate.easy, P1StudyCandidate.medium};
      final pooled = evaluateP1Study(_snapshot(windows: [
        _window(1, _balancedWithLegal(1, 5, first)),
        _window(2, _balancedWithLegal(1, 5, reordered)),
      ]));
      final split = evaluateP1Study(_snapshot(windows: [
        _window(1, _balancedWithLegal(1, 5, first)),
        _window(2, _balancedWithLegal(1, 5, reordered)),
        _window(3, [
          ..._many(1, P1StudyCandidate.easy, 5, legal: different),
          ..._many(6, P1StudyCandidate.medium, 5, legal: different),
        ]),
      ]));
      expect(pooled.metrics.qualifyingStratumCount, 1);
      expect(pooled.metrics.validOpportunityCount, 30);
      expect(split.metrics.qualifyingStratumCount, 1);
      expect(split.metrics.validOpportunityCount, 40);
      for (final candidate in P1StudyCandidate.values) {
        expect(
            pooled.metrics.candidateMetrics[candidate]!.comparableExposure, 10);
        expect(
            split.metrics.candidateMetrics[candidate]!.comparableExposure, 10);
      }
    });

    test(
        'three-to-one imbalance boundary qualifies and greater imbalance does not',
        () {
      final boundary = _window(1, [
        ..._many(1, P1StudyCandidate.easy, 10),
        ..._many(11, P1StudyCandidate.medium, 10),
        ..._many(21, P1StudyCandidate.hard, 5),
      ]);
      final remaining = _window(2, _many(1, P1StudyCandidate.hard, 25));
      final over = _window(3, _many(1, P1StudyCandidate.hard, 1));

      final exact = evaluateP1Study(_snapshot(windows: [boundary, remaining]));
      final overThree =
          evaluateP1Study(_snapshot(windows: [boundary, remaining, over]));
      expect(exact.metrics.candidateMetrics[P1StudyCandidate.easy]!
          .executedExposure, 10);
      expect(exact.metrics.candidateMetrics[P1StudyCandidate.medium]!
          .executedExposure, 10);
      expect(exact.metrics.candidateMetrics[P1StudyCandidate.hard]!
          .executedExposure, 30);
      expect(30 / 10, 3.0);
      expect(exact.metrics.qualifyingStratumCount, 1);
      expect(overThree.metrics.candidateMetrics[P1StudyCandidate.hard]!
          .executedExposure, 31);
      expect(31 / 10, 3.1);
      expect(overThree.metrics.qualifyingStratumCount, 0);
    });

    test('critical measurable predicates have locked precedence', () {
      final noLegalMedium = _snapshot(
          windows: List.generate(
        15,
        (i) => _window(
            i + 1,
            _many(1, P1StudyCandidate.easy, 20,
                legal: {P1StudyCandidate.easy})),
      ));
      expect(evaluateP1Study(noLegalMedium).notFeasibleReason,
          P1StudyNotFeasibleReason.legalOptionCoverageFailure);

      final starved = _snapshot(
          windows: List.generate(
        15,
        (i) => _window(i + 1, _many(1, P1StudyCandidate.easy, 20)),
      ));
      expect(evaluateP1Study(starved).notFeasibleReason,
          P1StudyNotFeasibleReason.exposureStarvation);

      final disjoint = _snapshot(
          windows: List.generate(15, (i) {
        final legal = switch (i % 3) {
          0 => {P1StudyCandidate.easy, P1StudyCandidate.medium},
          1 => {P1StudyCandidate.easy, P1StudyCandidate.hard},
          _ => {P1StudyCandidate.medium, P1StudyCandidate.hard},
        };
        final candidates = legal.toList();
        return _window(
            i + 1,
            List.generate(
                20,
                (n) => _opportunity(n + 1,
                    legal: legal, executed: candidates[n % 2])));
      }));
      expect(evaluateP1Study(disjoint).notFeasibleReason,
          P1StudyNotFeasibleReason.comparabilityFailure);
    });

    test(
        'canonical ordering, quintiles, diversity, Wilson, and all boundaries can pass',
        () {
      final windows = List.generate(15, (segment) {
        final operation = switch (segment ~/ 5) {
          0 => 'addition',
          1 => 'subtraction',
          _ => 'multiplication',
        };
        return _window(
            segment + 1,
            _balanced(1, 6, operation: operation)
              ..addAll(
                  _many(19, P1StudyCandidate.easy, 1, operation: operation))
              ..addAll(
                  _many(20, P1StudyCandidate.medium, 1, operation: operation)));
      });
      final result = evaluateP1Study(_snapshot(windows: windows));

      expect(result.status, P1StudyEvaluationStatus.feasible);
      expect(result.metrics.validOpportunityCount, 300);
      expect(result.metrics.qualifyingStratumCount, 3);
      expect(result.metrics.comparableRunDiversity, 15);
      for (final metrics in result.metrics.candidateMetrics.values) {
        expect(metrics.executedExposure, greaterThanOrEqualTo(60));
        expect(metrics.comparableExposure, greaterThanOrEqualTo(30));
        expect(metrics.legalCoverage, 1);
        expect(metrics.missingness, 0);
        expect(metrics.runConcentration, lessThanOrEqualTo(.25));
        expect(metrics.temporalConcentration, lessThanOrEqualTo(.50));
        expect(metrics.qualifyingStrataRepresented, 3);
        expect(metrics.wilson.meetsPrecision, isTrue);
      }
    });

    test('global missingness exact five percent passes and greater fails', () {
      final exact = evaluateP1Study(_withInvalid(
        _nearFeasibleSnapshot(validPerWindow: 19),
        P1StudyCandidate.easy,
        15,
      ));
      final over = evaluateP1Study(_withInvalid(
        _nearFeasibleSnapshot(validPerWindow: 19),
        P1StudyCandidate.easy,
        16,
      ));
      expect(exact.metrics.globalMissingness, .05);
      expect(exact.inconclusiveReason,
          P1StudyInconclusiveReason.commonSupportInsufficient);
      expect(over.metrics.globalMissingness, greaterThan(.05));
      expect(over.inconclusiveReason,
          P1StudyInconclusiveReason.missingnessAboveThreshold);
    });

    for (final candidate in P1StudyCandidate.values) {
      test('candidate $candidate Wilson 39/38 boundary is evaluator-owned', () {
        final pass = evaluateP1Study(_wilsonBoundarySnapshot(candidate, 39));
        final fail = evaluateP1Study(_wilsonBoundarySnapshot(candidate, 38));
        final passMetrics = pass.metrics.candidateMetrics[candidate]!;
        final failMetrics = fail.metrics.candidateMetrics[candidate]!;

        expect(pass.metrics.validOpportunityCount, 300);
        expect(passMetrics.executedExposure, greaterThanOrEqualTo(60));
        expect(passMetrics.comparableExposure, 39);
        expect(passMetrics.legalCoverage, greaterThanOrEqualTo(.40));
        expect(pass.metrics.globalMissingness, lessThanOrEqualTo(.05));
        expect(passMetrics.missingness, lessThanOrEqualTo(.10));
        expect(pass.metrics.qualifyingStratumCount, 3);
        expect(pass.metrics.starvation, lessThanOrEqualTo(.20));
        expect(pass.metrics.comparableRunDiversity, greaterThanOrEqualTo(10));
        expect(passMetrics.runConcentration, lessThanOrEqualTo(.25));
        expect(passMetrics.temporalConcentration, lessThanOrEqualTo(.50));
        expect(passMetrics.qualifyingStrataRepresented, 3);
        expect(passMetrics.wilson.status, WilsonEvaluationStatus.evaluable);
        expect(passMetrics.wilson.successes, 19);
        expect(passMetrics.wilson.trials, 39);
        expect(passMetrics.wilson.halfWidth, lessThanOrEqualTo(.15));
        expect(passMetrics.wilson.meetsPrecision, isTrue);
        for (final other in P1StudyCandidate.values.where((c) => c != candidate)) {
          expect(pass.metrics.candidateMetrics[other]!.wilson.meetsPrecision,
              isTrue);
        }
        expect(pass.status, P1StudyEvaluationStatus.feasible);

        expect(fail.metrics.validOpportunityCount, 300);
        expect(failMetrics.executedExposure, greaterThanOrEqualTo(60));
        expect(failMetrics.comparableExposure, 38);
        expect(failMetrics.legalCoverage, greaterThanOrEqualTo(.40));
        expect(fail.metrics.globalMissingness, lessThanOrEqualTo(.05));
        expect(failMetrics.missingness, lessThanOrEqualTo(.10));
        expect(fail.metrics.qualifyingStratumCount, 3);
        expect(fail.metrics.starvation, lessThanOrEqualTo(.20));
        expect(fail.metrics.comparableRunDiversity, greaterThanOrEqualTo(10));
        expect(failMetrics.runConcentration, lessThanOrEqualTo(.25));
        expect(failMetrics.temporalConcentration, lessThanOrEqualTo(.50));
        expect(failMetrics.qualifyingStrataRepresented, 3);
        expect(failMetrics.wilson.status, WilsonEvaluationStatus.evaluable);
        expect(failMetrics.wilson.successes, 19);
        expect(failMetrics.wilson.trials, 38);
        expect(failMetrics.wilson.halfWidth, greaterThan(.15));
        expect(failMetrics.wilson.meetsPrecision, isFalse);
        for (final other in P1StudyCandidate.values.where((c) => c != candidate)) {
          expect(fail.metrics.candidateMetrics[other]!.wilson.meetsPrecision,
              isTrue);
        }
        expect(fail.status, P1StudyEvaluationStatus.inconclusive);
        expect(fail.inconclusiveReason,
            P1StudyInconclusiveReason.precisionInsufficient);
      });
    }

    for (final candidate in P1StudyCandidate.values) {
      test(
          'candidate $candidate missingness exact ten percent passes and greater fails',
          () {
        final exact = evaluateP1Study(_withInvalid(
          _candidateMissingnessSnapshot(candidate),
          candidate,
          10,
        ));
        final over = evaluateP1Study(_withInvalid(
          _candidateMissingnessSnapshot(candidate),
          candidate,
          11,
        ));
        expect(exact.metrics.candidateMetrics[candidate]!.missingness, .10);
        expect(exact.inconclusiveReason,
            isNot(P1StudyInconclusiveReason.missingnessAboveThreshold));
        expect(over.metrics.candidateMetrics[candidate]!.missingness,
            greaterThan(.10));
        expect(over.status, P1StudyEvaluationStatus.inconclusive);
      });

      test(
          'candidate $candidate temporal concentration exact half passes and greater fails',
          () {
        final exact = evaluateP1Study(_temporalSnapshot(candidate, 10));
        final over = evaluateP1Study(_temporalSnapshot(candidate, 9));
        expect(exact.metrics.candidateMetrics[candidate]!.temporalConcentration,
            .50);
        expect(exact.status, P1StudyEvaluationStatus.inconclusive);
        expect(over.metrics.candidateMetrics[candidate]!.temporalConcentration,
            greaterThan(.50));
        expect(over.status, P1StudyEvaluationStatus.inconclusive);
      });

      test(
          'candidate $candidate run concentration exact quarter passes and greater fails',
          () {
        final exact = evaluateP1Study(_runConcentrationSnapshot(candidate, 15));
        final over = evaluateP1Study(_runConcentrationSnapshot(candidate, 14));
        expect(
            exact.metrics.candidateMetrics[candidate]!.runConcentration, .25);
        expect(exact.status, P1StudyEvaluationStatus.feasible);
        expect(over.metrics.candidateMetrics[candidate]!.runConcentration,
            greaterThan(.25));
        expect(over.inconclusiveReason,
            P1StudyInconclusiveReason.runOrTemporalDiversityInsufficient);
      });
    }

    test('starvation exact twenty percent passes and greater fails', () {
      final exact = evaluateP1Study(_starvationSnapshot(badStrata: 1));
      final over = evaluateP1Study(_starvationSnapshot(badStrata: 2));
      expect(exact.metrics.starvation, .20);
      expect(exact.metrics.qualifyingStratumCount, greaterThanOrEqualTo(3));
      expect(exact.status, P1StudyEvaluationStatus.feasible);
      expect(over.metrics.starvation, 2 / 6);
      expect(over.inconclusiveReason,
          P1StudyInconclusiveReason.commonSupportInsufficient);
    });

    test('run diversity exact ten passes and below fails', () {
      final exact = evaluateP1Study(_runDiversitySnapshot(10));
      final below = evaluateP1Study(_runDiversitySnapshot(9));
      expect(exact.metrics.comparableRunDiversity, 10);
      expect(exact.status, P1StudyEvaluationStatus.feasible);
      expect(below.metrics.comparableRunDiversity, 9);
      expect(below.inconclusiveReason,
          P1StudyInconclusiveReason.runOrTemporalDiversityInsufficient);
    });

    test('all seven frozen not-feasible roots are individually terminal', () {
      final roots = <P1StudyNotFeasibleReason, P1StudyScientificSnapshot>{
        P1StudyNotFeasibleReason.legalOptionCoverageFailure:
            _legalCoverageFailure(),
        P1StudyNotFeasibleReason.exposureStarvation: _exposureStarvation(),
        P1StudyNotFeasibleReason.comparabilityFailure: _disjointContexts(),
        P1StudyNotFeasibleReason.insufficientRepeatedEvidence:
            _insufficientRepeatedEvidence(),
        P1StudyNotFeasibleReason.modeContextConfounding:
            _modeConfounding(critical: true),
        P1StudyNotFeasibleReason.playerSelectionConfounding:
            _playerConfounding(critical: true),
        P1StudyNotFeasibleReason.adaptiveCanonicalSelectionConfounding:
            _adaptiveConfounding(critical: true),
      };
      for (final entry in roots.entries) {
        final result = evaluateP1Study(entry.value);
        expect(result.status, P1StudyEvaluationStatus.notFeasible,
            reason: '${entry.key} status');
        expect(result.notFeasibleReason, entry.key);
      }
    });

    test('known routes split exact support and route heterogeneity survives',
        () {
      final result = evaluateP1Study(_routeStratifiedSnapshot());
      expect(result.metrics.qualifyingStratumCount, 6);
      expect(result.status, P1StudyEvaluationStatus.feasible);
    });

    test('F2 confounding matrices retain full measurement or abstain exactly',
        () {
      final knownRoutes = evaluateP1Study(_routeStratifiedSnapshot());
      expect(knownRoutes.metrics.qualifyingStratumCount, 6);
      expect(knownRoutes.status, P1StudyEvaluationStatus.feasible);

      final playerResolvable = evaluateP1Study(
        _f2Confounded(_F2Kind.player, affected: 15),
      );
      expect(playerResolvable.status, P1StudyEvaluationStatus.feasible);
      expect(playerResolvable.metrics.rawOpportunityCount, 315);
      expect(playerResolvable.metrics.validOpportunityCount, 300);
      expect(playerResolvable.metrics.missingOpportunityCount, 15);
      expect(playerResolvable.metrics.globalMissingness, 15 / 315);
      _expectConfounding(
          playerResolvable.metrics.playerSelectionConfounding, 15, 315);
      final playerAtBoundary = evaluateP1Study(
        _f2Confounded(_F2Kind.player, affected: 75, destroyMeasurement: true),
      );
      expect(playerAtBoundary.status, P1StudyEvaluationStatus.inconclusive);
      expect(playerAtBoundary.inconclusiveReason,
          P1StudyInconclusiveReason.missingnessAboveThreshold);
      _expectConfounding(
          playerAtBoundary.metrics.playerSelectionConfounding, 75, 375);
      final playerSurvives = evaluateP1Study(
        _f2Confounded(_F2Kind.player, affected: 76),
      );
      expect(playerSurvives.status, P1StudyEvaluationStatus.inconclusive);
      expect(playerSurvives.inconclusiveReason,
          P1StudyInconclusiveReason.missingnessAboveThreshold);
      expect(playerSurvives.metrics.rawOpportunityCount, 376);
      expect(playerSurvives.metrics.validOpportunityCount, 300);
      expect(playerSurvives.metrics.missingOpportunityCount, 76);
      expect(playerSurvives.metrics.globalMissingness, 76 / 376);
      _expectConfounding(
          playerSurvives.metrics.playerSelectionConfounding, 76, 376);
      final playerCritical = evaluateP1Study(
        _f2Confounded(_F2Kind.player, affected: 76, destroyMeasurement: true),
      );
      _expectF2Critical(
        playerCritical,
        P1StudyNotFeasibleReason.playerSelectionConfounding,
      );

      final adaptiveAtBoundary = evaluateP1Study(
        _f2Confounded(_F2Kind.adaptive, affected: 75, destroyMeasurement: true),
      );
      expect(adaptiveAtBoundary.status, P1StudyEvaluationStatus.inconclusive);
      expect(adaptiveAtBoundary.inconclusiveReason,
          P1StudyInconclusiveReason.missingnessAboveThreshold);
      _expectConfounding(
          adaptiveAtBoundary.metrics.adaptiveCanonicalSelectionConfounding,
          75,
          375);
      final adaptiveResolvable = evaluateP1Study(
        _f2Confounded(_F2Kind.adaptive, affected: 15),
      );
      expect(adaptiveResolvable.status, P1StudyEvaluationStatus.feasible);
      expect(adaptiveResolvable.metrics.rawOpportunityCount, 315);
      expect(adaptiveResolvable.metrics.validOpportunityCount, 300);
      expect(adaptiveResolvable.metrics.missingOpportunityCount, 15);
      expect(adaptiveResolvable.metrics.globalMissingness, 15 / 315);
      _expectConfounding(
          adaptiveResolvable.metrics.adaptiveCanonicalSelectionConfounding,
          15,
          315);
      final adaptiveSurvives = evaluateP1Study(
        _f2Confounded(_F2Kind.adaptive, affected: 76),
      );
      expect(adaptiveSurvives.status, P1StudyEvaluationStatus.inconclusive);
      expect(adaptiveSurvives.inconclusiveReason,
          P1StudyInconclusiveReason.missingnessAboveThreshold);
      expect(adaptiveSurvives.metrics.rawOpportunityCount, 376);
      expect(adaptiveSurvives.metrics.validOpportunityCount, 300);
      expect(adaptiveSurvives.metrics.missingOpportunityCount, 76);
      expect(adaptiveSurvives.metrics.globalMissingness, 76 / 376);
      _expectConfounding(
          adaptiveSurvives.metrics.adaptiveCanonicalSelectionConfounding,
          76,
          376);
      final adaptiveCritical = evaluateP1Study(
        _f2Confounded(_F2Kind.adaptive, affected: 76, destroyMeasurement: true),
      );
      _expectF2Critical(
        adaptiveCritical,
        P1StudyNotFeasibleReason.adaptiveCanonicalSelectionConfounding,
      );

      final modeAtBoundary = evaluateP1Study(
        _f2Confounded(_F2Kind.mode, affected: 75, destroyMeasurement: true),
      );
      expect(modeAtBoundary.status, P1StudyEvaluationStatus.inconclusive);
      expect(modeAtBoundary.inconclusiveReason,
          P1StudyInconclusiveReason.commonSupportInsufficient);
      _expectConfounding(
          modeAtBoundary.metrics.modeContextConfounding, 75, 375);
      final modeSurvives = evaluateP1Study(
        _f2Confounded(_F2Kind.mode, affected: 76),
      );
      expect(modeSurvives.status, P1StudyEvaluationStatus.feasible);
      expect(modeSurvives.metrics.unsupportedOpportunityCount, 76);
      expect(modeSurvives.metrics.rawOpportunityCount, 300);
      expect(modeSurvives.metrics.validOpportunityCount, 300);
      expect(modeSurvives.metrics.missingOpportunityCount, 0);
      expect(modeSurvives.metrics.globalMissingness, 0);
      _expectConfounding(modeSurvives.metrics.modeContextConfounding, 76, 376);
      final modeCritical = evaluateP1Study(
        _f2Confounded(_F2Kind.mode, affected: 76, destroyMeasurement: true),
      );
      _expectF2Critical(
        modeCritical,
        P1StudyNotFeasibleReason.modeContextConfounding,
      );
    });

    test('F2 malformed records do not inflate confounder denominators', () {
      final player = evaluateP1Study(_withMalformedConfounder(
        _f2Confounded(_F2Kind.player, affected: 60),
        _F2Kind.player,
      ));
      _expectConfounding(player.metrics.playerSelectionConfounding, 60, 360);
      final adaptive = evaluateP1Study(_withMalformedConfounder(
        _f2Confounded(_F2Kind.adaptive, affected: 60),
        _F2Kind.adaptive,
      ));
      _expectConfounding(
          adaptive.metrics.adaptiveCanonicalSelectionConfounding, 60, 360);
      final mode = evaluateP1Study(_withMalformedConfounder(
        _f2Confounded(_F2Kind.mode, affected: 60),
        _F2Kind.mode,
      ));
      _expectConfounding(mode.metrics.modeContextConfounding, 60, 360);
    });

    test('F2 duplicate and incomplete mode records stay out of denominators',
        () {
      final player = evaluateP1Study(_withDuplicateConfounder(
        _f2Confounded(_F2Kind.player, affected: 60),
        _F2Kind.player,
      ));
      _expectConfounding(player.metrics.playerSelectionConfounding, 60, 360);

      final adaptive = evaluateP1Study(_withDuplicateConfounder(
        _f2Confounded(_F2Kind.adaptive, affected: 60),
        _F2Kind.adaptive,
      ));
      _expectConfounding(
          adaptive.metrics.adaptiveCanonicalSelectionConfounding, 60, 360);

      final mode = evaluateP1Study(_withDuplicateConfounder(
        _f2Confounded(_F2Kind.mode, affected: 60),
        _F2Kind.mode,
      ));
      _expectConfounding(mode.metrics.modeContextConfounding, 60, 360);

      final nullMode = evaluateP1Study(_withNullModeClassification(
        _f2Confounded(_F2Kind.mode, affected: 60),
      ));
      _expectConfounding(nullMode.metrics.modeContextConfounding, 60, 360);
    });

    test('F2 preserves an independently governing retained ordinary failure',
        () {
      final result = evaluateP1Study(_withIndependentMalformed(
        _f2Confounded(_F2Kind.player, affected: 75, destroyMeasurement: true),
        16,
      ));
      _expectConfounding(result.metrics.playerSelectionConfounding, 75, 375);
      expect(result.status, P1StudyEvaluationStatus.inconclusive);
      expect(result.inconclusiveReason,
          P1StudyInconclusiveReason.missingnessAboveThreshold);
    });

    test('F2 preserves independent locked roots despite noncritical confounding',
        () {
      final legal = evaluateP1Study(_withF2Affected(
        _legalCoverageFailure(),
        _F2Kind.player,
        60,
      ));
      expect(legal.status, P1StudyEvaluationStatus.notFeasible);
      expect(legal.notFeasibleReason,
          P1StudyNotFeasibleReason.legalOptionCoverageFailure);

      final diversity = evaluateP1Study(_withF2Affected(
        _runDiversitySnapshot(9),
        _F2Kind.mode,
        75,
      ));
      expect(diversity.status, P1StudyEvaluationStatus.inconclusive);
      expect(diversity.inconclusiveReason,
          P1StudyInconclusiveReason.runOrTemporalDiversityInsufficient);
    });

    test('negative controls never gain feasibility through artificial pooling',
        () {
      final snapshots = [
        _disjointContexts(),
        _starvationSnapshot(badStrata: 2),
        _legalCoverageBelowThreshold(),
        _runDiversitySnapshot(9),
        _routeIncompatibleSnapshot(),
      ];
      for (final snapshot in snapshots) {
        expect(evaluateP1Study(snapshot).status,
            isNot(P1StudyEvaluationStatus.feasible));
      }
    });

    test(
        'terminal precedence is measurement, critical, ordinary, then feasible',
        () {
      final unavailable = evaluateP1Study(_snapshot(
          available: false, windows: _legalCoverageFailure().windows));
      expect(unavailable.inconclusiveReason,
          P1StudyInconclusiveReason.measurementUnavailable);
      final criticalWithThreshold = evaluateP1Study(_modeConfounding(
        critical: true,
        makeMissing: true,
      ));
      expect(criticalWithThreshold.notFeasibleReason,
          P1StudyNotFeasibleReason.modeContextConfounding);
      final ordinary = evaluateP1Study(_withInvalid(
        _candidateMissingnessSnapshot(P1StudyCandidate.easy),
        P1StudyCandidate.easy,
        11,
      ));
      expect(ordinary.status, P1StudyEvaluationStatus.inconclusive);
      expect(ordinary.notFeasibleReason, isNull);
      expect(evaluateP1Study(_feasibleSnapshot()).status,
          P1StudyEvaluationStatus.feasible);
    });

    test('malformed inputs fail closed without becoming valid evidence', () {
      final cases = [
        _snapshot(windows: [
          _window(1, [_opportunity(1), _opportunity(1)])
        ]),
        _snapshot(windows: [
          _window(1, [_opportunity(1, legal: const {})])
        ]),
        _snapshot(windows: [
          _window(1, [_opportunity(1, acceptedQeoLink: false)])
        ]),
        _snapshot(windows: [
          _window(1, [_opportunity(26)])
        ]),
        _snapshot(windows: [
          _window(1, [_opportunity(1)], clean: false)
        ]),
      ];
      for (final snapshot in cases.skip(1)) {
        final result = evaluateP1Study(snapshot);
        expect(
            result.metrics.validOpportunityCount,
            lessThan(snapshot.windows.fold<int>(
                0, (count, window) => count + window.opportunities.length)));
        expect(result.status, isNot(P1StudyEvaluationStatus.feasible));
      }
      expect(evaluateP1Study(cases.first).inconclusiveReason,
          P1StudyInconclusiveReason.thresholdUnevaluable);
    });

    test('durable sampling readiness prevents pre-horizon terminals', () {
      final base = _feasibleSnapshot();
      P1StudyEvaluationAttempt attempt(
              String status, String reason, int count) =>
          attemptP1Study(P1StudyScientificSnapshot(
            epochSequence: base.epochSequence,
            measurementAvailable: base.measurementAvailable,
            windows: base.windows,
            epochStatus: status,
            epochStopReason: reason,
            admittedStudyWindowCount: count,
            capacityWindows: 49,
          ));
      final active48 = attempt('ACTIVE', 'none', 48);
      expect(
          active48.readiness, P1StudyAdjudicationReadiness.samplingIncomplete);
      expect(active48.evaluation, isNull);
      final active49 = attempt('ACTIVE', 'none', 49);
      expect(active49.readiness,
          P1StudyAdjudicationReadiness.governanceIncoherent);
      expect(active49.evaluation, isNull);
      final frozen = attempt('FROZEN_FOR_ADJUDICATION', 'capacityReached', 49);
      expect(frozen.readiness, P1StudyAdjudicationReadiness.ready);
      expect(frozen.evaluation?.status, P1StudyEvaluationStatus.feasible);
      expect(
          attempt('FROZEN_FOR_ADJUDICATION', 'capacityReached', 48).evaluation,
          isNull);
      expect(attempt('ABORTED', 'capacityReached', 49).readiness,
          P1StudyAdjudicationReadiness.aborted);
      expect(attempt('ADJUDICATED', 'capacityReached', 49).readiness,
          P1StudyAdjudicationReadiness.ready);
    });

    test('single governed record defects remain raw missing evidence', () {
      final base = _feasibleSnapshot();
      P1StudyScientificSnapshot withFirst(P1StudyScientificOpportunity record) {
        final first = base.windows.first;
        final windows = [...base.windows];
        windows[0] =
            _window(first.runSegmentId!, [record, ...first.opportunities]);
        return _snapshot(windows: windows);
      }

      final duplicate = withFirst(base.windows.first.opportunities.first);
      final duplicateResult = evaluateP1Study(duplicate);
      expect(duplicateResult.metrics.rawOpportunityCount, 301);
      expect(duplicateResult.metrics.validOpportunityCount, 299);
      expect(duplicateResult.metrics.missingOpportunityCount, 2);
      expect(duplicateResult.inconclusiveReason,
          isNot(P1StudyInconclusiveReason.measurementUnavailable));
      final source = base.windows.first.opportunities.first;
      final malformed = withFirst(P1StudyScientificOpportunity(
        opportunityOrdinalWithinRun: 25,
        decisionContext: source.decisionContext,
        decisionLocus: source.decisionLocus,
        decisionLocusReason: source.decisionLocusReason,
        legalCandidates: null,
        executedCandidate: source.executedCandidate,
        canonicalSelectionMechanism: source.canonicalSelectionMechanism,
        operation: source.operation,
        numberType: source.numberType,
        terminal: source.terminal,
        acceptedQeoLink: source.acceptedQeoLink,
      ));
      expect(evaluateP1Study(malformed).inconclusiveReason,
          isNot(P1StudyInconclusiveReason.measurementUnavailable));
      final unlinked = withFirst(P1StudyScientificOpportunity(
        opportunityOrdinalWithinRun: 25,
        decisionContext: source.decisionContext,
        decisionLocus: source.decisionLocus,
        decisionLocusReason: source.decisionLocusReason,
        legalCandidates: source.legalCandidates,
        executedCandidate: source.executedCandidate,
        canonicalSelectionMechanism: source.canonicalSelectionMechanism,
        operation: source.operation,
        numberType: source.numberType,
        terminal: source.terminal,
        acceptedQeoLink: false,
      ));
      final unlinkedResult = evaluateP1Study(unlinked);
      expect(unlinkedResult.metrics.rawOpportunityCount, 301);
      expect(unlinkedResult.metrics.validOpportunityCount, 300);
      expect(unlinkedResult.metrics.missingOpportunityCount, 1);
      expect(
          evaluateP1Study(_snapshot(available: false, windows: base.windows))
              .inconclusiveReason,
          P1StudyInconclusiveReason.measurementUnavailable);
    });
  });
}

P1StudyEvaluationResult evaluateP1Study(P1StudyScientificSnapshot snapshot) {
  final attempt = attemptP1Study(P1StudyScientificSnapshot(
    epochSequence: snapshot.epochSequence,
    measurementAvailable: snapshot.measurementAvailable,
    windows: snapshot.windows,
    epochStatus: 'FROZEN_FOR_ADJUDICATION',
    epochStopReason: 'capacityReached',
    admittedStudyWindowCount: 49,
    capacityWindows: 49,
  ));
  expect(attempt.readiness, P1StudyAdjudicationReadiness.ready);
  return attempt.evaluation!;
}

P1StudyScientificSnapshot _snapshot({
  bool available = true,
  required List<P1StudyScientificWindow> windows,
}) =>
    P1StudyScientificSnapshot(
      epochSequence: 1,
      measurementAvailable: available,
      windows: windows,
    );

P1StudyScientificWindow _window(
  int segment,
  List<P1StudyScientificOpportunity> opportunities, {
  bool clean = true,
  String route = 'freshSetupAcceptedConfiguration',
  String activity = 'quickPracticeTimingPractice',
  String? gameMode = 'standard',
}) =>
    P1StudyScientificWindow(
      runSegmentId: segment,
      activityRunContext: activity,
      agencyRoute: route,
      runType: 'normal',
      playerCount: 1,
      gameMode: gameMode,
      questionMechanic: 'standard',
      answerStyle: 'choice4',
      cleanEligible: clean,
      opportunities: opportunities,
    );

List<P1StudyScientificOpportunity> _balanced(
  int first,
  int each, {
  String operation = 'addition',
}) =>
    [
      ..._many(first, P1StudyCandidate.easy, each, operation: operation),
      ..._many(first + each, P1StudyCandidate.medium, each,
          operation: operation),
      ..._many(first + each * 2, P1StudyCandidate.hard, each,
          operation: operation),
    ];

List<P1StudyScientificOpportunity> _balancedWithLegal(
  int first,
  int each,
  Set<P1StudyCandidate> legal,
) =>
    [
      ..._many(first, P1StudyCandidate.easy, each, legal: legal),
      ..._many(first + each, P1StudyCandidate.medium, each, legal: legal),
      ..._many(first + each * 2, P1StudyCandidate.hard, each, legal: legal),
    ];

List<P1StudyScientificOpportunity> _many(
  int first,
  P1StudyCandidate candidate,
  int count, {
  Set<P1StudyCandidate> legal = const {
    P1StudyCandidate.easy,
    P1StudyCandidate.medium,
    P1StudyCandidate.hard,
  },
  String operation = 'addition',
}) =>
    List.generate(
        count,
        (index) => _opportunity(first + index,
            legal: legal, executed: candidate, operation: operation));

P1StudyScientificOpportunity _opportunity(
  int ordinal, {
  Set<P1StudyCandidate> legal = const {
    P1StudyCandidate.easy,
    P1StudyCandidate.medium,
    P1StudyCandidate.hard,
  },
  P1StudyCandidate executed = P1StudyCandidate.easy,
  bool acceptedQeoLink = true,
  String operation = 'addition',
  String canonical = 'playerConfigured',
  P1StudyTerminal terminal = P1StudyTerminal.answeredCorrect,
}) =>
    P1StudyScientificOpportunity(
      opportunityOrdinalWithinRun: ordinal,
      decisionContext: 'chooseDifficulty',
      decisionLocus: 'questionOpeningDifficultyResolution',
      decisionLocusReason: 'difficultyRequiredForQuestionOpening',
      legalCandidates: legal,
      executedCandidate: executed,
      canonicalSelectionMechanism: canonical,
      operation: operation,
      numberType: 'natural',
      terminal: terminal,
      acceptedQeoLink: acceptedQeoLink,
    );

P1StudyScientificSnapshot _feasibleSnapshot() => _snapshot(
      windows: List.generate(15, (segment) {
        final operation = switch (segment ~/ 5) {
          0 => 'addition',
          1 => 'subtraction',
          _ => 'multiplication',
        };
        return _window(
          segment + 1,
          _balanced(1, 6, operation: operation)
            ..addAll(_many(19, P1StudyCandidate.easy, 1, operation: operation))
            ..addAll(
                _many(20, P1StudyCandidate.medium, 1, operation: operation)),
        );
      }),
    );

P1StudyScientificSnapshot _wilsonBoundarySnapshot(
  P1StudyCandidate target,
  int targetTrials,
) {
  final others = P1StudyCandidate.values.where((c) => c != target).toList();
  final records = <P1StudyScientificOpportunity>[];
  var targetSuccesses = 19;
  for (var group = 0; group < 3; group++) {
    final targetCount = targetTrials ~/ 3 +
        (group < targetTrials % 3 ? 1 : 0);
    final candidates = [target, others[0], others[1]];
    final remaining = [targetCount, 20, 20];
    while (remaining.any((count) => count > 0)) {
      for (var index = 0; index < candidates.length; index++) {
        if (remaining[index]-- > 0) {
          final isTarget = candidates[index] == target;
          records.add(_opportunity(
            records.length + 1,
            executed: candidates[index],
            operation: ['addition', 'subtraction', 'multiplication'][group],
            terminal: isTarget && targetSuccesses-- <= 0
                ? P1StudyTerminal.answeredIncorrect
                : P1StudyTerminal.answeredCorrect,
          ));
        }
      }
    }
  }
  while (records.length < 300) {
    final other = others[records.length.isEven ? 0 : 1];
    records.add(_opportunity(
      records.length + 1,
      legal: {target, other},
      executed: target,
      operation: 'division',
    ));
  }
  return _snapshot(
    windows: List.generate((records.length + 9) ~/ 10, (windowIndex) {
      final slice = records.skip(windowIndex * 10).take(10).toList();
      return _window(windowIndex + 1, [
        for (var index = 0; index < slice.length; index++)
          P1StudyScientificOpportunity(
            opportunityOrdinalWithinRun: index + 1,
            decisionContext: slice[index].decisionContext,
            decisionLocus: slice[index].decisionLocus,
            decisionLocusReason: slice[index].decisionLocusReason,
            legalCandidates: slice[index].legalCandidates,
            executedCandidate: slice[index].executedCandidate,
            canonicalSelectionMechanism:
                slice[index].canonicalSelectionMechanism,
            operation: slice[index].operation,
            numberType: slice[index].numberType,
            terminal: slice[index].terminal,
            acceptedQeoLink: slice[index].acceptedQeoLink,
          ),
      ]);
    }),
  );
}

P1StudyScientificSnapshot _nearFeasibleSnapshot({int validPerWindow = 20}) =>
    _snapshot(
      windows: List.generate(15, (segment) {
        final operation = switch (segment ~/ 5) {
          0 => 'addition',
          1 => 'subtraction',
          _ => 'multiplication',
        };
        final counts = validPerWindow == 19 ? [6, 6, 7] : [7, 7, 6];
        return _window(segment + 1, [
          ..._many(1, P1StudyCandidate.easy, counts[0], operation: operation),
          ..._many(1 + counts[0], P1StudyCandidate.medium, counts[1],
              operation: operation),
          ..._many(1 + counts[0] + counts[1], P1StudyCandidate.hard, counts[2],
              operation: operation),
        ]);
      }),
    );

P1StudyScientificSnapshot _candidateMissingnessSnapshot(
  P1StudyCandidate target,
) =>
    _snapshot(
      windows: List.generate(5,
          (index) => _window(index + 1, _many(1, target, 18, legal: {target}))),
    );

P1StudyScientificSnapshot _withInvalid(
  P1StudyScientificSnapshot source,
  P1StudyCandidate candidate,
  int count,
) {
  var remaining = count;
  return _snapshot(
    windows: source.windows.map((window) {
      final opportunities = [...window.opportunities];
      while (remaining > 0 && opportunities.length < 25) {
        opportunities.add(_opportunity(
          opportunities.length + 1,
          legal: {candidate},
          executed: candidate,
          acceptedQeoLink: false,
        ));
        remaining--;
      }
      return _window(window.runSegmentId!, opportunities,
          route: window.agencyRoute!,
          activity: window.activityRunContext!,
          gameMode: window.gameMode!);
    }).toList(),
  );
}

P1StudyScientificSnapshot _starvationSnapshot({required int badStrata}) {
  final operations = [
    'addition',
    'subtraction',
    'multiplication',
    'division',
    'mixed',
    'master',
  ];
  final total = badStrata == 1 ? 5 : 6;
  return _snapshot(
    windows: List.generate(total * 3, (index) {
      final group = index ~/ 3;
      final operation = operations[group];
      final bad = group < badStrata;
      final counts = bad ? [3, 8, 9] : [7, 7, 6];
      return _window(index + 1, [
        ..._many(1, P1StudyCandidate.easy, counts[0], operation: operation),
        ..._many(1 + counts[0], P1StudyCandidate.medium, counts[1],
            operation: operation),
        ..._many(1 + counts[0] + counts[1], P1StudyCandidate.hard, counts[2],
            operation: operation),
      ]);
    }),
  );
}

P1StudyScientificSnapshot _temporalSnapshot(
  P1StudyCandidate target,
  int finalGroupTarget,
) {
  final other = P1StudyCandidate.values.where((c) => c != target).toList();
  final windows = <P1StudyScientificWindow>[];
  for (var index = 0; index < 9; index++) {
    final group = index ~/ 3;
    final operation = ['addition', 'subtraction', 'multiplication'][group];
    final counts = group == 0
        ? [20, 20, 20]
        : group == 2
            ? [finalGroupTarget, 25, 25]
            : [10, 25, 25];
    final targetCount = group == 0
        ? (index % 3 == 0 ? 20 : 0)
        : counts[0] ~/ 3 + (index % 3 < counts[0] % 3 ? 1 : 0);
    final otherOneCount = group == 0
        ? (index % 3 == 1 ? 20 : 0)
        : counts[1] ~/ 3 + (index % 3 < counts[1] % 3 ? 1 : 0);
    final otherTwoCount = 20 - targetCount - otherOneCount;
    windows.add(_window(index + 1, [
      ..._many(1, target, targetCount, operation: operation),
      ..._many(1 + targetCount, other[0], otherOneCount, operation: operation),
      ..._many(1 + targetCount + otherOneCount, other[1], otherTwoCount,
          operation: operation),
    ]));
  }
  for (var index = 9; index < 15; index++) {
    windows.add(_window(
        index + 1,
        _many(1, P1StudyCandidate.easy, 20,
            legal: {P1StudyCandidate.easy, P1StudyCandidate.medium})));
  }
  return _snapshot(windows: windows);
}

P1StudyScientificSnapshot _runConcentrationSnapshot(
  P1StudyCandidate target,
  int finalGroupTarget,
) {
  final other = P1StudyCandidate.values.where((c) => c != target).toList();
  return _snapshot(
    windows: List.generate(15, (index) {
      final group = index ~/ 3;
      final operation = [
        'addition',
        'subtraction',
        'multiplication',
        'division',
        'mixed'
      ][group];
      final targetTotal = group == 0
          ? 20
          : group == 4
              ? finalGroupTarget
              : 15;
      final targetCount = group == 0
          ? (index == 0 ? 20 : 0)
          : targetTotal ~/ 3 + (index % 3 < targetTotal % 3 ? 1 : 0);
      final otherOneTotal = (60 - targetTotal) ~/ 2;
      final otherOneCount = group == 0
          ? (index == 1 ? 20 : 0)
          : otherOneTotal ~/ 3 + (index % 3 < otherOneTotal % 3 ? 1 : 0);
      final remaining = 20 - targetCount;
      return _window(index + 1, [
        ..._many(1, target, targetCount, operation: operation),
        ..._many(1 + targetCount, other[0], otherOneCount,
            operation: operation),
        ..._many(1 + targetCount + otherOneCount, other[1],
            remaining - otherOneCount,
            operation: operation),
      ]);
    }),
  );
}

P1StudyScientificSnapshot _runDiversitySnapshot(int qualifyingWindows) =>
    _snapshot(
      windows: List.generate(15, (index) {
        if (index >= qualifyingWindows) {
          return _window(
              index + 1,
              _many(1, P1StudyCandidate.easy, 20,
                  legal: {P1StudyCandidate.easy, P1StudyCandidate.medium}));
        }
        final pattern = switch (index % 3) {
          0 => [7, 7, 6],
          1 => [6, 7, 7],
          _ => [7, 6, 7],
        };
        final operation =
            ['addition', 'subtraction', 'multiplication'][index % 3];
        return _window(
            index + 1,
            [
              ..._many(1, P1StudyCandidate.easy, pattern[0]),
              ..._many(1 + pattern[0], P1StudyCandidate.medium, pattern[1]),
              ..._many(1 + pattern[0] + pattern[1], P1StudyCandidate.hard,
                  pattern[2]),
            ]
                .map((opportunity) => P1StudyScientificOpportunity(
                      opportunityOrdinalWithinRun:
                          opportunity.opportunityOrdinalWithinRun,
                      decisionContext: opportunity.decisionContext,
                      decisionLocus: opportunity.decisionLocus,
                      decisionLocusReason: opportunity.decisionLocusReason,
                      legalCandidates: opportunity.legalCandidates,
                      executedCandidate: opportunity.executedCandidate,
                      canonicalSelectionMechanism:
                          opportunity.canonicalSelectionMechanism,
                      operation: operation,
                      numberType: opportunity.numberType,
                      terminal: opportunity.terminal,
                      acceptedQeoLink: opportunity.acceptedQeoLink,
                    ))
                .toList());
      }),
    );

P1StudyScientificSnapshot _legalCoverageFailure() => _snapshot(
      windows: List.generate(
          15,
          (index) => _window(
              index + 1,
              _many(1, P1StudyCandidate.easy, 20,
                  legal: {P1StudyCandidate.easy}))),
    );

P1StudyScientificSnapshot _exposureStarvation() => _snapshot(
      windows: List.generate(15,
          (index) => _window(index + 1, _many(1, P1StudyCandidate.easy, 20))),
    );

P1StudyScientificSnapshot _disjointContexts() => _snapshot(
      windows: List.generate(15, (index) {
        final legal = switch (index % 3) {
          0 => {P1StudyCandidate.easy, P1StudyCandidate.medium},
          1 => {P1StudyCandidate.easy, P1StudyCandidate.hard},
          _ => {P1StudyCandidate.medium, P1StudyCandidate.hard},
        };
        final candidates = legal.toList();
        return _window(
            index + 1,
            List.generate(
                20,
                (ordinal) => _opportunity(ordinal + 1,
                    legal: legal, executed: candidates[ordinal % 2])));
      }),
    );

P1StudyScientificSnapshot _insufficientRepeatedEvidence() => _snapshot(
      windows: List.generate(
          15,
          (index) => _window(
              index + 1,
              [
                ..._many(1, P1StudyCandidate.easy, 6),
                ..._many(7, P1StudyCandidate.medium, 7),
                ..._many(14, P1StudyCandidate.hard, 7),
              ],
              activity: 'distinct$index')),
    );

P1StudyScientificSnapshot _modeConfounding({
  required bool critical,
  bool makeMissing = false,
}) {
  final kept = critical ? 225 : 300;
  final windows = _recordsAsWindows(_feasibleRecords(kept));
  final outside = critical ? 76 : 76;
  windows.addAll(_recordsAsWindows(
      _feasibleRecords(outside, gameMode: 'blitz', startSegment: 100)));
  if (makeMissing) {
    windows.first.opportunities[0] = _opportunity(1, acceptedQeoLink: false);
  }
  return _snapshot(windows: windows);
}

P1StudyScientificSnapshot _playerConfounding({required bool critical}) {
  final kept = critical ? 225 : 300;
  final windows = _recordsAsWindows(_feasibleRecords(kept));
  windows.addAll(_recordsAsWindows(_feasibleRecords(critical ? 76 : 60,
      route: 'unresolvedPlayerRoute', startSegment: 100)));
  return _snapshot(windows: windows);
}

P1StudyScientificSnapshot _adaptiveConfounding({required bool critical}) {
  final kept = critical ? 225 : 300;
  final windows = _recordsAsWindows(_feasibleRecords(kept));
  windows.addAll(_recordsAsWindows(_feasibleRecords(critical ? 76 : 60,
      canonical: 'adaptive', startSegment: 100)));
  return _snapshot(windows: windows);
}

enum _F2Kind { player, adaptive, mode }

P1StudyScientificSnapshot _f2Confounded(
  _F2Kind kind, {
  required int affected,
  bool destroyMeasurement = false,
}) {
  final windows = destroyMeasurement
      ? _candidateDeficitWindows()
      : [..._feasibleSnapshot().windows];
  final affectedWindows = _recordsAsWindows(_feasibleRecords(
    affected,
    route: kind == _F2Kind.player
        ? 'unresolvedPlayerRoute'
        : 'freshSetupAcceptedConfiguration',
    gameMode: kind == _F2Kind.mode ? 'blitz' : 'standard',
    canonical: kind == _F2Kind.adaptive ? 'adaptive' : 'playerConfigured',
    startSegment: 100,
  ));
  windows.addAll(affectedWindows);
  return _snapshot(windows: windows);
}

P1StudyScientificSnapshot _withMalformedConfounder(
  P1StudyScientificSnapshot source,
  _F2Kind kind,
) {
  final windows = [...source.windows];
  windows.add(_window(
    999,
    [
      _opportunity(
        1,
        acceptedQeoLink: false,
        canonical: kind == _F2Kind.adaptive ? 'adaptive' : 'playerConfigured',
      ),
    ],
    route: kind == _F2Kind.player
        ? 'unresolvedPlayerRoute'
        : 'freshSetupAcceptedConfiguration',
    gameMode: kind == _F2Kind.mode ? 'blitz' : 'standard',
  ));
  return _snapshot(windows: windows);
}

P1StudyScientificSnapshot _withDuplicateConfounder(
  P1StudyScientificSnapshot source,
  _F2Kind kind,
) {
  final window = _window(
    999,
    [
      _opportunity(
        1,
        canonical: kind == _F2Kind.adaptive ? 'adaptive' : 'playerConfigured',
      ),
    ],
    route: kind == _F2Kind.player
        ? 'unresolvedPlayerRoute'
        : 'freshSetupAcceptedConfiguration',
    gameMode: kind == _F2Kind.mode ? 'blitz' : 'standard',
  );
  return _snapshot(windows: [...source.windows, window, window]);
}

P1StudyScientificSnapshot _withNullModeClassification(
  P1StudyScientificSnapshot source,
) =>
    _snapshot(windows: [
      ...source.windows,
      _window(998, [_opportunity(1)], gameMode: null),
    ]);

P1StudyScientificSnapshot _withF2Affected(
  P1StudyScientificSnapshot source,
  _F2Kind kind,
  int affected,
) {
  final windows = [...source.windows];
  windows.addAll(_recordsAsWindows(_feasibleRecords(
    affected,
    route: kind == _F2Kind.player
        ? 'unresolvedPlayerRoute'
        : 'freshSetupAcceptedConfiguration',
    gameMode: kind == _F2Kind.mode ? 'blitz' : 'standard',
    canonical: kind == _F2Kind.adaptive ? 'adaptive' : 'playerConfigured',
    startSegment: 100,
  )));
  return _snapshot(windows: windows);
}

P1StudyScientificSnapshot _withIndependentMalformed(
  P1StudyScientificSnapshot source,
  int count,
) {
  final windows = [...source.windows];
  for (var index = 0; index < count; index++) {
    windows.add(_window(
      800 + index,
      [_opportunity(1, acceptedQeoLink: false)],
    ));
  }
  return _snapshot(windows: windows);
}

void _expectConfounding(
  P1StudyConfoundingDiagnostics diagnostics,
  int affected,
  int total,
) {
  expect(diagnostics.affected, affected);
  expect(diagnostics.totalOtherwiseEligible, total);
  expect(diagnostics.affectedRate, affected / total);
}

List<P1StudyScientificWindow> _candidateDeficitWindows() {
  var hardToReplace = 41;
  return _feasibleSnapshot().windows.map((window) {
    return P1StudyScientificWindow(
      runSegmentId: window.runSegmentId,
      activityRunContext: window.activityRunContext,
      agencyRoute: window.agencyRoute,
      runType: window.runType,
      playerCount: window.playerCount,
      gameMode: window.gameMode,
      questionMechanic: window.questionMechanic,
      answerStyle: window.answerStyle,
      cleanEligible: window.cleanEligible,
      opportunities: window.opportunities.map((opportunity) {
        final replace = hardToReplace > 0 &&
            opportunity.executedCandidate == P1StudyCandidate.hard;
        if (replace) hardToReplace--;
        return P1StudyScientificOpportunity(
          opportunityOrdinalWithinRun: opportunity.opportunityOrdinalWithinRun,
          decisionContext: opportunity.decisionContext,
          decisionLocus: opportunity.decisionLocus,
          decisionLocusReason: opportunity.decisionLocusReason,
          legalCandidates: opportunity.legalCandidates,
          executedCandidate:
              replace ? P1StudyCandidate.easy : opportunity.executedCandidate,
          canonicalSelectionMechanism: opportunity.canonicalSelectionMechanism,
          operation: opportunity.operation,
          numberType: opportunity.numberType,
          terminal: opportunity.terminal,
          acceptedQeoLink: opportunity.acceptedQeoLink,
        );
      }).toList(),
    );
  }).toList();
}

void _expectF2Critical(
  P1StudyEvaluationResult result,
  P1StudyNotFeasibleReason reason,
) {
  expect(result.status, P1StudyEvaluationStatus.notFeasible);
  expect(result.notFeasibleReason, reason);
  final diagnostics = switch (reason) {
    P1StudyNotFeasibleReason.playerSelectionConfounding =>
      result.metrics.playerSelectionConfounding,
    P1StudyNotFeasibleReason.adaptiveCanonicalSelectionConfounding =>
      result.metrics.adaptiveCanonicalSelectionConfounding,
    P1StudyNotFeasibleReason.modeContextConfounding =>
      result.metrics.modeContextConfounding,
    _ => throw ArgumentError.value(reason),
  };
  _expectConfounding(diagnostics, 76, 376);
  expect(result.metrics.validOpportunityCount, 300);
  expect(
      result.metrics.candidateMetrics[P1StudyCandidate.easy]!.executedExposure,
      146);
  expect(
      result
          .metrics.candidateMetrics[P1StudyCandidate.medium]!.executedExposure,
      105);
  expect(
      result.metrics.candidateMetrics[P1StudyCandidate.hard]!.executedExposure,
      49);
  expect(result.metrics.qualifyingStratumCount, 2);
  expect(
      result
          .metrics.candidateMetrics[P1StudyCandidate.easy]!.comparableExposure,
      81);
  expect(
      result.metrics.candidateMetrics[P1StudyCandidate.medium]!
          .comparableExposure,
      70);
  expect(
      result
          .metrics.candidateMetrics[P1StudyCandidate.hard]!.comparableExposure,
      49);
  expect(result.metrics.comparableRunDiversity, 10);
  for (final metrics in result.metrics.candidateMetrics.values) {
    expect(metrics.wilson.status, WilsonEvaluationStatus.evaluable);
    expect(metrics.wilson.meetsPrecision, isTrue);
  }
}

P1StudyScientificSnapshot _routeStratifiedSnapshot() => _snapshot(
      windows: List.generate(15, (index) {
        final operation = switch (index ~/ 5) {
          0 => 'addition',
          1 => 'subtraction',
          _ => 'multiplication',
        };
        return _window(
            index + 1,
            _balanced(1, 6, operation: operation)
              ..addAll(
                  _many(19, P1StudyCandidate.easy, 1, operation: operation))
              ..addAll(
                  _many(20, P1StudyCandidate.medium, 1, operation: operation)),
            route: index.isEven
                ? 'freshSetupAcceptedConfiguration'
                : 'replayCarriedConfiguration');
      }),
    );

P1StudyScientificSnapshot _legalCoverageBelowThreshold() => _snapshot(
      windows: List.generate(
          15,
          (index) => _window(
              index + 1,
              index < 6
                  ? (_balanced(1, 6)
                    ..addAll(_many(19, P1StudyCandidate.easy, 1))
                    ..addAll(_many(20, P1StudyCandidate.medium, 1)))
                  : _many(1, P1StudyCandidate.medium, 20, legal: {
                      P1StudyCandidate.medium,
                      P1StudyCandidate.hard
                    }))),
    );

P1StudyScientificSnapshot _routeIncompatibleSnapshot() => _snapshot(
      windows: List.generate(
          15,
          (index) => _window(index + 1, _many(1, P1StudyCandidate.easy, 20),
              route: index.isEven
                  ? 'freshSetupAcceptedConfiguration'
                  : 'replayCarriedConfiguration')),
    );

List<P1StudyScientificWindow> _recordsAsWindows(List<_RecordSeed> records) {
  final bySegment = <int, _MutableWindow>{};
  for (final record in records) {
    (bySegment[record.segment] ??= _MutableWindow(record.segment,
            route: record.route, gameMode: record.gameMode))
        .opportunities
        .add(_opportunity(record.ordinal,
            executed: record.candidate, canonical: record.canonical));
  }
  return bySegment.values
      .map((window) => _window(window.segment, window.opportunities,
          route: window.route, gameMode: window.gameMode))
      .toList();
}

List<_RecordSeed> _feasibleRecords(
  int count, {
  String route = 'freshSetupAcceptedConfiguration',
  String gameMode = 'standard',
  String canonical = 'playerConfigured',
  int startSegment = 1,
}) =>
    List.generate(
        count,
        (index) => _RecordSeed(
              startSegment + index ~/ 20,
              index % 20 + 1,
              P1StudyCandidate.values[index % 3],
              route,
              gameMode,
              canonical,
            ));

final class _RecordSeed {
  const _RecordSeed(this.segment, this.ordinal, this.candidate, this.route,
      this.gameMode, this.canonical);
  final int segment;
  final int ordinal;
  final P1StudyCandidate candidate;
  final String route;
  final String gameMode;
  final String canonical;
}

final class _MutableWindow {
  _MutableWindow(this.segment, {required this.route, required this.gameMode});
  final int segment;
  final String route;
  final String gameMode;
  final opportunities = <P1StudyScientificOpportunity>[];
}
