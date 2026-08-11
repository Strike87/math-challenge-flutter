enum FamilyEligibility { unresolved, child, eligible }

enum FamilyAgeRange { under13, teen13to17, adult18plus }

extension FamilyAgeRangeEligibility on FamilyAgeRange {
  FamilyEligibility get eligibility => switch (this) {
        FamilyAgeRange.under13 => FamilyEligibility.child,
        FamilyAgeRange.teen13to17 ||
        FamilyAgeRange.adult18plus =>
          FamilyEligibility.eligible,
      };
}

FamilyAgeRange? parseFamilyAgeRange(String value) {
  for (final range in FamilyAgeRange.values) {
    if (value == range.name) return range;
  }
  return null;
}
