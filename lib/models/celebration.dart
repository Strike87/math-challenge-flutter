/// A lightweight event object for celebratory UI.
///
/// The incrementing [id] lets widgets detect a new event even when the same
/// kind/emoji fires twice in a row.
class CelebrationEvent {
  const CelebrationEvent({
    required this.id,
    required this.kind,
    required this.emoji,
    required this.message,
  });

  const CelebrationEvent.none()
      : id = 0,
        kind = CelebrationKind.none,
        emoji = '',
        message = '';

  final int id;
  final CelebrationKind kind;
  final String emoji;
  final String message;

  bool get isActive => id > 0 && kind != CelebrationKind.none;
}

enum CelebrationKind {
  none,
  achievement,
  stageClear,
  bossClear,
  win,
  perfect,
  reward,
}
