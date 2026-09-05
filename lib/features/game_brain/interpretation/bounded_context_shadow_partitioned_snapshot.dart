import '../../../models/enums.dart';
import '../domain/context_evidence.dart';
import 'bounded_context_shadow_interpreter.dart';

final class BoundedContextShadowPartitionedSnapshot {
  BoundedContextShadowPartitionedSnapshot(
    List<BoundedContextShadowInterpretation> partitions,
  ) : partitions = List.unmodifiable(partitions);

  final List<BoundedContextShadowInterpretation> partitions;

  BoundedContextShadowAuthority get authority =>
      BoundedContextShadowAuthority.none;
  bool get mayAffectGameplay => false;
}

final class BoundedContextShadowPartitionedInterpreter {
  const BoundedContextShadowPartitionedInterpreter();

  BoundedContextShadowPartitionedSnapshot interpret(
    List<ContextEvidenceObservation> observations,
  ) {
    final groups = <({ContextEvidenceKey context, Difficulty difficulty}),
        List<ContextEvidenceObservation>>{};
    for (final observation in observations) {
      final context = observation.context;
      if (context == null) {
        throw ArgumentError('Each observation must have a context.');
      }
      (groups[(context: context, difficulty: observation.difficulty)] ??= [])
          .add(observation);
    }

    final partitions = groups.values
        .map(const BoundedContextShadowInterpreter().interpret)
        .toList()
      ..sort((first, second) =>
          first.factualContextId!.compareTo(second.factualContextId!));
    return BoundedContextShadowPartitionedSnapshot(partitions);
  }
}
