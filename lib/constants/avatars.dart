// Expanded avatar list for Math Challenge.
//
// Originally the HTML game had 11 animal emojis. We've expanded to ~50
// across 5 themed categories for more variety.
//
// Usage:
//   import '../constants/avatars.dart';
//   final emoji = AvatarPool.all.first;  // '🐶'
//   final random = AvatarPool.random();  // random pick

class AvatarPool {
  AvatarPool._();

  // ===== Original 11 from HTML game (kept at the top for backward compat) =====
  static const List<String> originals = [
    '🐶', '🐱', '🦁', '🐸', '🐼', '🦊', '🐯', '🦋', '🐙', '🦉', '🐧',
  ];

  // ===== Mammals =====
  static const List<String> mammals = [
    '🐶', '🐱', '🦁', '🐼', '🦊', '🐯', '🐺', '🐻', '🐨', '🐮',
    '🐷', '🐹', '🐰', '🐭', '🦄', '🐎', '🦓', '🦒', '🐘',
    '🦏', '🦛', '🐒', '🦍', '🦧', '🐕', '🐈', '🦘', '🦨', '🦡',
  ];

  // ===== Birds =====
  static const List<String> birds = [
    '🦉', '🐧', '🐦', '🐤', '🦆', '🦅', '🕊️', '🦢', '🦜', '🦩',
    '🐔', '🦃', '🦚', '🦤',
  ];

  // ===== Sea & reptiles =====
  static const List<String> sea = [
    '🐸', '🐙', '🐬', '🐳', '🐋', '🦈', '🐟', '🐠', '🦐', '🦀',
    '🦞', '🐚', '🦑', '🐢', '🐍', '🦎', '🐊',
  ];

  // ===== Bugs & small critters =====
  static const List<String> bugs = [
    '🦋', '🐝', '🐞', '🐜', '🦗', '🕷️', '🦂', '🐌', '🦟',
  ];

  // ===== Mythical / fantasy (fun bonus) =====
  static const List<String> fantasy = [
    '🦄', '🐉', '🐲', '🦕', '🦖',
  ];

  /// All avatars merged (deduplicated, original 11 first).
  static final List<String> all = _buildAll();

  static List<String> _buildAll() {
    final seen = <String>{};
    final out = <String>[];
    for (final list in [originals, mammals, birds, sea, bugs, fantasy]) {
      for (final e in list) {
        if (!seen.contains(e)) {
          seen.add(e);
          out.add(e);
        }
      }
    }
    return out;
  }

  /// Categories for the picker UI.
  static const List<AvatarCategory> categories = [
    AvatarCategory(name: 'Original',  emojis: originals),
    AvatarCategory(name: 'Mammals',   emojis: mammals),
    AvatarCategory(name: 'Birds',     emojis: birds),
    AvatarCategory(name: 'Sea',       emojis: sea),
    AvatarCategory(name: 'Bugs',      emojis: bugs),
    AvatarCategory(name: 'Fantasy',   emojis: fantasy),
  ];

  /// Pick a random avatar — useful for default assignment.
  static String random() {
    final i = DateTime.now().millisecondsSinceEpoch % all.length;
    return all[i];
  }
}

class AvatarCategory {
  final String name;
  final List<String> emojis;
  const AvatarCategory({required this.name, required this.emojis});
}
