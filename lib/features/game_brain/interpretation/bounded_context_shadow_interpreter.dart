import '../../../models/enums.dart';
import '../domain/context_evidence.dart';

class BoundedContextAggregate {
  BoundedContextAggregate({
    required this.evidenceCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.timeoutCount,
  }) {
    if (evidenceCount < 0 ||
        correctCount < 0 ||
        incorrectCount < 0 ||
        timeoutCount < 0) {
      throw ArgumentError('Observation counts must not be negative.');
    }
    if (evidenceCount != correctCount + incorrectCount + timeoutCount) {
      throw ArgumentError('evidenceCount must equal the outcome counts.');
    }
  }

  final int evidenceCount;
  final int correctCount;
  final int incorrectCount;
  final int timeoutCount;

  double get accuracy => evidenceCount == 0 ? 0 : correctCount / evidenceCount;
}

enum BoundedContextShadowInterpretationState { observational, insufficient }

enum BoundedContextShadowAuthority { none }

class BoundedContextShadowInterpretation {
  const BoundedContextShadowInterpretation({
    required this.state,
    required this.aggregate,
    required this.factualContextId,
    required this.explanation,
  });

  final BoundedContextShadowInterpretationState state;
  final BoundedContextAggregate? aggregate;
  final String? factualContextId;
  final String explanation;
  BoundedContextShadowAuthority get authority =>
      BoundedContextShadowAuthority.none;
  bool get mayAffectGameplay => false;
}

class BoundedContextShadowInterpreter {
  const BoundedContextShadowInterpreter();

  BoundedContextShadowInterpretation interpret(
    List<ContextEvidenceObservation> observations,
  ) {
    final facts = _validateHomogeneous(observations);
    if (facts == null) {
      return const BoundedContextShadowInterpretation(
        state: BoundedContextShadowInterpretationState.insufficient,
        aggregate: null,
        factualContextId: null,
        explanation: 'No bounded context observations are available.',
      );
    }

    final aggregate = _aggregate(observations);
    final contextId = _contextId(facts);
    return BoundedContextShadowInterpretation(
      state: BoundedContextShadowInterpretationState.observational,
      aggregate: aggregate,
      factualContextId: contextId,
      explanation: 'Observed ${aggregate.evidenceCount} context observations: '
          '${aggregate.correctCount} correct, ${aggregate.incorrectCount} incorrect, '
          '${aggregate.timeoutCount} timeout; derived accuracy '
          '${aggregate.accuracy.toStringAsFixed(2)}. Factual context: $contextId.',
    );
  }

  ({ContextEvidenceKey context, Difficulty difficulty})? _validateHomogeneous(
    List<ContextEvidenceObservation> observations,
  ) {
    if (observations.isEmpty) return null;

    final context = observations.first.context;
    if (context == null) {
      throw ArgumentError('Each observation must have a context.');
    }
    final difficulty = observations.first.difficulty;
    for (final observation in observations) {
      if (observation.context == null) {
        throw ArgumentError('Each observation must have a context.');
      }
      if (observation.context != context) {
        throw ArgumentError('Observations must have the same context.');
      }
      if (observation.difficulty != difficulty) {
        throw ArgumentError('Observations must have the same difficulty.');
      }
    }
    return (context: context, difficulty: difficulty);
  }

  BoundedContextAggregate _aggregate(
    List<ContextEvidenceObservation> observations,
  ) {
    var correctCount = 0;
    var incorrectCount = 0;
    var timeoutCount = 0;
    for (final observation in observations) {
      if (observation.timedOut) {
        timeoutCount++;
      } else if (observation.correct) {
        correctCount++;
      } else {
        incorrectCount++;
      }
    }
    return BoundedContextAggregate(
      evidenceCount: observations.length,
      correctCount: correctCount,
      incorrectCount: incorrectCount,
      timeoutCount: timeoutCount,
    );
  }

  String _contextId(
          ({ContextEvidenceKey context, Difficulty difficulty}) facts) =>
      'operation=${facts.context.operation.name};'
      'numberType=${facts.context.numberType.name};'
      'representation=${facts.context.representation.name};'
      'difficulty=${facts.difficulty.name}';
}
