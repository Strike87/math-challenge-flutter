import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_state.dart';
import '../game_config.dart';
import '../models/player.dart';
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
    if (gs.setupPlayers == 2 && _setupStep == 1) {
      setState(() => _setupStep = 0);
      return;
    }
    _setupStep = 0;
    gs.backFromPlayers();
  }

  void _submit(GameState gs) {
    if (gs.setupPlayers == 2 && _setupStep == 0) {
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

    if (gs.setupPlayers != 2 && _setupStep != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _setupStep = 0);
      });
    }

    final twoPlayer = gs.setupPlayers == 2 &&
        gs.rt.challenge.name != 'master' &&
        gs.rt.challenge.name != 'dailyBoss';
    final currentPid = twoPlayer && _setupStep == 1 ? 2 : 1;
    final title = twoPlayer ? 'Player $currentPid Setup' : 'Player Setup';
    final subtitle = !twoPlayer
        ? 'Create your player'
        : currentPid == 1
            ? 'First player, get ready'
            : 'Second player, your turn';
    final primaryLabel = twoPlayer && _setupStep == 0 ? 'Next' : 'Start Game';
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 96 + keyboardInset),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SetupHeader(
                        title: title,
                        subtitle: subtitle,
                        onBack: () => _goBack(gs),
                        s: s,
                      ),
                      if (twoPlayer) ...[
                        const SizedBox(height: 8),
                        _PlayerProgress(
                          currentStep: _setupStep,
                          s: s,
                        ),
                      ],
                      const SizedBox(height: 10),
                      _PlayerSection(
                        pid: currentPid,
                        gs: gs,
                        s: s,
                        singlePlayer: !twoPlayer,
                      ),
                      const SizedBox(height: 14),
                      NeoButton(
                        key: const Key('player-setup-primary'),
                        label: primaryLabel,
                        color: GameConfig.coral,
                        onPressed: () => _submit(gs),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SetupHeader extends StatelessWidget {
  const _SetupHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.s,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    const accent = Color(GameConfig.sky);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Material(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                key: const Key('player-setup-back'),
                borderRadius: BorderRadius.circular(15),
                onTap: onBack,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: s.text,
                  size: 21,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: s.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontFamily: AppFonts.head,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: s.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 52),
        ],
      ),
    );
  }
}

class _PlayerProgress extends StatelessWidget {
  const _PlayerProgress({
    required this.currentStep,
    required this.s,
  });

  final int currentStep;
  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    const coral = Color(GameConfig.coral);

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: coral.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ProgressStep(
              label: 'Player 1',
              active: currentStep == 0,
              completed: currentStep == 1,
              s: s,
            ),
          ),
          Container(
            width: 28,
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color:
                  currentStep == 1 ? coral.withValues(alpha: 0.55) : s.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Expanded(
            child: _ProgressStep(
              label: 'Player 2',
              active: currentStep == 1,
              completed: false,
              s: s,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.label,
    required this.active,
    required this.completed,
    required this.s,
  });

  final String label;
  final bool active;
  final bool completed;
  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    const coral = Color(GameConfig.coral);
    final highlighted = active || completed;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: highlighted
                ? coral.withValues(alpha: 0.13)
                : s.surface2.withValues(alpha: s.dark ? 0.90 : 0.75),
            border: Border.all(
              color: highlighted ? coral : s.border,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Icon(
            completed
                ? Icons.check_rounded
                : active
                    ? Icons.circle
                    : Icons.circle_outlined,
            size: completed ? 14 : 8,
            color: highlighted ? coral : s.muted,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? s.text : s.muted,
              fontSize: 10.5,
              fontWeight: active ? FontWeight.w900 : FontWeight.w700,
              fontFamily: AppFonts.body,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerSection extends StatelessWidget {
  const _PlayerSection({
    required this.pid,
    required this.gs,
    required this.s,
    required this.singlePlayer,
  });

  final int pid;
  final GameState gs;
  final SettingsService s;
  final bool singlePlayer;

  @override
  Widget build(BuildContext context) {
    final pl = gs.p[pid];
    const coral = Color(GameConfig.coral);

    return Container(
      key: Key('player-setup-section-p$pid'),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: coral.withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompactSectionLabel(
            icon: Icons.person_rounded,
            label: singlePlayer ? 'YOUR PLAYER' : 'PLAYER $pid',
            s: s,
          ),
          const SizedBox(height: 8),

          // Tappable avatar card — same emoji picker used by Settings.
          GestureDetector(
            key: Key('player-setup-avatar-tile-p$pid'),
            onTap: () async {
              final selected = await showDialog<String>(
                context: context,
                builder: (_) => AvatarPickerDialog(
                  currentAvatar: pl.avatar.storageEmoji,
                  availableAvatars: gs.availableAvatarBases,
                ),
              );
              if (selected != null) {
                gs.pickAvatar(pid, selected);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: coral.withValues(alpha: s.dark ? 0.10 : 0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: coral.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: coral.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: coral.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Center(
                      child: AvatarWidget(
                        avatar: pl.avatar,
                        size: 39,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tap to change',
                          style: TextStyle(
                            color: s.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            fontFamily: AppFonts.head,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${gs.availableAvatarBases.length} unlocked emojis available',
                          style: TextStyle(
                            color: s.muted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: coral,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniLabel(
                label: 'QUICK PICKS',
                s: s,
              ),
              NeoButton(
                key: Key('player-setup-customize-p$pid'),
                label: '🎨 Customize Avatar',
                color: GameConfig.grape,
                fontSize: 11,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                onPressed: () => gs.showAvatarBuilder(pid),
              ),
            ],
          ),
          const SizedBox(height: 7),

          // Quick-pick strip — unlocked emoji avatars only.
          SizedBox(
            height: 58,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: gs.availableAvatarBases.length,
              itemBuilder: (_, i) {
                final a = gs.availableAvatarBases[i];
                return _AvatarOption(
                  avatar: a,
                  selected: pl.avatar.storageEmoji == a,
                  onTap: () => gs.pickAvatar(pid, a),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          _MiniLabel(
            label: 'PLAYER NAME',
            s: s,
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: Key('player-setup-name-p$pid'),
            initialValue: pl.name,
            decoration: InputDecoration(
              prefixIcon: Container(
                margin: const EdgeInsets.all(7),
                child: AvatarWidget(
                  avatar: pl.avatar,
                  size: 26,
                ),
              ),
              hintText: 'Enter Player $pid name',
              filled: true,
              fillColor: s.surface2.withValues(alpha: s.dark ? 0.90 : 0.70),
              counterStyle: TextStyle(
                color: s.muted,
                fontSize: 10,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: s.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: s.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(GameConfig.coral),
                  width: 2,
                ),
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

class _CompactSectionLabel extends StatelessWidget {
  const _CompactSectionLabel({
    required this.icon,
    required this.label,
    required this.s,
  });

  final IconData icon;
  final String label;
  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    const coral = Color(GameConfig.coral);

    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: coral.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            color: coral,
            size: 15,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: s.text,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontFamily: AppFonts.head,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniLabel extends StatelessWidget {
  const _MiniLabel({
    required this.label,
    required this.s,
  });

  final String label;
  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: s.muted,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        fontFamily: AppFonts.head,
        letterSpacing: 0.8,
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

  final String avatar;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    const coral = Color(GameConfig.coral);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: selected
              ? coral.withValues(alpha: 0.15)
              : s.surface2.withValues(alpha: s.dark ? 0.90 : 0.70),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? coral : s.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: coral.withValues(alpha: 0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: AvatarWidget(
                avatar: AvatarData.emoji(avatar),
                size: 36,
              ),
            ),
            if (selected)
              Positioned(
                right: 3,
                top: 3,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: coral,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
