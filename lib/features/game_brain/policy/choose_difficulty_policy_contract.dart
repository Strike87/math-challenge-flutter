import '../../../models/enums.dart';
import '../evaluation/choose_difficulty_candidate_epistemic_preservation.dart';

enum ChooseDifficultyPolicyAuthority { none }

final class ChooseDifficultyPolicyIdentity {
  ChooseDifficultyPolicyIdentity({required this.id, required this.version}) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be blank');
    }
    if (version <= 0) {
      throw ArgumentError.value(version, 'version', 'must be positive');
    }
  }

  final String id;
  final int version;
}

sealed class ChooseDifficultyPolicyResolution {
  const ChooseDifficultyPolicyResolution({
    required this.source,
    required this.identity,
  });

  final ChooseDifficultyEpistemicPreservationSet source;
  final ChooseDifficultyPolicyIdentity identity;

  ChooseDifficultyPolicyAuthority get authority =>
      ChooseDifficultyPolicyAuthority.none;
  bool get mayAffectGameplay => false;
}

final class ChooseDifficultyNoPreference
    extends ChooseDifficultyPolicyResolution {
  const ChooseDifficultyNoPreference({
    required super.source,
    required super.identity,
  });
}

final class ChooseDifficultyPreferredCandidate
    extends ChooseDifficultyPolicyResolution {
  ChooseDifficultyPreferredCandidate({
    required super.source,
    required super.identity,
    required this.candidate,
  }) {
    if (!source.candidates
        .any((item) => item.candidateDifficulty == candidate)) {
      throw ArgumentError.value(candidate, 'candidate', 'is not preserved');
    }
  }

  final Difficulty candidate;
}

abstract interface class VersionedChooseDifficultyPolicy {
  ChooseDifficultyPolicyIdentity get identity;

  ChooseDifficultyPolicyResolution resolve({
    required ChooseDifficultyEpistemicPreservationSet evidence,
  });
}
