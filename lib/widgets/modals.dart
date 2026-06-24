import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_state.dart';
import '../game_config.dart';
import '../models/enums.dart';
import '../models/game_data.dart';
import '../services/settings.dart';
import '../widgets/common.dart';

/// Container for all modal dialogs. Routed by [GameState.currentModal].
class ModalRouter extends StatelessWidget {
  const ModalRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    if (gs.currentModal == GameModal.none) return const SizedBox.shrink();
    return Stack(
      children: [
        ModalBarrier(
          color: Colors.black54,
          dismissible: false,
        ),
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
            margin: const EdgeInsets.all(24),
            child: _pickModal(gs, context),
          ),
        ),
      ],
    );
  }

  Widget _pickModal(GameState gs, BuildContext context) {
    switch (gs.currentModal) {
      case GameModal.settings:        return SettingsModal(gs: gs);
      case GameModal.masterIntro:     return MasterIntroModal(gs: gs);
      case GameModal.dailyBoss:       return DailyBossModal(gs: gs);
      case GameModal.stageCleared:    return StageClearedModal(gs: gs);
      case GameModal.win:             return WinModal(gs: gs);
      case GameModal.quitConfirm:     return QuitConfirmModal(gs: gs);
      case GameModal.highScore:       return HighScoreModal(gs: gs);
      case GameModal.achievements:    return AchievementsModal(gs: gs);
      case GameModal.tutorial:        return TutorialModal(gs: gs);
      case GameModal.avatarBuilder:   return AvatarBuilderModal(gs: gs);
      case GameModal.skillDashboard:  return SkillDashboardModal(gs: gs);
      case GameModal.coinShop:        return CoinShopModal(gs: gs);
      case GameModal.dailyChallenges: return DailyChallengesModal(gs: gs);
      case GameModal.none:            return const SizedBox.shrink();
    }
  }
}

/// Base modal shell with icon + title + content + actions.
class ModalShell extends StatelessWidget {
  const ModalShell({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.actions = const [],
    this.maxHeight,
  });
  final String icon;
  final String title;
  final Widget child;
  final List<Widget> actions;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return Container(
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight ?? 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 4),
              Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: s.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: AppFonts.head,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(child: SingleChildScrollView(child: child)),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Settings Modal
// ═══════════════════════════════════════════════════════════════
class SettingsModal extends StatelessWidget {
  const SettingsModal({super.key, required this.gs});
  final GameState gs;

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, s, _) => ModalShell(
        icon: '⚙️',
        title: 'Settings',
        actions: [
          NeoButton(
            label: 'Done',
            color: GameConfig.coral,
            onPressed: gs.closeModal,
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _section('Player Avatar', s),
            _AvatarSettingsTile(gs: gs),
            const SizedBox(height: 16),
            _section('Display & Audio', s),
            Row(
              children: [
                _TrioBtn(icon: '🌓', label: 'Dark Mode', state: s.dark ? 'ON' : 'OFF', active: s.dark, onTap: s.toggleDark),
                _TrioBtn(icon: '🔊', label: 'Sound', state: s.sound ? 'ON' : 'OFF', active: s.sound, onTap: s.toggleSound),
                _TrioBtn(icon: '📳', label: 'Vibration', state: s.vibration ? 'ON' : 'OFF', active: s.vibration, onTap: s.toggleVibration),
              ],
            ),
            const SizedBox(height: 16),
            _section('Accessibility', s),
            _CheckTile(label: 'Dyslexia-friendly font', value: s.dyslexia, onChanged: (_) => s.toggleDyslexia()),
            _CheckTile(label: 'Color-blind safe palette', value: s.colorblind, onChanged: (_) => s.toggleColorblind()),
            _CheckTile(label: 'Performance mode (faster on all devices)', value: s.lowPerf, onChanged: (_) => s.toggleLowPerf()),
            _CheckTile(label: 'Reduce motion', value: s.reduceMotion, onChanged: (_) => s.toggleReduceMotion()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Text('Anim speed:'),
                  Expanded(
                    child: Slider(
                      min: 0.3, max: 2.0, divisions: 17,
                      value: s.animSpeed,
                      activeColor: const Color(GameConfig.coral),
                      onChanged: s.setAnimSpeed,
                    ),
                  ),
                  Text('${s.animSpeed.toStringAsFixed(1)}x',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _section('More', s),
            NeoButton(
              label: '❓ How to Play',
              outlined: true,
              color: GameConfig.sky,
              onPressed: () {
                gs.closeModal();
                gs.showModal(GameModal.tutorial);
              },
            ),
            const SizedBox(height: 8),
            NeoButton(
              label: '🗑️ Reset All Data',
              outlined: true,
              color: GameConfig.punch,
              onPressed: () {
                gs.resetAllData();
                gs.closeModal();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String text, SettingsService s) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text,
        style: TextStyle(
          color: s.muted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Avatar selector tile used inside SettingsModal.
/// Opens the full AvatarPickerDialog with ~50 emojis.
class _AvatarSettingsTile extends StatelessWidget {
  const _AvatarSettingsTile({required this.gs});
  final GameState gs;

  @override
  Widget build(BuildContext context) {
    final p1 = gs.p[1];
    final currentAvatar = p1.avatar is String ? p1.avatar as String : '🐶';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(GameConfig.coral).withValues(alpha: 0.3), width: 1.5),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final selected = await showDialog<String>(
            context: context,
            builder: (_) => AvatarPickerDialog(currentAvatar: currentAvatar),
          );
          if (selected != null && selected != currentAvatar) {
            gs.pickAvatar(1, selected);
            await gs.save();
          }
        },
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(GameConfig.coral).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: AvatarWidget(avatar: p1.avatar, size: 32),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Default Avatar',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontFamily: AppFonts.body,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text('Tap to change • ~50 emojis available',
                    style: TextStyle(
                      color: Colors.grey,
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
    );
  }
}

class _TrioBtn extends StatelessWidget {
  const _TrioBtn({
    required this.icon, required this.label, required this.state,
    required this.active, required this.onTap,
  });
  final String icon, label, state;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: active ? const Color(GameConfig.coral).withValues(alpha: 0.15) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? const Color(GameConfig.coral) : Colors.grey.shade300,
              width: active ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              Text(label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              Text(state,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: active ? const Color(GameConfig.coral) : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: const Color(GameConfig.coral),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Master Intro Modal
// ═══════════════════════════════════════════════════════════════
class MasterIntroModal extends StatelessWidget {
  const MasterIntroModal({super.key, required this.gs});
  final GameState gs;

  @override
  Widget build(BuildContext context) {
    return ModalShell(
      icon: '🏆🗺️',
      title: 'The Master Challenge',
      actions: [
        NeoButton(label: 'I am Ready! 🗡️', color: GameConfig.coral, onPressed: gs.startMasterMode),
        NeoButton(label: 'Cancel', outlined: true, color: GameConfig.mutedLight, onPressed: () {
          gs.closeModal();
          gs.showScreen(GameScreen.menu);
        }),
      ],
      child: const Text(
        'Welcome, brave explorer! Clear 5 Stages to find the treasure.\n'
        'Defeat the Bosses in each level.\n'
        'You have 3 Hearts ❤️❤️❤️ total. Good luck!',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, height: 1.5),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Daily Boss Modal
// ═══════════════════════════════════════════════════════════════
class DailyBossModal extends StatelessWidget {
  const DailyBossModal({super.key, required this.gs});
  final GameState gs;

  @override
  Widget build(BuildContext context) {
    final b = gs.dailyBoss;
    if (b == null) return const SizedBox.shrink();
    return ModalShell(
      icon: b.icon,
      title: b.name,
      actions: [
        if (!gs.isDailyBossClaimedToday)
          NeoButton(label: "Fight Today's Boss", color: GameConfig.coral, onPressed: gs.startDailyBoss),
        NeoButton(
          label: 'Close',
          outlined: true,
          color: GameConfig.mutedLight,
          onPressed: gs.closeModal,
        ),
      ],
      child: Column(
        children: [
          Text(b.desc, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          _InfoRow('Mission', '${b.type} • ${b.diff} • ${b.numType}'),
          _InfoRow('Rules', '${b.goal} correct • ${b.time}s each'),
          _InfoRow('Reward', gs.isDailyBossClaimedToday ? 'Claimed today' : '${b.reward} 🪙'),
          _InfoRow('Status', gs.isDailyBossClaimedToday ? 'Cleared today' : 'Ready to fight'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.k, this.v);
  final String k, v;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 80,
          child: Text(k, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        Expanded(child: Text(v)),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// Stage Cleared Modal
// ═══════════════════════════════════════════════════════════════
class StageClearedModal extends StatelessWidget {
  const StageClearedModal({super.key, required this.gs});
  final GameState gs;

  @override
  Widget build(BuildContext context) {
    return ModalShell(
      icon: '🌟',
      title: 'Stage Cleared!',
      actions: [
        NeoButton(label: 'Next Stage →', color: GameConfig.coral, onPressed: gs.advanceStage),
      ],
      child: const Text(
        'You defeated the boss! The next stage awaits...',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, height: 1.5),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Win Modal
// ═══════════════════════════════════════════════════════════════
class WinModal extends StatelessWidget {
  const WinModal({super.key, required this.gs});
  final GameState gs;

  @override
  Widget build(BuildContext context) {
    final p1 = gs.p[1];
    final p2 = gs.p[2];
    final isWin = p1.score > 0;
    return ModalShell(
      icon: isWin ? '🏆' : '😢',
      title: isWin ? 'Great Job!' : 'Game Over',
      actions: [
        NeoButton(
          label: 'Replay',
          color: GameConfig.mint,
          onPressed: gs.replayGame,
        ),
        NeoButton(
          label: 'Main Menu',
          outlined: true,
          color: GameConfig.coral,
          onPressed: gs.quitToMenu,
        ),
      ],
      child: Column(
        children: [
          _ResultRow('Player', 'Score', 'Acc', 'Time', header: true),
          _ResultRow(p1.name, '${p1.score}', '${p1.accuracy.toStringAsFixed(0)}%',
            '${(p1.avgMs / 1000).toStringAsFixed(1)}s'),
          if (gs.players == 2 && p2.score > 0)
            _ResultRow(p2.name, '${p2.score}', '${p2.accuracy.toStringAsFixed(0)}%',
              '${(p2.avgMs / 1000).toStringAsFixed(1)}s'),
          const SizedBox(height: 12),
          if (p1.maxStreak > 0)
            Text('🔥 Best streak: ${p1.maxStreak}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          if (gs.newlyUnlocked.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('🎉 Achievements Unlocked!',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            ...gs.newlyUnlocked.map((a) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(a.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(a.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow(this.name, this.score, this.acc, this.time, {this.header = false});
  final String name, score, acc, time;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: header ? FontWeight.w900 : FontWeight.w600,
      fontSize: 13,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(name, style: style)),
          Expanded(child: Text(score, style: style, textAlign: TextAlign.end)),
          Expanded(child: Text(acc, style: style, textAlign: TextAlign.end)),
          Expanded(child: Text(time, style: style, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Quit Confirm Modal
// ═══════════════════════════════════════════════════════════════
class QuitConfirmModal extends StatelessWidget {
  const QuitConfirmModal({super.key, required this.gs});
  final GameState gs;
  @override
  Widget build(BuildContext context) => ModalShell(
    icon: '❌',
    title: 'Quit Game?',
    actions: [
      NeoButton(label: 'Yes, Quit', color: GameConfig.punch, onPressed: gs.quitToMenu),
      NeoButton(label: 'Cancel', outlined: true, color: GameConfig.mutedLight, onPressed: gs.closeModal),
    ],
    child: const Text(
      'Your current progress will be lost. Are you sure?',
      textAlign: TextAlign.center,
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// High Score Modal
// ═══════════════════════════════════════════════════════════════
class HighScoreModal extends StatelessWidget {
  const HighScoreModal({super.key, required this.gs});
  final GameState gs;

  @override
  Widget build(BuildContext context) {
    return ModalShell(
      icon: '🏆',
      title: 'Hall of Fame',
      actions: [
        NeoButton(label: 'Close', color: GameConfig.coral, onPressed: gs.closeModal),
      ],
      child: gs.highScores.isEmpty
        ? const Text('No scores yet. Play a game!',
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          )
        : Column(
            children: [
              _ResultRow('Name', 'Score', 'Mode', 'Date', header: true),
              ...gs.highScores.map((s) => _ResultRow(s.name, '${s.score}', s.mode, s.date.substring(5))),
            ],
          ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Achievements Modal
// ═══════════════════════════════════════════════════════════════
class AchievementsModal extends StatelessWidget {
  const AchievementsModal({super.key, required this.gs});
  final GameState gs;

  @override
  Widget build(BuildContext context) {
    return ModalShell(
      icon: '🎯',
      title: 'Achievements',
      maxHeight: 540,
      actions: [
        NeoButton(label: 'Close', color: GameConfig.coral, onPressed: gs.closeModal),
      ],
      child: Column(
        children: GameConfig.achievementsDef.map((a) {
          final unlocked = gs.achievements[a.id] == true;
          return ListTile(
            leading: Text(a.icon,
              style: TextStyle(
                fontSize: 28,
                color: unlocked ? null : Colors.grey.shade400,
              ),
            ),
            title: Text(a.name,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: unlocked ? null : Colors.grey,
              ),
            ),
            subtitle: Text(a.desc,
              style: TextStyle(
                fontSize: 12,
                color: unlocked ? null : Colors.grey,
              ),
            ),
            trailing: unlocked
              ? const Icon(Icons.check_circle, color: Color(GameConfig.mint))
              : const Icon(Icons.lock_outline, color: Colors.grey),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Tutorial Modal
// ═══════════════════════════════════════════════════════════════
class TutorialModal extends StatelessWidget {
  const TutorialModal({super.key, required this.gs});
  final GameState gs;

  @override
  Widget build(BuildContext context) {
    return ModalShell(
      icon: '❓',
      title: 'How to Play',
      actions: [
        NeoButton(label: 'Got it!', color: GameConfig.coral, onPressed: gs.closeModal),
      ],
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Game Modes', style: TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('• Standard: Answer questions before time runs out'),
          Text('• Blitz ⚡: 60 seconds — answer as many as possible'),
          Text('• Death 💀: One wrong answer = Game Over!'),
          Text('• Master 🏆: Story mode with boss battles'),
          Text('• Survival 💪: 3 hearts, endless questions — difficulty rises every 5 correct'),
          Text('• Combo 🔥: Build streaks for bigger multipliers'),
          SizedBox(height: 12),
          Text('Number Types', style: TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('• Natural: 1, 2, 3, …'),
          Text('• Integers: includes negatives'),
          Text('• Rationals: decimal numbers'),
          SizedBox(height: 12),
          Text('Power-Ups', style: TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('Earn power-ups every 3 correct answers in single-player Standard mode.'),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Avatar Builder Modal
// ═══════════════════════════════════════════════════════════════
class AvatarBuilderModal extends StatelessWidget {
  const AvatarBuilderModal({super.key, required this.gs});
  final GameState gs;

  @override
  Widget build(BuildContext context) {
    return ModalShell(
      icon: '🎨',
      title: 'Avatar Builder',
      maxHeight: 600,
      actions: [
        NeoButton(label: 'Save', color: GameConfig.coral, onPressed: gs.saveCustomAvatar),
        NeoButton(label: 'Cancel', outlined: true, color: GameConfig.mutedLight, onPressed: gs.closeModal),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: AvatarWidget(avatar: gs.builderAvatar, size: 80)),
          const SizedBox(height: 16),
          const Text('Base', style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: GameConfig.avatarBases.length,
              itemBuilder: (_, i) {
                final e = GameConfig.avatarBases[i];
                return GestureDetector(
                  onTap: () => gs.setBuilderBase(e),
                  child: Container(
                    width: 48,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: gs.builderAvatar.base == e
                        ? const Color(GameConfig.coral).withValues(alpha: 0.15)
                        : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: gs.builderAvatar.base == e
                          ? const Color(GameConfig.coral)
                          : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Center(child: Text(e, style: const TextStyle(fontSize: 24))),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Text('Hat', style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: GameConfig.avatarHats.length,
              itemBuilder: (_, i) {
                final e = GameConfig.avatarHats[i];
                return GestureDetector(
                  onTap: () => gs.setBuilderHat(e),
                  child: Container(
                    width: 48,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: gs.builderAvatar.hat == e
                        ? const Color(GameConfig.coral).withValues(alpha: 0.15)
                        : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: gs.builderAvatar.hat == e
                          ? const Color(GameConfig.coral)
                          : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Center(child: Text(e.isEmpty ? '∅' : e, style: const TextStyle(fontSize: 24))),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Text('Accessory', style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: GameConfig.avatarAccessories.length,
              itemBuilder: (_, i) {
                final e = GameConfig.avatarAccessories[i];
                return GestureDetector(
                  onTap: () => gs.setBuilderAccessory(e),
                  child: Container(
                    width: 48,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: gs.builderAvatar.accessory == e
                        ? const Color(GameConfig.coral).withValues(alpha: 0.15)
                        : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: gs.builderAvatar.accessory == e
                          ? const Color(GameConfig.coral)
                          : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Center(child: Text(e.isEmpty ? '∅' : e, style: const TextStyle(fontSize: 22))),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Text('Color', style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: GameConfig.avatarColors.length,
              itemBuilder: (_, i) {
                final c = GameConfig.avatarColors[i];
                final selected = gs.builderAvatar.color == c;
                return GestureDetector(
                  onTap: () => gs.setBuilderColor(c),
                  child: Container(
                    width: 48,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: c == null ? Colors.white : _color(c),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? const Color(GameConfig.coral) : Colors.grey.shade300,
                        width: selected ? 3 : 1,
                      ),
                    ),
                    child: c == null
                      ? const Center(child: Text('∅', style: TextStyle(fontSize: 18)))
                      : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _color(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

// ═══════════════════════════════════════════════════════════════
// Skill Dashboard Modal
// ═══════════════════════════════════════════════════════════════
class SkillDashboardModal extends StatelessWidget {
  const SkillDashboardModal({super.key, required this.gs});
  final GameState gs;

  @override
  Widget build(BuildContext context) {
    return ModalShell(
      icon: '📊',
      title: 'Skill Dashboard',
      maxHeight: 540,
      actions: [
        NeoButton(label: 'Close', color: GameConfig.coral, onPressed: gs.closeModal),
      ],
      child: Column(
        children: [
          Operation.addition,
          Operation.subtraction,
          Operation.multiplication,
          Operation.division,
        ].map((op) {
          final sd = gs.skillMap[op.name] ?? SkillData();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(op.symbol,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 8),
                    Text(op.label,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Text('${sd.confidence.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(GameConfig.coral),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: sd.mastery / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  color: const Color(GameConfig.coral),
                ),
                Text('Mastery ${sd.mastery.toStringAsFixed(0)}% • ${sd.correct}/${sd.count} correct',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Coin Shop Modal
// ═══════════════════════════════════════════════════════════════
class CoinShopModal extends StatelessWidget {
  const CoinShopModal({super.key, required this.gs});
  final GameState gs;

  @override
  Widget build(BuildContext context) {
    return ModalShell(
      icon: '🛒',
      title: 'Coin Shop',
      maxHeight: 580,
      actions: [
        NeoButton(label: 'Close', color: GameConfig.coral, onPressed: gs.closeModal),
      ],
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Row(
              children: [
                const Text('🪙 Balance: ', style: TextStyle(fontWeight: FontWeight.w800)),
                Text('${gs.coins}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(GameConfig.coin),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const TabBar(
              tabs: [
                Tab(text: 'Avatars'),
                Tab(text: 'Hats'),
                Tab(text: 'Packs'),
              ],
              labelColor: Color(GameConfig.coral),
            ),
            SizedBox(
              height: 320,
              child: TabBarView(
                children: [
                  _ShopGrid(items: GameConfig.shopItems['avatars']!, gs: gs),
                  _ShopGrid(items: GameConfig.shopItems['hats']!, gs: gs),
                  _ShopGrid(items: GameConfig.shopItems['packs']!, gs: gs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopGrid extends StatelessWidget {
  const _ShopGrid({required this.items, required this.gs});
  final List<ShopItem> items;
  final GameState gs;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.95,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final owned = gs.shopOwned.contains(item.id);
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(GameConfig.coral).withValues(alpha: 0.3), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 4),
              Text(item.name.replaceAll('\n', ' '),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                maxLines: 2,
              ),
              const Spacer(),
              if (owned && !item.consumable)
                const Text('✓ Owned',
                  style: TextStyle(
                    color: Color(GameConfig.mint),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                )
              else
                NeoButton(
                  label: item.special == 'watch' ? 'Watch Ad' : '${item.price} 🪙',
                  color: GameConfig.coral,
                  fontSize: 11,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  onPressed: () => gs.buyShopItem(item),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Daily Challenges Modal
// ═══════════════════════════════════════════════════════════════
class DailyChallengesModal extends StatelessWidget {
  const DailyChallengesModal({super.key, required this.gs});
  final GameState gs;

  @override
  Widget build(BuildContext context) {
    return ModalShell(
      icon: '📅',
      title: 'Daily Challenges',
      maxHeight: 540,
      actions: [
        NeoButton(label: 'Close', color: GameConfig.coral, onPressed: gs.closeModal),
      ],
      child: Column(
        children: GameConfig.dailyChallenges.map((c) {
          final cur = gs.dailyProgress[c.id] ?? 0;
          final done = cur >= c.target;
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: done ? const Color(GameConfig.mint).withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: done ? const Color(GameConfig.mint) : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      Text(c.desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: (cur / c.target).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        color: done ? const Color(GameConfig.mint) : const Color(GameConfig.coral),
                      ),
                      Text('$cur / ${c.target}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    Text('+${c.reward}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(GameConfig.coin),
                      ),
                    ),
                    const Text('🪙', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
