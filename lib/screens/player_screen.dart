import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_state.dart';
import '../game_config.dart';
import '../models/player.dart';
import '../services/settings.dart';
import '../widgets/common.dart';

class PlayerSetupScreen extends StatelessWidget {
  const PlayerSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final s = context.watch<SettingsService>();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: s.text,
                  onPressed: gs.backFromPlayers,
                ),
                Expanded(
                  child: Text(
                    'Player Setup',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: s.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontFamily: AppFonts.head,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 16),

            // Player 1
            _PlayerSection(pid: 1, gs: gs, s: s),
            const SizedBox(height: 20),

            // Player 2 (only if 2-player mode)
            if (gs.players == 2 &&
                gs.rt.challenge.name != 'master' &&
                gs.rt.challenge.name != 'dailyBoss')
              _PlayerSection(pid: 2, gs: gs, s: s),

            const SizedBox(height: 24),
            NeoButton(
              label: 'Start Game ▶',
              color: GameConfig.coral,
              onPressed: gs.startGame,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerSection extends StatelessWidget {
  const _PlayerSection({required this.pid, required this.gs, required this.s});
  final int pid;
  final GameState gs;
  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    final pl = gs.p[pid];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(GameConfig.borderMdLight)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Player $pid Avatar',
            style: TextStyle(
              color: s.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // Tappable avatar card — opens full picker with ~50 emojis
          GestureDetector(
            onTap: () async {
              final current = pl.avatar is String ? pl.avatar as String : '🐶';
              final selected = await showDialog<String>(
                context: context,
                builder: (_) => AvatarPickerDialog(
                  currentAvatar: current,
                  availableAvatars: gs.availableAvatarBases,
                ),
              );
              if (selected != null) {
                gs.pickAvatar(pid, selected);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: s.surface2.withValues(alpha: s.dark ? 0.90 : 0.70),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(GameConfig.coral).withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color:
                          const Color(GameConfig.coral).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(GameConfig.coral)
                            .withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: AvatarWidget(avatar: pl.avatar, size: 40),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pl.avatar is AvatarCustom
                              ? 'Custom avatar'
                              : 'Tap to change',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontFamily: AppFonts.body,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${gs.availableAvatarBases.length} unlocked emojis',
                          style: TextStyle(
                            color: s.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Quick-pick strip — original 11 emojis + Custom option
          SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: gs.availableAvatarBases.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return _AvatarOption(
                    avatar: gs.avatarCustom['$pid']!,
                    selected: pl.avatar is AvatarCustom,
                    onTap: () => gs.showAvatarBuilder(pid),
                    isCustom: true,
                  );
                }
                final a = gs.availableAvatarBases[i - 1];
                return _AvatarOption(
                  avatar: a,
                  selected: pl.avatar == a,
                  onTap: () => gs.pickAvatar(pid, a),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              NeoButton(
                label: '🎨 Customize Avatar',
                color: GameConfig.grape,
                fontSize: 12,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                onPressed: () => gs.showAvatarBuilder(pid),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                child: AvatarWidget(avatar: pl.avatar, size: 28),
              ),
              hintText: 'Enter Player $pid name',
              filled: true,
              fillColor: s.surface2.withValues(alpha: s.dark ? 0.90 : 0.70),
              counterStyle: TextStyle(color: s.muted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: s.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: s.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide:
                    const BorderSide(color: Color(GameConfig.coral), width: 2),
              ),
            ),
            controller: TextEditingController(text: pl.name),
            maxLength: 20,
            onChanged: (v) => gs.setPlayerName(pid, v),
          ),
        ],
      ),
    );
  }
}

class _AvatarOption extends StatelessWidget {
  const _AvatarOption({
    required this.avatar,
    required this.selected,
    required this.onTap,
    this.isCustom = false,
  });
  final Object avatar;
  final bool selected;
  final VoidCallback onTap;
  final bool isCustom;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(GameConfig.coral).withValues(alpha: 0.15)
              : s.surface2.withValues(alpha: s.dark ? 0.90 : 0.70),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(GameConfig.coral)
                : Colors.white.withValues(alpha: 0.7),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color:
                        const Color(GameConfig.coral).withValues(alpha: 0.20),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Center(child: AvatarWidget(avatar: avatar, size: 40)),
            if (isCustom)
              const Positioned(
                top: 4,
                right: 4,
                child: Text('🎨', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}
