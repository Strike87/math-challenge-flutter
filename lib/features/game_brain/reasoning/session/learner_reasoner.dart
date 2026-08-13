import '../../../../models/enums.dart';
import '../../domain/brain_memory_entry.dart';
import '../../domain/session_evidence.dart';

/// Pure seam for deriving a conservative, session-only learner hypothesis.
abstract interface class LearnerReasoner {
  SessionEvidence reason(
    List<BrainMemoryEntry> entries,
    Operation operation,
  );
}
