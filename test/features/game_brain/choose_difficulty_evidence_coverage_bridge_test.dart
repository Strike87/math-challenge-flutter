import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  const bridge = ChooseDifficultyEvidenceCoverageBridge();

  test('1: present maps exactly to present', () {
    final result = bridge.project(
      snapshot: _snapshot([_present(Difficulty.easy)]),
      slotIdsByCandidate: {Difficulty.easy: 'opaque'},
    );

    expect(
        result.single.disposition, BoundedEvidenceCoverageDisposition.present);
  });

  test('2: absent maps exactly to notObserved', () {
    final result = bridge.project(
      snapshot: _snapshot([_absent(Difficulty.easy)]),
      slotIdsByCandidate: {Difficulty.easy: 'opaque'},
    );

    expect(result.single.disposition,
        BoundedEvidenceCoverageDisposition.notObserved);
  });

  test('3-4: mixed source states produce only the two mapped dispositions', () {
    final result = bridge.project(
      snapshot: _snapshot([
        _absent(Difficulty.hard),
        _present(Difficulty.easy),
      ]),
      slotIdsByCandidate: {
        Difficulty.hard: 'H',
        Difficulty.easy: 'E',
      },
    );

    expect(result.map((fact) => fact.disposition), [
      BoundedEvidenceCoverageDisposition.notObserved,
      BoundedEvidenceCoverageDisposition.present,
    ]);
    expect(
      result.every((fact) =>
          fact.disposition == BoundedEvidenceCoverageDisposition.present ||
          fact.disposition == BoundedEvidenceCoverageDisposition.notObserved),
      isTrue,
    );
  });

  test('5-6: opaque slot IDs and literal evidence order are preserved', () {
    final result = bridge.project(
      snapshot: _snapshot([
        _absent(Difficulty.hard),
        _absent(Difficulty.easy),
      ]),
      slotIdsByCandidate: {
        Difficulty.easy: ' left ',
        Difficulty.hard: 'RIGHT',
      },
    );

    expect(result.map((fact) => fact.slotId), ['RIGHT', ' left ']);
  });

  test('7-8: missing or extra slot bindings fail closed', () {
    final snapshot = _snapshot([_absent(Difficulty.easy)]);

    expect(
      () => bridge.project(snapshot: snapshot, slotIdsByCandidate: const {}),
      throwsArgumentError,
    );
    expect(
      () => bridge.project(
        snapshot: snapshot,
        slotIdsByCandidate: {
          Difficulty.easy: 'E',
          Difficulty.medium: 'M',
        },
      ),
      throwsArgumentError,
    );
  });

  test('9-13: slot IDs reject exact duplicates and blanks but retain variants',
      () {
    final snapshot = _snapshot([
      _absent(Difficulty.easy),
      _absent(Difficulty.medium),
    ]);

    for (final slotIds in [
      {Difficulty.easy: 'same', Difficulty.medium: 'same'},
      {Difficulty.easy: '', Difficulty.medium: 'M'},
      {Difficulty.easy: ' \t', Difficulty.medium: 'M'},
    ]) {
      expect(
        () => bridge.project(snapshot: snapshot, slotIdsByCandidate: slotIds),
        throwsArgumentError,
      );
    }
    expect(
      bridge.project(
        snapshot: snapshot,
        slotIdsByCandidate: {
          Difficulty.easy: 'slot',
          Difficulty.medium: 'SLOT',
        },
      ).map((fact) => fact.slotId),
      ['slot', 'SLOT'],
    );
    expect(
      bridge.project(
        snapshot: snapshot,
        slotIdsByCandidate: {
          Difficulty.easy: ' slot',
          Difficulty.medium: 'slot ',
        },
      ).map((fact) => fact.slotId),
      [' slot', 'slot '],
    );
  });

  test('14: duplicate legal candidates fail closed', () {
    expect(
      () => bridge.project(
        snapshot: _snapshot(
          [_absent(Difficulty.easy)],
          legalCandidates: [Difficulty.easy, Difficulty.easy],
        ),
        slotIdsByCandidate: {Difficulty.easy: 'E'},
      ),
      throwsArgumentError,
    );
  });

  test('15: duplicate evidence identities fail closed', () {
    expect(
      () => bridge.project(
        snapshot: _snapshot([
          _absent(Difficulty.easy),
          _absent(Difficulty.easy),
        ]),
        slotIdsByCandidate: {Difficulty.easy: 'E'},
      ),
      throwsArgumentError,
    );
  });

  test('16-17: evidence identity sets must match legal candidates exactly', () {
    expect(
      () => bridge.project(
        snapshot: _snapshot(
          [_absent(Difficulty.easy)],
          legalCandidates: [Difficulty.easy, Difficulty.medium],
        ),
        slotIdsByCandidate: {Difficulty.easy: 'E', Difficulty.medium: 'M'},
      ),
      throwsArgumentError,
    );
    expect(
      () => bridge.project(
        snapshot: _snapshot(
          [_absent(Difficulty.easy), _absent(Difficulty.medium)],
          legalCandidates: [Difficulty.easy],
        ),
        slotIdsByCandidate: {Difficulty.easy: 'E'},
      ),
      throwsArgumentError,
    );
  });

  test('18-20: all-empty output is immutable and detached from caller map', () {
    final empty = bridge.project(
      snapshot: _snapshot(const []),
      slotIdsByCandidate: const {},
    );
    expect(empty, isEmpty);
    expect(() => empty.add(_fact('later')), throwsUnsupportedError);

    final slotIds = <Difficulty, String>{Difficulty.easy: 'before'};
    final result = bridge.project(
      snapshot: _snapshot([_absent(Difficulty.easy)]),
      slotIdsByCandidate: slotIds,
    );
    slotIds[Difficulty.easy] = 'after';
    expect(result.single.slotId, 'before');
    expect(() => result.clear(), throwsUnsupportedError);
  });

  test(
      '21-23: source firewall excludes topology, EST aggregation, and inference',
      () {
    final source = _withoutCommentsAndStrings(
      File('lib/features/game_brain/decision/'
              'choose_difficulty_evidence_coverage_bridge.dart')
          .readAsStringSync(),
    );
    final barrel =
        File('lib/features/game_brain/game_brain.dart').readAsStringSync();

    for (final pattern in [
      'Difficulty.values',
      '.index',
      'candidate.name',
      'indexOf(',
      'sort(',
      'sorted',
      'compareTo(',
      'DifficultyCandidateTopologyHandoff',
      'BoundedEvidenceCoverageSummarizer',
      'BoundedEvidenceCoverageSummary',
      'ScenarioDefinition',
      'ScenarioKnowledgeLibrary',
      'higher',
      'lower',
      'adjacent',
      'minimum',
      'threshold',
      'sufficient',
      'insufficient',
      'sparse',
      'recommend',
      'policy',
      'scenario',
    ]) {
      expect(source, isNot(contains(pattern)));
    }
    expect(
      barrel,
      contains(
          "export 'decision/choose_difficulty_evidence_coverage_bridge.dart';"),
    );
  });
}

ChooseDifficultyEvidenceSnapshot _snapshot(
  List<ChooseDifficultyCandidateEvidence> candidates, {
  List<Difficulty>? legalCandidates,
}) =>
    ChooseDifficultyEvidenceSnapshot(
      context: _context,
      legalCandidates: legalCandidates ??
          candidates.map((entry) => entry.candidate).toList(),
      candidates: candidates,
    );

ChooseDifficultyCandidateEvidence _present(Difficulty candidate) =>
    ChooseDifficultyCandidateEvidence(
      candidate: candidate,
      availability: ChooseDifficultyEvidenceAvailability.present,
      aggregate: const BoundedContextShadowInterpreter().interpret([
        ContextEvidenceObservation(
          context: _context,
          difficulty: Difficulty.easy,
          correctAnswer: 1,
          submittedAnswer: 1,
          correct: true,
          timedOut: false,
          responseTimeMs: 1,
        ),
      ]).aggregate!,
    );

ChooseDifficultyCandidateEvidence _absent(Difficulty candidate) =>
    ChooseDifficultyCandidateEvidence(
      candidate: candidate,
      availability: ChooseDifficultyEvidenceAvailability.absent,
      aggregate: null,
    );

BoundedEvidenceCoverageFact _fact(String slotId) => BoundedEvidenceCoverageFact(
      slotId: slotId,
      disposition: BoundedEvidenceCoverageDisposition.present,
    );

final _context = ContextEvidenceKey(
  operation: Operation.addition,
  numberType: NumberType.natural,
);

String _withoutCommentsAndStrings(String source) => source.replaceAll(
      RegExp(
        r'''//.*?$|/\*[\s\S]*?\*/|'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"''',
        multiLine: true,
      ),
      '',
    );
