import '../../../models/enums.dart';

class NumberTypeUnlockPolicy {
  const NumberTypeUnlockPolicy();

  int priceFor(NumberType type) => switch (type) {
        NumberType.integers => 500,
        NumberType.rationals => 1200,
        _ => 0,
      };

  bool requiresPurchase(
    NumberType type,
    Map<String, int> ownership,
  ) =>
      priceFor(type) > 0 && (ownership[type.name] ?? 0) < 1;

  bool canAfford(NumberType type, int balance) => balance >= priceFor(type);
}
