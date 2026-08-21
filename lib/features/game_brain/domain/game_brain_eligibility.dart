import '../../family/domain/family_eligibility.dart';

enum GameBrainEligibility { unresolved, ineligible, eligible }

GameBrainEligibility gameBrainEligibilityFor(FamilyAgeRange? ageRange) =>
    switch (ageRange) {
      null => GameBrainEligibility.unresolved,
      FamilyAgeRange.under13 => GameBrainEligibility.ineligible,
      FamilyAgeRange.teen13to17 ||
      FamilyAgeRange.adult18plus =>
        GameBrainEligibility.eligible,
    };
