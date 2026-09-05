import '../domain/context_evidence.dart';
import 'bounded_context_shadow_interpreter.dart';

final class BoundedContextShadowEpisode {
  const BoundedContextShadowEpisode._({
    required this.sequence,
    required this.interpretation,
  });

  final int sequence;
  final BoundedContextShadowInterpretation interpretation;
  BoundedContextShadowAuthority get authority =>
      BoundedContextShadowAuthority.none;
  bool get mayAffectGameplay => false;
}

final class BoundedContextShadowEpisodeRecorder {
  BoundedContextShadowEpisodeRecorder({
    required this.capacity,
    BoundedContextShadowInterpreter interpreter =
        const BoundedContextShadowInterpreter(),
  }) : _interpreter = interpreter {
    if (capacity <= 0) {
      throw ArgumentError.value(capacity, 'capacity', 'must be positive');
    }
  }

  final int capacity;
  final BoundedContextShadowInterpreter _interpreter;
  final List<BoundedContextShadowEpisode> _episodes = [];
  int _nextSequence = 1;

  List<BoundedContextShadowEpisode> get episodes =>
      List.unmodifiable(_episodes);

  BoundedContextShadowEpisode record(
    List<ContextEvidenceObservation> observations,
  ) {
    final interpretation = _interpreter.interpret(observations);
    final episode = BoundedContextShadowEpisode._(
      sequence: _nextSequence++,
      interpretation: interpretation,
    );
    if (_episodes.length == capacity) _episodes.removeAt(0);
    _episodes.add(episode);
    return episode;
  }
}
