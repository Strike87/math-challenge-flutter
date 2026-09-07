enum BoundedEvidenceCoverageDisposition {
  present,
  notObserved,
  filtered,
  excluded,
  unsupported,
  notCaptured,
  evicted,
  unavailable,
  unknown,
}

enum BoundedEvidenceCoverageAuthority { none }

final class BoundedEvidenceCoverageFact {
  BoundedEvidenceCoverageFact({
    required this.slotId,
    required this.disposition,
  }) {
    if (slotId.trim().isEmpty) {
      throw ArgumentError.value(slotId, 'slotId', 'must not be blank');
    }
  }

  final String slotId;
  final BoundedEvidenceCoverageDisposition disposition;
}

final class BoundedEvidenceCoverageSummary {
  const BoundedEvidenceCoverageSummary._({
    required this.slotCount,
    required this.presentCount,
    required this.notObservedCount,
    required this.filteredCount,
    required this.excludedCount,
    required this.unsupportedCount,
    required this.notCapturedCount,
    required this.evictedCount,
    required this.unavailableCount,
    required this.unknownCount,
  });

  final int slotCount;
  final int presentCount;
  final int notObservedCount;
  final int filteredCount;
  final int excludedCount;
  final int unsupportedCount;
  final int notCapturedCount;
  final int evictedCount;
  final int unavailableCount;
  final int unknownCount;

  BoundedEvidenceCoverageAuthority get authority =>
      BoundedEvidenceCoverageAuthority.none;

  bool get mayAffectGameplay => false;
}

final class BoundedEvidenceCoverageSummarizer {
  const BoundedEvidenceCoverageSummarizer();

  BoundedEvidenceCoverageSummary summarize(
    List<BoundedEvidenceCoverageFact> facts,
  ) {
    final slotIds = <String>{};
    var presentCount = 0;
    var notObservedCount = 0;
    var filteredCount = 0;
    var excludedCount = 0;
    var unsupportedCount = 0;
    var notCapturedCount = 0;
    var evictedCount = 0;
    var unavailableCount = 0;
    var unknownCount = 0;

    for (final fact in facts) {
      if (!slotIds.add(fact.slotId)) {
        throw ArgumentError.value(fact.slotId, 'slotId', 'must be unique');
      }
      switch (fact.disposition) {
        case BoundedEvidenceCoverageDisposition.present:
          presentCount++;
        case BoundedEvidenceCoverageDisposition.notObserved:
          notObservedCount++;
        case BoundedEvidenceCoverageDisposition.filtered:
          filteredCount++;
        case BoundedEvidenceCoverageDisposition.excluded:
          excludedCount++;
        case BoundedEvidenceCoverageDisposition.unsupported:
          unsupportedCount++;
        case BoundedEvidenceCoverageDisposition.notCaptured:
          notCapturedCount++;
        case BoundedEvidenceCoverageDisposition.evicted:
          evictedCount++;
        case BoundedEvidenceCoverageDisposition.unavailable:
          unavailableCount++;
        case BoundedEvidenceCoverageDisposition.unknown:
          unknownCount++;
      }
    }

    return BoundedEvidenceCoverageSummary._(
      slotCount: facts.length,
      presentCount: presentCount,
      notObservedCount: notObservedCount,
      filteredCount: filteredCount,
      excludedCount: excludedCount,
      unsupportedCount: unsupportedCount,
      notCapturedCount: notCapturedCount,
      evictedCount: evictedCount,
      unavailableCount: unavailableCount,
      unknownCount: unknownCount,
    );
  }
}
