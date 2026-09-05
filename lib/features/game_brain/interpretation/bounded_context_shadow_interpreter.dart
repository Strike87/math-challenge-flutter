import '../../../models/enums.dart';
import '../domain/context_evidence.dart';
import '../est/bounded_outcome_descriptive_summary.dart';

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
    if (observations.isEmpty) {
      return const BoundedContextShadowInterpretation(
        state: BoundedContextShadowInterpretationState.insufficient,
        aggregate: null,
        factualContextId: null,
        explanation: 'No bounded context observations are available.',
      );
    }

    final summary = const BoundedOutcomeDescriptiveSummarizer().summarize(
      observations,
    );
    final aggregate = BoundedContextAggregate(
      evidenceCount: summary.evidenceCount,
      correctCount: summary.correctCount,
      incorrectCount: summary.incorrectCount,
      timeoutCount: summary.timeoutCount,
    );
    final contextId = _contextId(summary.context!, summary.difficulty!);
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

  String _contextId(ContextEvidenceKey context, Difficulty difficulty) =>
      'operation=${context.operation.name};'
      'numberType=${context.numberType.name};'
      'representation=${context.representation.name};'
      'difficulty=${difficulty.name}';
}
