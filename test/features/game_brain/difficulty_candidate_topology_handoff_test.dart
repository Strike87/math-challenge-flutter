import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  const candidates = [Difficulty.easy, Difficulty.medium, Difficulty.hard];

  DifficultyCandidateTopologyHandoff handoff({
    Difficulty reference = Difficulty.easy,
    Difficulty candidate = Difficulty.hard,
    DifficultyCandidateRelation relation =
        DifficultyCandidateRelation.higherThanReference,
    List<Difficulty> legalCandidates = candidates,
  }) =>
      DifficultyCandidateTopologyHandoff(
        reference: reference,
        candidate: candidate,
        relation: relation,
        legalCandidates: legalCandidates,
      );

  test('preserves supplied higher and lower relations exactly', () {
    expect(handoff().relation, DifficultyCandidateRelation.higherThanReference);
    expect(
      handoff(relation: DifficultyCandidateRelation.lowerThanReference)
          .relation,
      DifficultyCandidateRelation.lowerThanReference,
    );
  });

  test('accepts equality only with the same relation', () {
    expect(
      handoff(
        reference: Difficulty.medium,
        candidate: Difficulty.medium,
        relation: DifficultyCandidateRelation.sameAsReference,
      ).relation,
      DifficultyCandidateRelation.sameAsReference,
    );
    for (final relation in [
      DifficultyCandidateRelation.higherThanReference,
      DifficultyCandidateRelation.lowerThanReference,
    ]) {
      expect(
        () => handoff(
          reference: Difficulty.medium,
          candidate: Difficulty.medium,
          relation: relation,
        ),
        throwsArgumentError,
      );
    }
  });

  test('rejects same relation for different difficulties', () {
    expect(
      () => handoff(relation: DifficultyCandidateRelation.sameAsReference),
      throwsArgumentError,
    );
  });

  test('accepts an externally supplied surprising direction', () {
    expect(
      handoff(relation: DifficultyCandidateRelation.lowerThanReference)
          .relation,
      DifficultyCandidateRelation.lowerThanReference,
    );
  });

  test('requires supplied Phase-1 reference and candidate membership', () {
    expect(
      () => handoff(legalCandidates: const [Difficulty.hard]),
      throwsArgumentError,
    );
    expect(
      () => handoff(
        candidate: Difficulty.medium,
        legalCandidates: const [Difficulty.easy, Difficulty.hard],
      ),
      throwsArgumentError,
    );
  });

  test('rejects duplicate and unsupported candidates', () {
    for (final legalCandidates in [
      [Difficulty.easy, Difficulty.easy],
      [Difficulty.easy, Difficulty.expert],
      [Difficulty.easy, Difficulty.insane],
    ]) {
      expect(
          () => handoff(legalCandidates: legalCandidates), throwsArgumentError);
    }
  });

  test('rejects unsupported reference and candidate', () {
    expect(() => handoff(reference: Difficulty.expert), throwsArgumentError);
    expect(() => handoff(candidate: Difficulty.insane), throwsArgumentError);
  });

  test('copies and preserves supplied candidate order', () {
    final supplied = <Difficulty>[
      Difficulty.hard,
      Difficulty.easy,
      Difficulty.medium,
    ];
    final result = handoff(
      reference: Difficulty.easy,
      candidate: Difficulty.hard,
      legalCandidates: supplied,
    );
    supplied.clear();

    expect(
      result.legalCandidates,
      const [Difficulty.hard, Difficulty.easy, Difficulty.medium],
    );
    expect(() => result.legalCandidates.clear(), throwsUnsupportedError);
  });

  test('remains authority-free', () {
    final result = handoff();

    expect(result.authority, DifficultyCandidateTopologyAuthority.none);
    expect(result.mayAffectGameplay, isFalse);
  });

  test('carries no inverse or global-ordering API', () {
    final source = _withoutCommentsAndStrings(
      File(
        'lib/features/game_brain/decision/difficulty_candidate_topology_handoff.dart',
      ).readAsStringSync(),
    );

    expect(
      RegExp(
        r'\b(?:adjacentHigher|adjacentLower|nextHigher|nextLower|'
        r'rankCandidates|sortCandidates|findHigherCandidate|'
        r'findLowerCandidate|recommend\w*|policy\w*|inverse\w*|'
        r'transitiv\w*|globalOrder\w*)\b',
      ).hasMatch(source),
      isFalse,
    );
  });

  test('source firewall excludes topology inference and prohibited imports',
      () {
    final source = _withoutCommentsAndStrings(
      File(
        'lib/features/game_brain/decision/difficulty_candidate_topology_handoff.dart',
      ).readAsStringSync(),
    );

    expect(
      RegExp(
        r'Difficulty\.values|\.index\b|\bindexOf\s*\(|\bsort\s*\('
        r'|\bsorted\b|\bcompareTo\s*\(|AdaptiveDifficultyEngine'
        r'|QuestionDifficultyLegality|Scenario(?:Definition|KnowledgeLibrary)'
        r'|GB-EST-\d+',
      ).hasMatch(source),
      isFalse,
    );
  });
}

String _withoutCommentsAndStrings(String source) => source
    .replaceAll(RegExp(r"'(?:\\.|[^'\\])*'"), '')
    .replaceAll(RegExp(r'"(?:\\.|[^"\\])*"'), '')
    .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
    .replaceAll(RegExp(r'//.*'), '');
