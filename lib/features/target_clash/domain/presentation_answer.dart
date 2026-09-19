enum PresentationAnswer {
  lessThan,
  equalTo,
  greaterThan;

  static PresentationAnswer classify(num expressionValue, num targetValue) {
    if (!expressionValue.isFinite || !targetValue.isFinite) {
      throw ArgumentError('Relation values must be finite.');
    }
    if (expressionValue < targetValue) return lessThan;
    if (expressionValue > targetValue) return greaterThan;
    return equalTo;
  }
}
