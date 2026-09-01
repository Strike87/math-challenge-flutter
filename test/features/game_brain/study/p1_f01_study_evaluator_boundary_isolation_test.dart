import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/study/p1_f01_study_evaluator.dart';

void main() {
  group('P1 Study evaluator isolated high-N boundaries', () {
    test('canonical feasible fixture establishes the mutation postcondition',
        () {
      final result = evaluateP1Study(buildCanonicalFeasibleFixture());
      expect(result.status, P1StudyEvaluationStatus.feasible);
      expect(result.metrics.rawOpportunityCount, 1000);
      expect(result.metrics.validOpportunityCount, 1000);
      expect(result.metrics.qualifyingStratumCount, greaterThanOrEqualTo(4));
      expect(result.metrics.comparableRunDiversity, greaterThanOrEqualTo(12));
      for (final metrics in result.metrics.candidateMetrics.values) {
        expect(metrics.executedExposure, greaterThan(60));
        expect(metrics.comparableExposure, greaterThan(30));
        expect(metrics.legalCoverage, greaterThan(.40));
        expect(metrics.runConcentration, lessThan(.25));
        expect(metrics.temporalConcentration, lessThan(.50));
        expect(metrics.wilson.meetsPrecision, isTrue);
      }
    });

    test('global missingness is isolated at 50/1000 and 51/1000', () {
      final exact = evaluateP1Study(_allLegal(1000, invalid: 50));
      final over = evaluateP1Study(_allLegal(1000, invalid: 51));
      expect(exact.metrics.globalMissingness, .05);
      expect(exact.status, P1StudyEvaluationStatus.feasible);
      expect(over.metrics.globalMissingness, .051);
      expect(over.inconclusiveReason,
          P1StudyInconclusiveReason.missingnessAboveThreshold);
    });

    test('R1D known missing receipts preserve the exact global threshold', () {
      final exact = evaluateP1Study(_r1dKnownMissingReceipts(50));
      final over = evaluateP1Study(_r1dKnownMissingReceipts(51));

      expect(exact.metrics.rawOpportunityCount, 1000);
      expect(exact.metrics.validOpportunityCount, 950);
      expect(exact.metrics.missingOpportunityCount, 50);
      expect(exact.metrics.globalMissingness, .05);
      expect(exact.status, P1StudyEvaluationStatus.feasible);

      expect(over.metrics.rawOpportunityCount, 1000);
      expect(over.metrics.validOpportunityCount, 949);
      expect(over.metrics.missingOpportunityCount, 51);
      expect(over.metrics.globalMissingness, .051);
      expect(over.status, P1StudyEvaluationStatus.inconclusive);
      expect(over.inconclusiveReason,
          P1StudyInconclusiveReason.missingnessAboveThreshold);
    });

    test('O_valid has the exact 300/299 terminal boundary', () {
      final pass = evaluateP1Study(_allLegal(300));
      final fail = evaluateP1Study(_allLegal(300, invalid: 1));
      expect(pass.metrics.validOpportunityCount, 300);
      expect(pass.status, P1StudyEvaluationStatus.feasible);
      expect(fail.metrics.validOpportunityCount, 299);
      expect(fail.metrics.globalMissingness, 1 / 300);
      expect(fail.inconclusiveReason,
          P1StudyInconclusiveReason.commonSupportInsufficient);
    });

    for (final target in P1StudyCandidate.values) {
      test('executed $target has the exact 60/59 terminal boundary', () {
        final pass = evaluateP1Study(_executedBoundary(target));
        final fail = evaluateP1Study(_executedBoundary(target, reduce: true));
        expect(pass.metrics.candidateMetrics[target]!.executedExposure, 60);
        expect(pass.status, P1StudyEvaluationStatus.feasible);
        expect(fail.metrics.candidateMetrics[target]!.executedExposure, 59);
        expect(fail.inconclusiveReason,
            P1StudyInconclusiveReason.commonSupportInsufficient);
      });

      test(
          'minimum cell for $target is qualification-only with three protected strata',
          () {
        final pass = evaluateP1Study(_qualificationBoundary(target));
        final fail =
            evaluateP1Study(_qualificationBoundary(target, fail: true));
        expect(pass.metrics.qualifyingStratumCount, 4);
        expect(fail.metrics.qualifyingStratumCount, 3);
        expect(pass.status, isNot(P1StudyEvaluationStatus.notFeasible));
        expect(fail.status, isNot(P1StudyEvaluationStatus.notFeasible));
      });

      test('legal coverage for $target is exact 400/1000 and 399/1000', () {
        final pass = evaluateP1Study(_legalCoverageBoundary(target, 400));
        final fail = evaluateP1Study(_legalCoverageBoundary(target, 399));
        expect(pass.metrics.candidateMetrics[target]!.legalCoverage, .40);
        expect(pass.status, P1StudyEvaluationStatus.feasible);
        expect(fail.metrics.candidateMetrics[target]!.legalCoverage, .399);
        expect(fail.inconclusiveReason,
            P1StudyInconclusiveReason.legalCoverageInsufficient);
      });
    }

    test(
        'three versus two qualifying strata is a common-support coupled boundary',
        () {
      final pass = evaluateP1Study(_strataBoundary(3));
      final fail = evaluateP1Study(_strataBoundary(2));
      expect(pass.metrics.qualifyingStratumCount, 3);
      expect(fail.metrics.qualifyingStratumCount, 2);
      expect(fail.inconclusiveReason,
          P1StudyInconclusiveReason.commonSupportInsufficient);
      for (final candidate in P1StudyCandidate.values) {
        expect(
            pass.metrics.candidateMetrics[candidate]!
                .qualifyingStrataRepresented,
            3);
        expect(
            fail.metrics.candidateMetrics[candidate]!
                .qualifyingStrataRepresented,
            2);
      }
    });

    test('comparable exposure 30/29 is coupled to three/two qualifying strata',
        () {
      final pass = evaluateP1Study(_comparableBoundary(fail: false));
      final fail = evaluateP1Study(_comparableBoundary(fail: true));
      final target = P1StudyCandidate.easy;
      expect(pass.metrics.validOpportunityCount, 300);
      expect(pass.metrics.qualifyingStratumCount, 3);
      expect(pass.metrics.candidateMetrics[target]!.comparableExposure, 30);
      expect(pass.metrics.candidateMetrics[target]!.executedExposure,
          greaterThanOrEqualTo(60));
      expect(
          pass.metrics.candidateMetrics[target]!.wilson.meetsPrecision, isTrue);
      expect(pass.status, P1StudyEvaluationStatus.feasible);
      expect(fail.metrics.validOpportunityCount, 300);
      expect(fail.metrics.qualifyingStratumCount, 2);
      expect(fail.metrics.candidateMetrics[target]!.comparableExposure, 29);
      expect(fail.metrics.candidateMetrics[target]!.executedExposure,
          greaterThanOrEqualTo(60));
      expect(fail.metrics.starvation, 0);
      expect(fail.inconclusiveReason,
          P1StudyInconclusiveReason.commonSupportInsufficient);
    });

    for (final candidate in P1StudyCandidate.values) {
      test('candidate $candidate missingness is isolated at 40/400 and 41/400',
          () {
        final exact =
            evaluateP1Study(_candidateCoverage(candidate, invalid: 40));
        final over =
            evaluateP1Study(_candidateCoverage(candidate, invalid: 41));
        expect(exact.metrics.candidateMetrics[candidate]!.missingness, .10);
        expect(exact.status, P1StudyEvaluationStatus.feasible,
            reason: '${exact.inconclusiveReason}');
        expect(over.metrics.candidateMetrics[candidate]!.missingness, .1025);
        expect(over.inconclusiveReason,
            P1StudyInconclusiveReason.missingnessAboveThreshold);
      });

      test(
          'candidate $candidate temporal concentration is isolated at 50/100 and 51/100',
          () {
        final exact = evaluateP1Study(_concentration(candidate, early: 50));
        final over = evaluateP1Study(_concentration(candidate, early: 51));
        expect(exact.metrics.candidateMetrics[candidate]!.temporalConcentration,
            .50);
        expect(exact.status, P1StudyEvaluationStatus.feasible,
            reason: '${exact.inconclusiveReason}');
        expect(over.metrics.candidateMetrics[candidate]!.temporalConcentration,
            .51);
        expect(over.inconclusiveReason,
            P1StudyInconclusiveReason.runOrTemporalDiversityInsufficient);
      });
    }
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

P1StudyScientificSnapshot buildCanonicalFeasibleFixture() => _allLegal(1000);

P1StudyScientificSnapshot _allLegal(int count, {int invalid = 0}) {
  final records = <_R>[];
  for (var index = 0; index < count; index++) {
    records.add(_R(
      candidate: P1StudyCandidate.values[index % 3],
      operation: _operations[(index ~/ 20) % _operations.length],
      accepted: index >= invalid,
    ));
  }
  return _snapshot(records);
}

/// This is the immutable shape emitted by the Store's R1D counter-difference
/// projection: known legal membership, but no durable opening fields.
P1StudyScientificSnapshot _r1dKnownMissingReceipts(int missing) {
  final base = _allLegal(1000 - missing);
  return P1StudyScientificSnapshot(
    epochSequence: base.epochSequence,
    measurementAvailable: base.measurementAvailable,
    windows: [
      ...base.windows,
      P1StudyScientificWindow(
        runSegmentId: base.windows.length + 1,
        activityRunContext: 'quickPracticeTimingPractice',
        agencyRoute: 'freshSetupAcceptedConfiguration',
        runType: 'normal',
        playerCount: 1,
        gameMode: 'standard',
        questionMechanic: 'standard',
        answerStyle: 'choice4',
        cleanEligible: false,
        opportunities: List.generate(
          missing,
          (_) => const P1StudyScientificOpportunity(
            opportunityOrdinalWithinRun: null,
            decisionContext: null,
            decisionLocus: null,
            decisionLocusReason: null,
            legalCandidates: {
              P1StudyCandidate.easy,
              P1StudyCandidate.medium,
              P1StudyCandidate.hard,
            },
            executedCandidate: null,
            canonicalSelectionMechanism: null,
            operation: null,
            numberType: null,
            terminal: null,
            acceptedQeoLink: null,
          ),
        ),
      ),
    ],
  );
}

P1StudyScientificSnapshot _candidateCoverage(
  P1StudyCandidate target, {
  required int invalid,
}) {
  final other =
      P1StudyCandidate.values.where((value) => value != target).toList();
  final records = <_R>[];
  // 400 triple-legal records supply five clean, qualifying support strata.
  for (var index = 0; index < 400; index++) {
    records.add(_R(
      candidate: P1StudyCandidate.values[index % 3],
      operation: _operations[(index ~/ 80) % 5],
      accepted: index >= invalid,
    ));
  }
  // The remaining receipts intentionally exclude the target from the legal
  // set. They are valid but cannot be common-support evidence for it.
  for (var index = 0; index < 500; index++) {
    records.add(_R(
      candidate: other[index % 2],
      legal: {other[0], other[1]},
      operation: _operations[(index ~/ 20) % _operations.length],
    ));
  }
  return _snapshot(records);
}

P1StudyScientificSnapshot _executedBoundary(
  P1StudyCandidate target, {
  bool reduce = false,
}) {
  final other = P1StudyCandidate.values
      .where((candidate) => candidate != target)
      .toList();
  final records = <_R>[];
  for (var group = 0; group < 5; group++) {
    records.addAll(List<_R>.filled(
      12,
      _R(candidate: target, operation: _operations[group]),
    ));
    records.addAll(List<_R>.filled(
      24,
      _R(candidate: other[0], operation: _operations[group]),
    ));
    records.addAll(List<_R>.filled(
      24,
      _R(candidate: other[1], operation: _operations[group]),
    ));
  }
  if (reduce) {
    final index = records.indexWhere((record) => record.candidate == target);
    records[index] =
        _R(candidate: other[0], operation: records[index].operation);
  }
  return _snapshot(records);
}

P1StudyScientificSnapshot _qualificationBoundary(
  P1StudyCandidate target, {
  bool fail = false,
}) {
  final other = P1StudyCandidate.values
      .where((candidate) => candidate != target)
      .toList();
  final records = <_R>[];
  for (var group = 0; group < 4; group++) {
    final targetCount = group == 3 && fail
        ? 9
        : group == 3
            ? 10
            : 25;
    final firstOther = group == 3 && fail
        ? 25
        : group == 3
            ? 25
            : 18;
    final secondOther = 60 - targetCount - firstOther;
    records.addAll(List<_R>.filled(
        targetCount, _R(candidate: target, operation: _operations[group])));
    records.addAll(List<_R>.filled(
        firstOther, _R(candidate: other[0], operation: _operations[group])));
    records.addAll(List<_R>.filled(
        secondOther, _R(candidate: other[1], operation: _operations[group])));
  }
  for (var index = records.length; index < 300; index++) {
    records.add(_R(
        candidate: other[index % 2],
        legal: {other[0], other[1]},
        operation: _operations[index % 5]));
  }
  return _snapshot(records);
}

P1StudyScientificSnapshot _strataBoundary(int qualifying) {
  final records = <_R>[];
  for (var group = 0; group < qualifying; group++) {
    for (final candidate in P1StudyCandidate.values) {
      records.addAll(List<_R>.filled(
          20, _R(candidate: candidate, operation: _operations[group])));
    }
  }
  for (var index = records.length; index < 300; index++) {
    records.add(_R(
      candidate: index.isEven ? P1StudyCandidate.easy : P1StudyCandidate.medium,
      legal: {P1StudyCandidate.easy, P1StudyCandidate.medium},
      operation: _operations[index % 5],
    ));
  }
  return _snapshot(records);
}

P1StudyScientificSnapshot _comparableBoundary({required bool fail}) {
  final records = <_R>[];
  final counts = fail
      ? const [
          [10, 10, 10],
          [19, 10, 10],
        ]
      : const [
          [10, 10, 10],
          [10, 10, 10],
          [10, 10, 10],
        ];
  for (var group = 0; group < counts.length; group++) {
    final remaining = [...counts[group]];
    while (remaining.any((count) => count > 0)) {
      for (var index = 0; index < P1StudyCandidate.values.length; index++) {
        if (remaining[index]-- > 0) {
          records.add(_R(
            candidate: P1StudyCandidate.values[index],
            operation: _operations[group],
          ));
        }
      }
    }
  }
  final pairs = const [
    {P1StudyCandidate.easy, P1StudyCandidate.medium},
    {P1StudyCandidate.easy, P1StudyCandidate.hard},
    {P1StudyCandidate.medium, P1StudyCandidate.hard},
  ];
  while (records.length < 300) {
    final legal = pairs[records.length % pairs.length];
    records.add(_R(
      candidate: legal.elementAt(records.length % legal.length),
      legal: legal,
      operation: _operations[records.length % _operations.length],
    ));
  }
  return _snapshot(records, recordsPerWindow: 9);
}

P1StudyScientificSnapshot _legalCoverageBoundary(
  P1StudyCandidate target,
  int targetLegal,
) {
  final other = P1StudyCandidate.values
      .where((candidate) => candidate != target)
      .toList();
  final records = <_R>[];
  for (var index = 0; index < targetLegal; index++) {
    records.add(_R(
      candidate: P1StudyCandidate.values[index % 3],
      operation: _operations[(index ~/ 80) % 5],
    ));
  }
  while (records.length < 1000) {
    records.add(_R(
      candidate: other[records.length % 2],
      legal: {other[0], other[1]},
      operation: _operations[records.length % 5],
    ));
  }
  return _snapshot(records);
}

P1StudyScientificSnapshot _concentration(
  P1StudyCandidate target, {
  required int early,
}) {
  final other =
      P1StudyCandidate.values.where((value) => value != target).toList();
  final groups = <P1StudyCandidate, List<int>>{
    for (final candidate in P1StudyCandidate.values)
      candidate: List<int>.generate(100, (index) => index ~/ 20),
  };
  final positions = <P1StudyCandidate, int>{
    for (final candidate in P1StudyCandidate.values) candidate: 0,
  };
  final comparable = <_R>[];
  void add(P1StudyCandidate candidate, int count) {
    for (var index = 0; index < count; index++) {
      final position = positions[candidate]!;
      final group = groups[candidate]![position];
      positions[candidate] = position + 1;
      comparable.add(_R(candidate: candidate, operation: _operations[group]));
    }
  }

  // The first 60 comparable observations form one temporal quintile.
  add(target, early);
  final firstOther = (60 - early) ~/ 2;
  add(other[0], firstOther);
  add(other[1], 60 - early - firstOther);
  var remainingTarget = 100 - early;
  var remainingFirst = 100 - firstOther;
  for (var bin = 0; bin < 5; bin++) {
    final binsLeft = 5 - bin;
    final targetCount = remainingTarget ~/ binsLeft;
    final firstCount = remainingFirst ~/ binsLeft;
    final secondCount = 48 - targetCount - firstCount;
    add(target, targetCount);
    add(other[0], firstCount);
    add(other[1], secondCount);
    remainingTarget -= targetCount;
    remainingFirst -= firstCount;
  }
  // 300 tri-legal comparable receipts: each support key has E/M/H = 20.
  // The queues above have exact 100 records per candidate, so group allocation
  // remains 20 per candidate and is independently checkable by the evaluator.
  expect(comparable, hasLength(300));
  final nonComparable = <_R>[];
  for (var index = 0; index < 700; index++) {
    final legal = switch (index % 7) {
      0 || 1 => {target, other[0]},
      _ => {other[0], other[1]},
    };
    nonComparable.add(_R(
      candidate: legal.contains(other[0]) ? other[0] : other[1],
      legal: legal,
      operation: _operations[index % _operations.length],
    ));
  }
  return _snapshot([...comparable, ...nonComparable]);
}

P1StudyScientificSnapshot _snapshot(
  List<_R> records, {
  int recordsPerWindow = 20,
}) =>
    P1StudyScientificSnapshot(
      epochSequence: 1,
      measurementAvailable: true,
      windows: List.generate(
          (records.length + recordsPerWindow - 1) ~/ recordsPerWindow,
          (windowIndex) {
        final slice = records
            .skip(windowIndex * recordsPerWindow)
            .take(recordsPerWindow)
            .toList();
        return P1StudyScientificWindow(
          runSegmentId: windowIndex + 1,
          activityRunContext: 'quickPracticeTimingPractice',
          agencyRoute: 'freshSetupAcceptedConfiguration',
          runType: 'normal',
          playerCount: 1,
          gameMode: 'standard',
          questionMechanic: 'standard',
          answerStyle: 'choice4',
          cleanEligible: true,
          opportunities: List.generate(slice.length, (ordinal) {
            final record = slice[ordinal];
            return P1StudyScientificOpportunity(
              opportunityOrdinalWithinRun: ordinal + 1,
              decisionContext: 'chooseDifficulty',
              decisionLocus: 'questionOpeningDifficultyResolution',
              decisionLocusReason: 'difficultyRequiredForQuestionOpening',
              legalCandidates: record.legal,
              executedCandidate: record.candidate,
              canonicalSelectionMechanism: 'playerConfigured',
              operation: record.operation,
              numberType: 'natural',
              terminal: P1StudyTerminal.answeredCorrect,
              acceptedQeoLink: record.accepted,
            );
          }),
        );
      }),
    );

final class _R {
  const _R({
    required this.candidate,
    required this.operation,
    this.legal = const {
      P1StudyCandidate.easy,
      P1StudyCandidate.medium,
      P1StudyCandidate.hard,
    },
    this.accepted = true,
  });
  final P1StudyCandidate candidate;
  final String operation;
  final Set<P1StudyCandidate> legal;
  final bool accepted;
}

const _operations = [
  'addition',
  'subtraction',
  'multiplication',
  'division',
  'mixed'
];
