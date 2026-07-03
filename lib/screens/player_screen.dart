import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_state.dart';
import '../game_config.dart';
import '../services/settings.dart';
import '../widgets/common.dart';

class PlayerSetupScreen extends StatefulWidget {
  const PlayerSetupScreen({super.key});

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  int _setupStep = 0;

  void _goBack(GameState gs) {
    if (gs.players == 2 && _setupStep == 1) {
      setState(() => _setupStep = 0);
      return;
    }
    _setupStep = 0;
    gs.backFromPlayers();
  }

  void _submit(GameState gs) {
    if (gs.players == 2 && _setupStep == 0) {
      setState(() => _setupStep = 1);
      return;
    }
    setState(() => _setupStep = 0);
    gs.startGame();
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final s = context.watch<SettingsService>();
    if (gs.players != 2 && _setupStep != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _setupStep = 0);
      });
    }
    final twoPlayer = gs.players == 2 &&
        gs.rt.challenge.name != 'master' &&
        gs.rt.challenge.name != 'dailyBoss';
    final currentPid = twoPlayer && _setupStep == 1 ? 2 : 1;
    final title = twoPlayer ? 'Player $currentPid Setup' : 'Player Setup';
    final primaryLabel = twoPlayer && _setupStep == 0 ? 'Next' : 'Start Game';
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        key: const Key('player-setup-back'),
                        icon: const Icon(Icons.arrow_back),
                        color: s.text,
                        onPressed: () => _goBack(gs),
                      ),
                      Expanded(
                        child: Text(
                          title,
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
                  _PlayerSection(pid: currentPid, gs: gs, s: s),
                  const SizedBox(height: 24),
                  NeoButton(
                    key: const Key('player-setup-primary'),
                    label: primaryLabel,
                    color: GameConfig.coral,
                    onPressed: () => _submit(gs),
                  ),
                ],
              ),
            ),
          );
        },
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
      key: Key('player-setup-section-p$pid'),
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

          // Tappable avatar card — same emoji picker used by Settings.
          GestureDetector(
            key: Key('player-setup-avatar-tile-p$pid'),
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
                          'Tap to change',
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

          // Quick-pick strip — unlocked emoji avatars only.
          SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: gs.availableAvatarBases.length,
              itemBuilder: (_, i) {
                final a = gs.availableAvatarBases[i];
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
                key: Key('player-setup-customize-p$pid'),
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
          TextFormField(
            key: Key('player-setup-name-p$pid'),
            initialValue: pl.name,
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
  });
  final Object avatar;
  final bool selected;
  final VoidCallback onTap;

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
        child: Center(child: AvatarWidget(avatar: avatar, size: 40)),
      ),
    );
  }
}
