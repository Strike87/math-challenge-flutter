import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';

void main() {
  const summarizer = BoundedEvidenceCoverageSummarizer();

  test('1: empty input has zero independent counts', () {
    expect(_counts(summarizer.summarize(const [])),
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
  });

  for (final entry in BoundedEvidenceCoverageDisposition.values.indexed) {
    test('${entry.$1 + 2}: ${entry.$2.name} increments only its count', () {
      final counts = _counts(summarizer.summarize([_fact('slot', entry.$2)]));

      expect(counts.first, 1);
      for (var index = 1; index < counts.length; index++) {
        expect(counts[index], index == entry.$1 + 1 ? 1 : 0);
      }
    });
  }

  test('11: mixed facts retain exact independent counts and invariant', () {
    final result = summarizer.summarize([
      for (final entry in BoundedEvidenceCoverageDisposition.values.indexed)
        _fact('slot-${entry.$1}', entry.$2),
      _fact('second-present', BoundedEvidenceCoverageDisposition.present),
    ]);

    expect(_counts(result), [10, 2, 1, 1, 1, 1, 1, 1, 1, 1]);
    expect(_counts(result).skip(1).reduce((sum, count) => sum + count),
        result.slotCount);
  });

  test('12: duplicate IDs fail closed using exact equality', () {
    expect(
      () => summarizer.summarize([
        _fact('slot', BoundedEvidenceCoverageDisposition.present),
        _fact('slot', BoundedEvidenceCoverageDisposition.unknown),
      ]),
      throwsArgumentError,
    );
  });

  test('13: blank and whitespace-only IDs fail closed', () {
    expect(
      () => _fact('', BoundedEvidenceCoverageDisposition.present),
      throwsArgumentError,
    );
    expect(
      () => _fact(' \t', BoundedEvidenceCoverageDisposition.present),
      throwsArgumentError,
    );
  });

  test('14: case and literal whitespace variants remain distinct', () {
    final result = summarizer.summarize([
      _fact('slot', BoundedEvidenceCoverageDisposition.present),
      _fact('SLOT', BoundedEvidenceCoverageDisposition.notObserved),
      _fact(' slot', BoundedEvidenceCoverageDisposition.filtered),
      _fact('slot ', BoundedEvidenceCoverageDisposition.excluded),
    ]);

    expect(_counts(result), [4, 1, 1, 1, 1, 0, 0, 0, 0, 0]);
  });

  test('15: summary is unchanged after caller list mutation', () {
    final facts = [_fact('slot', BoundedEvidenceCoverageDisposition.present)];
    final result = summarizer.summarize(facts);
    facts.add(_fact('later', BoundedEvidenceCoverageDisposition.unknown));

    expect(_counts(result), [1, 1, 0, 0, 0, 0, 0, 0, 0, 0]);
  });

  test('16: summary has aggregate counts and no gameplay authority', () {
    final result = summarizer.summarize(const []);

    expect(result, isNot(isA<List<BoundedEvidenceCoverageFact>>()));
    expect(result.authority, BoundedEvidenceCoverageAuthority.none);
    expect(result.mayAffectGameplay, isFalse);
  });

  test('17: source firewall excludes adapters and prohibited concepts', () {
    final source = _withoutCommentsAndStrings(
      File('lib/features/game_brain/est/bounded_evidence_coverage.dart')
          .readAsStringSync(),
    );
    final barrel =
        File('lib/features/game_brain/game_brain.dart').readAsStringSync();

    for (final pattern in [
      'missingCount',
      'missingRate',
      'missingness',
      'coverageRate',
      'threshold',
      'minimumN',
      'confidenceInterval',
      'pValue',
      'effectSize',
      'bootstrap',
      'commonSupport',
      'higherDifficulty',
      'lowerDifficulty',
      'Difficulty.values',
      '.index',
      'scenario',
      'recommendation',
      'policy',
      'temporal',
      'ContextEvidenceObservation',
      'ChooseDifficultyEvidenceSnapshot',
      'BoundedContextShadowPartitionedSnapshot',
      'BoundedContextShadowEpisodeRecorder',
      'P1StudyScientificSnapshot',
    ]) {
      expect(source, isNot(contains(pattern)));
    }
    expect(barrel, contains("export 'est/bounded_evidence_coverage.dart';"));
  });
}

BoundedEvidenceCoverageFact _fact(
  String slotId,
  BoundedEvidenceCoverageDisposition disposition,
) =>
    BoundedEvidenceCoverageFact(slotId: slotId, disposition: disposition);

List<int> _counts(BoundedEvidenceCoverageSummary summary) => [
      summary.slotCount,
      summary.presentCount,
      summary.notObservedCount,
      summary.filteredCount,
      summary.excludedCount,
      summary.unsupportedCount,
      summary.notCapturedCount,
      summary.evictedCount,
      summary.unavailableCount,
      summary.unknownCount,
    ];

String _withoutCommentsAndStrings(String source) => source.replaceAll(
      RegExp(
        r'''//.*?$|/\*[\s\S]*?\*/|'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"''',
        multiLine: true,
      ),
      '',
    );
