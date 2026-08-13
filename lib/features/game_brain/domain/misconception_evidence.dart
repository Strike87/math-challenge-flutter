/// Caller-tagged evidence retained verbatim for later, separately approved
/// interpretation. BRAIN-01 does not derive hypotheses from this value.
final class MisconceptionEvidence {
  MisconceptionEvidence({required this.tag}) {
    if (tag.trim().isEmpty) {
      throw ArgumentError.value(tag, 'tag', 'must not be empty');
    }
  }

  final String tag;
}
