import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_state.dart';
import '../features/modals/presentation/widgets/avatar_builder_tab_label.dart';
import '../features/modals/presentation/widgets/skill_dashboard_header.dart';
import '../features/operation_quest/domain/operation_quest.dart';
import '../features/gameplay/domain/question_mechanic.dart';
import '../features/modals/presentation/widgets/skill_dashboard_cards.dart';
import '../features/weak_skills/domain/weak_skills_policy.dart';
import '../game_config.dart';
import '../models/enums.dart';
import '../models/game_data.dart';
import '../models/player.dart';
import '../services/iap.dart';
import '../services/link_launcher.dart';
import '../services/settings.dart';
import '../widgets/common.dart';

/// Container for all modal dialogs. Routed by [GameState.currentModal].
class ModalRouter extends StatelessWidget {
  const ModalRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final s = context.watch<SettingsService>();
    if (gs.currentModal == GameModal.none) return const SizedBox.shrink();
    return Stack(
      children: [
        ModalBarrier(
          color: s.dark
              ? Colors.black.withValues(alpha: 0.65)
              : const Color(0xFF1E140A).withValues(alpha: 0.45),
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
      case GameModal.settings:
        return SettingsModal(gs: gs);
      case GameModal.masterIntro:
        return MasterIntroModal(gs: gs);
      case GameModal.dailyBoss:
        return DailyBossModal(gs: gs);
      case GameModal.stageCleared:
        return StageClearedModal(gs: gs);
      case GameModal.win:
        return WinModal(gs: gs);
      case GameModal.quitConfirm:
        return QuitConfirmModal(gs: gs);
      case GameModal.highScore:
        return HighScoreModal(gs: gs);
      case GameModal.achievements:
        return AchievementsModal(gs: gs);
      case GameModal.tutorial:
        return TutorialModal(gs: gs);
      case GameModal.avatarBuilder:
        return AvatarBuilderModal(gs: gs);
      case GameModal.skillDashboard:
        return SkillDashboardModal(gs: gs);
      case GameModal.coinShop:
        return CoinShopModal(key: const ValueKey('coinShopModal'), gs: gs);
      case GameModal.adultGate:
        return AdultGateModal(gs: gs);
      case GameModal.dailyChallenges:
        return DailyChallengesModal(gs: gs);
      case GameModal.operationQuest:
        return OperationQuestModal(gs: gs);
      case GameModal.weakSkillsPractice:
        return WeakSkillsPracticeModal(gs: gs);
      case GameModal.none:
        return const SizedBox.shrink();
    }
  }
}

class WeakSkillsPracticeModal extends StatelessWidget {
  const WeakSkillsPracticeModal({super.key, required this.gs});

  final GameState gs;

  @override
  Widget build(BuildContext context) {
    final plan = gs.setupWeakSkillsPlan;
    if (plan == null) return const SizedBox.shrink();
    final s = context.watch<SettingsService>();
    return ModalShell(
      icon: '🧠+',
      title: plan.isFallback
          ? 'Building Your Practice Profile'
          : 'Recommended Practice',
      actions: [
        NeoButton(
          label: 'Cancel',
          outlined: true,
          color: GameConfig.coral,
          onPressed: gs.cancelWeakSkillsSetup,
        ),
        NeoButton(
          label: 'Continue',
          color: GameConfig.coral,
          onPressed: gs.continueWeakSkillsSetup,
        ),
      ],
      child: plan.isFallback
          ? Text(
              'This round will include all four operations.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: s.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Practice areas',
                  style: TextStyle(
                    color: s.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                for (final operation in plan.focusedOperations)
                  Text(
                    operation == Operation.multiplication
                        ? 'Multiplication'
                        : operation.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: s.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: AppFonts.headFor(s),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Based on your practice history.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: s.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}

class OperationQuestModal extends StatelessWidget {
  const OperationQuestModal({super.key, required this.gs});

  final GameState gs;

  @override
  Widget build(BuildContext context) {
    return ModalShell(
      icon: '🗺️',
      title: 'Operation Quest',
      maxHeight: 620,
      actions: [
        NeoButton(
          label: 'Close',
          outlined: true,
          color: GameConfig.coral,
          onPressed: gs.closeModal,
        ),
      ],
      child: Column(
        children: [
          _OperationQuestTrail(
            heading: '➕ Addition Trail',
            stages: operationQuestStagesFor(Operation.addition),
            gs: gs,
          ),
          const SizedBox(height: 18),
          _OperationQuestTrail(
            heading: '➖ Subtraction Trail',
            stages: operationQuestStagesFor(Operation.subtraction),
            gs: gs,
          ),
          const SizedBox(height: 18),
          _OperationQuestTrail(
            heading: '✖️ Multiplication Trail',
            stages: operationQuestStagesFor(Operation.multiplication),
            gs: gs,
          ),
          const SizedBox(height: 18),
          _OperationQuestTrail(
            heading: '➗ Division Trail',
            stages: operationQuestStagesFor(Operation.division),
            gs: gs,
          ),
          const SizedBox(height: 18),
          _OperationQuestTrail(
            heading: '🧮 Mixed Operations Trail',
            stages: operationQuestStages
                .where((stage) =>
                    stage.operation == Operation.mixed &&
                    stage.questionMechanic == QuestionMechanic.standard)
                .toList(),
            gs: gs,
          ),
          const SizedBox(height: 18),
          _OperationQuestTrail(
            heading: '❔ Missing Operation Trail',
            stages: operationQuestStages
                .where((stage) =>
                    stage.questionMechanic == QuestionMechanic.missingOperation)
                .toList(),
            gs: gs,
          ),
          const SizedBox(height: 18),
          _OperationQuestTrail(
            heading: '🔢 Missing Number Trail',
            stages: operationQuestStages
                .where((stage) =>
                    stage.questionMechanic == QuestionMechanic.missingNumber)
                .toList(),
            gs: gs,
          ),
        ],
      ),
    );
  }
}

class _OperationQuestTrail extends StatelessWidget {
  const _OperationQuestTrail({
    required this.heading,
    required this.stages,
    required this.gs,
  });

  final String heading;
  final List<OperationQuestStage> stages;
  final GameState gs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          heading,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < stages.length; i++) ...[
          _OperationQuestStageCard(
            number: i + 1,
            stage: stages[i],
            stars: gs.operationQuestProgress.bestStars(stages[i].id),
            unlocked: gs.operationQuestProgress.isUnlocked(stages[i].id),
            onTap: () => gs.startOperationQuestStage(stages[i].id),
          ),
          if (i < stages.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _OperationQuestStageCard extends StatelessWidget {
  const _OperationQuestStageCard({
    required this.number,
    required this.stage,
    required this.stars,
    required this.unlocked,
    required this.onTap,
  });

  final int number;
  final OperationQuestStage stage;
  final int stars;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return Material(
      key: Key('operation-quest-stage-${stage.id.storageId}'),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: unlocked ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: s.surface2,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: unlocked ? const Color(GameConfig.mango) : s.border,
            ),
          ),
          child: Row(
            children: [
              Text(
                unlocked ? '$number' : '🔒',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${stage.difficulty.label} • ${stage.operation.label}',
                      style: TextStyle(color: s.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                List.generate(3, (i) => i < stars ? '★' : '☆').join(),
                style: TextStyle(
                  color: unlocked ? const Color(GameConfig.mango) : s.muted,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    this.iconWidget,
    this.header,
    this.scrollChild = true,
    this.subtitle,
  });

  final String icon;
  final String title;
  final Widget child;
  final List<Widget> actions;
  final double? maxHeight;
  final Widget? iconWidget;
  final Widget? header;
  final bool scrollChild;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    final radius = BorderRadius.circular(30);
    final modal = Container(
      decoration: BoxDecoration(
        color: s.dark ? const Color(0xF01B1815) : const Color(0xF7FFFFFF),
        borderRadius: radius,
        border: Border.all(
          color: s.dark
              ? Colors.white.withValues(alpha: 0.11)
              : Colors.white.withValues(alpha: 0.96),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: s.dark ? 0.28 : 0.16),
            blurRadius: 56,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight ?? 600),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(GameConfig.coral),
                      Color(GameConfig.mango),
                      Color(GameConfig.sky),
                      Color(GameConfig.mint),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (header != null)
                    header!
                  else
                    _ModalDefaultHeader(
                      icon: icon,
                      title: title,
                      subtitle: subtitle,
                      iconWidget: iconWidget,
                      settings: s,
                    ),
                  const SizedBox(height: 14),
                  Flexible(
                    fit: scrollChild ? FlexFit.loose : FlexFit.tight,
                    child: scrollChild
                        ? SingleChildScrollView(child: child)
                        : child,
                  ),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: s.border.withValues(alpha: 0.62),
                          ),
                        ),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: actions,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: s.lowPerf ? 0 : 24,
          sigmaY: s.lowPerf ? 0 : 24,
        ),
        child: modal,
      ),
    );
  }
}

class _ModalDefaultHeader extends StatelessWidget {
  const _ModalDefaultHeader({
    required this.icon,
    required this.title,
    required this.settings,
    this.subtitle,
    this.iconWidget,
  });

  final String icon;
  final String title;
  final String? subtitle;
  final Widget? iconWidget;
  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    const accent = Color(GameConfig.coral);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: settings.surface2.withValues(
          alpha: settings.dark ? 0.76 : 0.62,
        ),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: accent.withValues(alpha: settings.dark ? 0.20 : 0.16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: settings.dark ? 0.16 : 0.11),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: accent.withValues(alpha: 0.20),
              ),
            ),
            child: iconWidget == null
                ? Text(
                    icon,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 27,
                      height: 1,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(2),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: iconWidget!,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        color: settings.text,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        fontFamily: AppFonts.headFor(settings),
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: settings.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
            SizedBox(
              height: 136,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TrioBtn(
                      icon: '🌓',
                      label: 'Dark Mode',
                      state: s.dark ? 'ON' : 'OFF',
                      active: s.dark,
                      onTap: s.toggleDark),
                  _TrioBtn(
                      icon: '🔊',
                      label: 'Sound',
                      state: s.sound ? 'ON' : 'OFF',
                      active: s.sound,
                      onTap: s.toggleSound),
                  _TrioBtn(
                      icon: '📳',
                      label: 'Vibration',
                      state: s.vibration ? 'ON' : 'OFF',
                      active: s.vibration,
                      onTap: s.toggleVibration),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _section('Accessibility', s),
            _AccessibilityPanel(s: s),
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
            const SizedBox(height: 8),
            NeoButton(
              label: 'Restore Purchases',
              outlined: true,
              color: GameConfig.sky,
              onPressed: () {
                gs.restorePurchases();
              },
            ),
            const SizedBox(height: 16),
            _section('Support / About', s),
            _SupportLinkTile(
              icon: '✉️',
              label: 'Email',
              value: 'support@mathchallenge.me',
              onTap: () => _openSupportLink(
                gs,
                'mailto:support@mathchallenge.me',
              ),
            ),
            const SizedBox(height: 8),
            _SupportLinkTile(
              icon: '🌐',
              label: 'Website',
              value: 'mathchallenge.me',
              onTap: () => _openSupportLink(
                gs,
                'https://mathchallenge.me',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSupportLink(GameState gs, String url) async {
    if (await LinkLauncher.open(url)) return;
    gs.showToast('Could not open link.');
  }

  Widget _section(String text, SettingsService s) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
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

class _SupportLinkTile extends StatelessWidget {
  const _SupportLinkTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return Material(
      color: s.surface2.withValues(alpha: s.dark ? 0.84 : 0.56),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: s.text,
                        fontWeight: FontWeight.w900,
                        fontFamily: AppFonts.body,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: s.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppFonts.body,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, size: 18, color: s.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessibilityPanel extends StatelessWidget {
  const _AccessibilityPanel({required this.s});

  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: s.surface2.withValues(alpha: s.dark ? 0.84 : 0.56),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.74)),
      ),
      child: Column(
        children: [
          _CheckTile(
              label: 'Dyslexia-friendly font',
              value: s.dyslexia,
              onChanged: (_) => s.toggleDyslexia()),
          _CheckTile(
              label: 'Color-blind safe palette',
              value: s.colorblind,
              onChanged: (_) => s.toggleColorblind()),
          _CheckTile(
              label: 'Performance mode',
              detail: 'faster on all devices',
              value: s.lowPerf,
              onChanged: (_) => s.toggleLowPerf()),
          _CheckTile(
              label: 'Reduce motion',
              value: s.manualReduceMotion,
              onChanged: (_) => s.toggleReduceMotion()),
          Row(
            children: [
              const Text(
                'Anim speed:',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              Expanded(
                child: Slider(
                  min: 0.3,
                  max: 2.0,
                  divisions: 17,
                  value: s.animSpeed,
                  activeColor: s.accent(GameConfig.coral),
                  onChanged: s.setAnimSpeed,
                ),
              ),
              Text(
                '${s.animSpeed.toStringAsFixed(1)}x',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
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
    final s = context.watch<SettingsService>();
    final p1 = gs.p[1];
    final currentAvatar = p1.avatar.storageEmoji;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: s.surface2.withValues(alpha: s.dark ? 0.9 : 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(GameConfig.coral).withValues(alpha: 0.3),
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final selected = await showDialog<String>(
            context: context,
            builder: (_) => AvatarPickerDialog(
              currentAvatar: currentAvatar,
              availableAvatars: gs.availableAvatarBases,
            ),
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
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(GameConfig.coral).withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: AvatarWidget(avatar: p1.avatar, size: 32),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default Avatar',
                    style: TextStyle(
                      color: s.text,
                      fontWeight: FontWeight.w800,
                      fontFamily: AppFonts.body,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to change',
                    style: TextStyle(
                      color: s.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: s.muted),
          ],
        ),
      ),
    );
  }
}

class _TrioBtn extends StatelessWidget {
  const _TrioBtn({
    required this.icon,
    required this.label,
    required this.state,
    required this.active,
    required this.onTap,
  });
  final String icon, label, state;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return Expanded(
      child: Semantics(
        button: true,
        toggled: active,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? const Color(GameConfig.coral).withValues(alpha: 0.15)
                  : s.surface2.withValues(alpha: s.dark ? 0.9 : 0.7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: active
                    ? const Color(GameConfig.coral)
                    : Colors.white.withValues(alpha: 0.7),
                width: active ? 2 : 1,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: const Color(GameConfig.coral)
                            .withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 38,
                  child: Center(
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white.withValues(alpha: 0.42)
                            : s.surface.withValues(alpha: s.dark ? 0.7 : 0.6),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.62),
                        ),
                      ),
                      child: Text(icon, style: const TextStyle(fontSize: 23)),
                    ),
                  ),
                ),
                SizedBox(
                  height: 28,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: s.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          fontFamily: AppFonts.head,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        softWrap: false,
                      ),
                    ),
                  ),
                ),
                Container(
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 26),
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(GameConfig.coral)
                        : s.surface.withValues(alpha: s.dark ? 0.95 : 0.85),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    state,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: active ? Colors.white : s.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile(
      {required this.label,
      required this.value,
      required this.onChanged,
      this.detail});
  final String label;
  final String? detail;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Checkbox(
            value: value,
            activeColor: const Color(GameConfig.coral),
            visualDensity: VisualDensity.compact,
            onChanged: (v) => onChanged(v ?? false),
          ),
          Expanded(
            child: detail == null
                ? Text(
                    label,
                    style: TextStyle(
                      color: s.text,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppFonts.body,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: s.text,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppFonts.body,
                        ),
                      ),
                      Text(
                        detail!,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: s.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFonts.body,
                        ),
                      ),
                    ],
                  ),
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
        NeoButton(
            label: 'I am Ready! 🗡️',
            color: GameConfig.coral,
            onPressed: gs.startMasterMode),
        NeoButton(
            label: 'Cancel',
            outlined: true,
            color: GameConfig.mutedLight,
            onPressed: () {
              gs.closeModal();
              gs.showScreen(GameScreen.menu);
            }),
      ],
      child: const _MasterIntroCopy(),
    );
  }
}

class _MasterIntroCopy extends StatelessWidget {
  const _MasterIntroCopy();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    final stages = GameConfig.masterLevels;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(GameConfig.mango).withValues(alpha: 0.16),
                const Color(GameConfig.mint).withValues(alpha: 0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(GameConfig.mango).withValues(alpha: 0.28),
            ),
          ),
          child: Column(
            children: [
              Text(
                'Adventure Briefing',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: s.text,
                  fontFamily: AppFonts.head,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cross the map, defeat every boss, and unlock the treasure vault.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: s.text2,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _AdventureRule(icon: '🗺️', title: 'Journey', text: '5 stages'),
        const _AdventureRule(
            icon: '⚔️', title: 'Quest', text: 'Beat each boss'),
        const _AdventureRule(icon: '♥', title: 'Lives', text: '3 hearts'),
        const SizedBox(height: 6),
        Text(
          'Answer enough questions before your hearts run out.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: s.text2,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < stages.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  _StageChip(index: i + 1, boss: stages[i].boss),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AdventureRule extends StatelessWidget {
  const _AdventureRule({
    required this.icon,
    required this.title,
    required this.text,
  });

  final String icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    final isHeart = icon == '♥';
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: s.surface2.withValues(alpha: s.dark ? 0.88 : 0.76),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              icon,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isHeart ? const Color(GameConfig.coral) : null,
                fontSize: isHeart ? 22 : 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$title:',
            style: TextStyle(
              color: s.text,
              fontWeight: FontWeight.w900,
              fontFamily: AppFonts.head,
            ),
          ),
          const Spacer(),
          Text(
            text,
            style: TextStyle(
              color: isHeart ? const Color(GameConfig.coral) : s.text,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({required this.index, required this.boss});

  final int index;
  final String boss;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: s.dark ? 0.12 : 0.72),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: const Color(GameConfig.coral).withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        '$index $boss',
        style: TextStyle(
          color: s.text,
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
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
        NeoButton(
            label: "Fight Today's Boss",
            color: GameConfig.coral,
            onPressed: gs.startDailyBoss),
        NeoButton(
          label: 'Cancel',
          outlined: true,
          color: GameConfig.mutedLight,
          onPressed: gs.closeModal,
        ),
      ],
      child: Column(
        children: [
          Text(
            b.desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Defeat the boss by answering enough questions correctly. Wrong answers or timeouts cost hearts. Reach the goal before your hearts run out to win.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          _ReportBox(
            rows: [
              _ReportRow(
                'Mission',
                '',
                values: [
                  _bossTypeLabel(b.type),
                  _titleCase(b.diff),
                  _numTypeLabel(b.numType),
                ],
              ),
              _ReportRow(
                'Rules',
                '',
                values: [
                  '${b.goal} correct answers',
                  '3 hearts',
                  '${b.time}s each',
                ],
              ),
              _ReportRow(
                'Reward',
                gs.isDailyBossClaimedToday
                    ? 'Reward claimed today'
                    : '🪙 ${b.reward}',
              ),
              _ReportRow(
                'Status',
                gs.isDailyBossClaimedToday
                    ? 'Cleared today. Replay for practice.'
                    : 'Ready to fight',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportRow {
  const _ReportRow(this.label, this.value, {this.values, this.color});
  final String label;
  final String value;
  final List<String>? values;
  final Color? color;
}

class _ReportBox extends StatelessWidget {
  const _ReportBox({required this.rows});
  final List<_ReportRow> rows;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: s.surface2.withValues(alpha: s.dark ? 0.9 : 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: s.border, width: 1.5),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _ReportBoxRow(row: rows[i]),
            if (i != rows.length - 1)
              Divider(height: 1, color: s.border.withValues(alpha: 0.72)),
          ],
        ],
      ),
    );
  }
}

class _ReportBoxRow extends StatelessWidget {
  const _ReportBoxRow({required this.row});
  final _ReportRow row;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                row.label,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: s.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppFonts.body,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: row.values == null
                ? Text(
                    row.value,
                    textAlign: TextAlign.right,
                    softWrap: true,
                    style: _reportValueStyle(s, row),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final value in row.values!)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            value,
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.right,
                            style: _reportValueStyle(s, row),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  TextStyle _reportValueStyle(SettingsService s, _ReportRow row) {
    return TextStyle(
      color: row.color ?? s.text,
      fontSize: 13,
      fontWeight: FontWeight.w800,
      height: 1.25,
      fontFamily: AppFonts.body,
    );
  }
}

String _bossTypeLabel(String value) =>
    value == 'mixed' ? 'Mixed Operations' : _titleCase(value);

String _numTypeLabel(String value) {
  return switch (value) {
    'natural' => 'Natural',
    'integers' => 'Integers',
    'rationals' => 'Rationals',
    'mixed' => 'Mixed',
    _ => _titleCase(value),
  };
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value
      .split(RegExp(r'[\s_-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}

// ═══════════════════════════════════════════════════════════════
// Stage Cleared Modal
// ═══════════════════════════════════════════════════════════════
class StageClearedModal extends StatelessWidget {
  const StageClearedModal({super.key, required this.gs});
  final GameState gs;

  @override
  Widget build(BuildContext context) {
    final cleared = gs.clearedMasterLevel;
    final next = gs.nextMasterLevel;
    return ModalShell(
      icon: '🌟',
      title: cleared == null ? 'Stage Cleared!' : '${cleared.name} Cleared! 🌟',
      actions: [
        NeoButton(
            label: next == null ? 'Continue' : 'Enter ${next.name}',
            color: GameConfig.coral,
            onPressed: gs.advanceStage),
      ],
      child: Text(
        cleared?.story ?? 'You defeated the boss! The next stage awaits...',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, height: 1.5),
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
    final canReplay =
        !(gs.rt.challenge == Operation.dailyBoss && gs.rt.dailyBossWon);
    return ModalShell(
      icon: gs.resultIcon,
      title: gs.resultTitle,
      actions: [
        if (canReplay)
          NeoButton(
            label: 'Replay',
            color: GameConfig.mint,
            onPressed: gs.replayGame,
          ),
        NeoButton(
          label: gs.isOperationQuest ? 'Quest Map' : 'Main Menu',
          outlined: true,
          color: GameConfig.coral,
          onPressed: gs.isOperationQuest
              ? gs.returnToOperationQuestMap
              : gs.quitToMenu,
        ),
      ],
      child: Column(
        children: [
          if (gs.resultDescription.isNotEmpty) ...[
            Text(
              gs.resultDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, height: 1.4),
            ),
            const SizedBox(height: 12),
          ],
          if (gs.activePlayers == 2 && gs.activeMode == GameMode.standard)
            _CompareResultReport(p1: p1, p2: p2)
          else
            _SingleResultReport(player: p1),
          const SizedBox(height: 12),
          if (p1.maxStreak > 0)
            Text(
              '🔥 Best streak: ${p1.maxStreak}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          if (gs.newlyUnlocked.isNotEmpty) ...[
            const SizedBox(height: 12),
            const SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '🎉 Achievements Unlocked!',
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(GameConfig.coin).withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(GameConfig.coin).withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                children: gs.newlyUnlocked
                    .map(
                      (a) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${a.icon} ${a.name}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SingleResultReport extends StatelessWidget {
  const _SingleResultReport({required this.player});

  final PlayerState player;

  @override
  Widget build(BuildContext context) {
    final wrong = player.total - player.correct - player.skipped;
    return Column(
      children: [
        Text(
          "${player.name}'s Report",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontFamily: AppFonts.head,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        _ReportBox(
          rows: [
            _ReportRow('Final Score', '${player.score}'),
            _ReportRow('Accuracy', '${player.accuracy.round()}%'),
            _ReportRow('✓ Correct', '${player.correct}',
                color: const Color(GameConfig.mint)),
            _ReportRow('✗ Wrong', '$wrong',
                color: const Color(GameConfig.punch)),
            _ReportRow('Skipped', '${player.skipped}'),
            _ReportRow('Time Bonus', '${player.bonus}pts',
                color: const Color(GameConfig.grape)),
            _ReportRow('Best Streak', '${player.maxStreak}'),
            _ReportRow(
                'Avg Time', '${(player.avgMs / 1000).toStringAsFixed(1)}s'),
          ],
        ),
      ],
    );
  }
}

class _CompareResultReport extends StatelessWidget {
  const _CompareResultReport({required this.p1, required this.p2});

  final PlayerState p1;
  final PlayerState p2;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CompareResultRow('Stat', p1.name, p2.name, header: true),
        _CompareResultRow('Score', '${p1.score}', '${p2.score}'),
        _CompareResultRow(
            'Accuracy', '${p1.accuracy.round()}%', '${p2.accuracy.round()}%'),
        _CompareResultRow('✓ Correct', '${p1.correct}', '${p2.correct}',
            color: const Color(GameConfig.mint)),
        _CompareResultRow('✗ Wrong', '${_wrongCount(p1)}', '${_wrongCount(p2)}',
            color: const Color(GameConfig.punch)),
        _CompareResultRow('Skipped', '${p1.skipped}', '${p2.skipped}'),
        _CompareResultRow(
            'Avg Time',
            '${(p1.avgMs / 1000).toStringAsFixed(1)}s',
            '${(p2.avgMs / 1000).toStringAsFixed(1)}s'),
      ],
    );
  }

  int _wrongCount(PlayerState player) =>
      player.total - player.correct - player.skipped;
}

class _CompareResultRow extends StatelessWidget {
  const _CompareResultRow(this.label, this.first, this.second,
      {this.header = false, this.color});

  final String label;
  final String first;
  final String second;
  final bool header;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    final style = TextStyle(
      color: color ?? s.text,
      fontSize: 13,
      fontWeight: header ? FontWeight.w900 : FontWeight.w700,
      fontFamily: AppFonts.body,
      height: 1.2,
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: s.border.withValues(alpha: 0.45)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          Expanded(
            child: Text(first, textAlign: TextAlign.center, style: style),
          ),
          Expanded(
            child: Text(second, textAlign: TextAlign.right, style: style),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow(this.a, this.b, this.c, this.d, {this.header = false});

  final String a;
  final String b;
  final String c;
  final String d;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    final style = TextStyle(
      color: header ? s.muted : s.text,
      fontSize: 12,
      fontWeight: header ? FontWeight.w900 : FontWeight.w700,
      fontFamily: AppFonts.body,
      height: 1.2,
      letterSpacing: header ? 0.8 : 0,
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: s.border.withValues(alpha: 0.42)),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: _fitCell(a, style, TextAlign.left)),
          Expanded(child: _fitCell(b, style, TextAlign.center)),
          Expanded(child: _fitCell(c, style, TextAlign.center)),
          Expanded(child: _fitCell(d, style, TextAlign.right)),
        ],
      ),
    );
  }

  Widget _fitCell(String text, TextStyle style, TextAlign align) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: switch (align) {
        TextAlign.right => Alignment.centerRight,
        TextAlign.center => Alignment.center,
        _ => Alignment.centerLeft,
      },
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        textAlign: align,
        style: style,
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
          NeoButton(
              label: 'Yes, Quit',
              color: GameConfig.punch,
              onPressed: gs.quitToMenu),
          NeoButton(
              label: 'Cancel',
              outlined: true,
              color: GameConfig.mutedLight,
              onPressed: gs.closeModal),
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
        NeoButton(
            label: 'Close', color: GameConfig.coral, onPressed: gs.closeModal),
      ],
      child: gs.highScores.isEmpty
          ? const Text(
              'No scores yet. Play a game!',
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            )
          : Column(
              children: [
                _ResultRow('Name', 'Score', 'Mode', 'Date', header: true),
                ...gs.highScores.map((s) => _ResultRow(
                      s.name,
                      '${s.score}',
                      [
                        s.mode.label,
                        if (s.difficulty != null) s.difficulty!.label,
                        s.answerStyle.label,
                      ].join(' · '),
                      s.date.length >= 5 ? s.date.substring(5) : s.date,
                    )),
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
    final settings = context.watch<SettingsService>();
    return ModalShell(
      icon: '🎯',
      title: 'Achievements',
      maxHeight: 540,
      actions: [
        NeoButton(
            label: 'Close', color: GameConfig.coral, onPressed: gs.closeModal),
      ],
      child: Column(
        children: GameConfig.achievementsDef.map((a) {
          final unlocked = gs.achievements[a.id] == true;
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: unlocked
                  ? settings.surface2
                      .withValues(alpha: settings.dark ? 0.9 : 0.72)
                  : settings.surface2
                      .withValues(alpha: settings.dark ? 0.55 : 0.42),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: unlocked
                    ? const Color(GameConfig.mint).withValues(alpha: 0.42)
                    : Colors.white.withValues(alpha: 0.55),
              ),
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: const Color(GameConfig.mint)
                            .withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Opacity(
                  opacity: unlocked ? 1 : 0.32,
                  child: Text(a.icon, style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontFamily: AppFonts.head,
                          color: unlocked ? settings.text : settings.muted,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        a.desc,
                        style: TextStyle(
                          fontSize: 12,
                          color: settings.muted,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  unlocked ? Icons.check_circle : Icons.lock_outline,
                  color:
                      unlocked ? const Color(GameConfig.mint) : settings.muted,
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
        NeoButton(
            label: 'Got it!',
            color: GameConfig.coral,
            onPressed: gs.closeModal),
      ],
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How to play', style: TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text(
              'Answer math questions, earn coins, unlock rewards, and beat bosses.'),
          SizedBox(height: 12),
          Text('Boss fights', style: TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text(
              'Defeat the boss by answering enough questions correctly. Wrong answers or timeouts cost hearts. Reach the goal before your hearts run out to win.'),
          SizedBox(height: 12),
          Text('Hearts', style: TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text(
              'Hearts protect you in boss and survival challenges. Lose all hearts and the challenge ends.'),
          SizedBox(height: 12),
          Text('Coins', style: TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text(
              'Earn coins by playing, beating bosses, claiming daily rewards, and completing challenges. Use coins to unlock avatars, hats, number types, and power-ups.'),
          SizedBox(height: 12),
          Text('Power-ups', style: TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text(
              'Power-ups can help during tough questions. Use them carefully when the boss gets stronger.'),
          SizedBox(height: 12),
          Text(
              'Practice addition, subtraction, multiplication, and division through quick challenges and boss battles.'),
          SizedBox(height: 12),
          Text('Game Modes', style: TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('• Standard: Answer questions before time runs out'),
          Text('• Blitz ⚡: 60 seconds — answer as many as possible'),
          Text('• Death 💀: One wrong answer = Game Over!'),
          Text('• Master 🏆: Story mode with boss battles'),
          Text(
              '• Survival 💪: 3 hearts, endless questions — difficulty rises every 5 correct'),
          Text('• Combo 🔥: Build streaks for bigger multipliers'),
          SizedBox(height: 12),
          Text('Number Types', style: TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('• Natural: 1, 2, 3, …'),
          Text('• Integers: includes negatives'),
          Text('• Rationals: decimal numbers'),
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
    final s = context.watch<SettingsService>();
    return ModalShell(
      icon: '🎨',
      title: 'Avatar Builder',
      maxHeight: 700,
      scrollChild: false,
      actions: [
        NeoButton(
            label: 'Save Avatar',
            color: GameConfig.coral,
            onPressed: gs.saveCustomAvatar),
        NeoButton(
            label: 'Cancel',
            outlined: true,
            color: GameConfig.mutedLight,
            onPressed: gs.closeModal),
      ],
      child: DefaultTabController(
        length: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AvatarBuilderPreview(gs: gs, settings: s),
            const SizedBox(height: 12),
            Container(
              key: const Key('avatar-builder-tabs'),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: s.surface2.withValues(alpha: s.dark ? 0.85 : 0.62),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
              child: const TabBar(
                labelPadding: EdgeInsets.zero,
                tabs: [
                  Tab(child: AvatarBuilderTabLabel(icon: '🐾', label: 'Base')),
                  Tab(child: AvatarBuilderTabLabel(icon: '🎩', label: 'Hat')),
                  Tab(
                      child: AvatarBuilderTabLabel(
                          icon: '🎒', label: 'Accessory')),
                  Tab(child: AvatarBuilderTabLabel(icon: '🎨', label: 'Color')),
                ],
                labelColor: Colors.white,
                unselectedLabelColor: Color(GameConfig.mutedLight),
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(GameConfig.coral),
                      Color(0xFFD4681A),
                    ],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                key: const Key('avatar-builder-picker'),
                children: [
                  _AvatarButtonGrid(
                    key: const Key('avatar-base-grid'),
                    items: gs.availableAvatarBases,
                    selected: gs.builderAvatar.base,
                    onTap: gs.setBuilderBase,
                  ),
                  _AvatarButtonGrid(
                    key: const Key('avatar-hat-grid'),
                    items: [
                      '',
                      ...gs.availableAvatarHats.where((hat) => hat.isNotEmpty),
                    ],
                    selected: gs.builderAvatar.hat,
                    emptyLabel: '🚫',
                    onTap: gs.setBuilderHat,
                  ),
                  _AvatarButtonGrid(
                    key: const Key('avatar-accessory-grid'),
                    items: [
                      '',
                      ...GameConfig.avatarAccessories
                          .where((accessory) => accessory.isNotEmpty),
                    ],
                    selected: gs.builderAvatar.accessory,
                    emptyLabel: '🚫',
                    onTap: gs.setBuilderAccessory,
                  ),
                  _AvatarColorGrid(
                    key: const Key('avatar-color-grid'),
                    gs: gs,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarBuilderPreview extends StatelessWidget {
  const _AvatarBuilderPreview({required this.gs, required this.settings});

  final GameState gs;
  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    final avatar = gs.builderAvatar;
    final bg = avatar.color == null ? null : _avatarBuilderColor(avatar.color!);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        final slotSize = compact ? 62.0 : 70.0;

        return Container(
          key: const Key('avatar-builder-preview'),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                settings.surface2.withValues(alpha: settings.dark ? 0.88 : 0.7),
                const Color(GameConfig.sky)
                    .withValues(alpha: settings.dark ? 0.10 : 0.13),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Player ${gs.builderPid} Avatar',
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: settings.text,
                  fontFamily: AppFonts.head,
                  fontSize: compact ? 17 : 19,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _AvatarStudioSlot(
                    size: slotSize,
                    child: AvatarWidget(
                      avatar: AvatarData.custom(avatar),
                      size: slotSize - 8,
                    ),
                  ),
                  _AvatarStudioSlot(
                    size: slotSize,
                    child: Text(avatar.hat.isEmpty ? '🚫' : avatar.hat),
                  ),
                  _AvatarStudioSlot(
                    size: slotSize,
                    child: Text(
                      avatar.accessory.isEmpty ? '🚫' : avatar.accessory,
                    ),
                  ),
                  _AvatarStudioSlot(
                    size: slotSize,
                    child: bg == null
                        ? const Text('🚫')
                        : Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: bg,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AvatarStudioSlot extends StatelessWidget {
  const _AvatarStudioSlot({required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: s.dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.70)),
        ),
        child: DefaultTextStyle(
          style: TextStyle(color: s.text, fontSize: 26, height: 1),
          child: FittedBox(fit: BoxFit.scaleDown, child: child),
        ),
      ),
    );
  }
}

class _AvatarButtonGrid extends StatelessWidget {
  const _AvatarButtonGrid({
    super.key,
    required this.items,
    required this.selected,
    required this.onTap,
    this.emptyLabel = '🚫',
  });

  final List<String> items;
  final String selected;
  final ValueChanged<String> onTap;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 340 ? 5 : 4;
        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final item = items[i];
            return _AvatarChoiceButton(
              value: item,
              label: item.isEmpty ? emptyLabel : item,
              selected: selected == item,
              onTap: () => onTap(item),
            );
          },
        );
      },
    );
  }
}

class _AvatarChoiceButton extends StatelessWidget {
  const _AvatarChoiceButton({
    required this.value,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    const Color(GameConfig.coral).withValues(alpha: 0.16),
                    const Color(GameConfig.mango).withValues(alpha: 0.16),
                  ],
                )
              : null,
          color: selected
              ? null
              : s.surface2.withValues(alpha: s.dark ? 0.85 : 0.62),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(GameConfig.coral)
                : Colors.white.withValues(alpha: 0.85),
            width: selected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? const Color(GameConfig.coral).withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: selected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: value.isEmpty ? s.muted : null,
            fontSize: value.isEmpty ? 20 : 26,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _AvatarColorGrid extends StatelessWidget {
  const _AvatarColorGrid({super.key, required this.gs});

  final GameState gs;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 340 ? 6 : 5;
        final colors = [
          null,
          ...GameConfig.avatarColors.whereType<String>(),
        ];
        return GridView.builder(
          padding: const EdgeInsets.all(4),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: colors.length,
          itemBuilder: (_, i) {
            final color = colors[i];
            final selected = gs.builderAvatar.color == color;
            final parsed = color == null ? null : _avatarBuilderColor(color);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => gs.setBuilderColor(color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: parsed ??
                      s.surface2.withValues(alpha: s.dark ? 0.88 : 0.66),
                  border: Border.all(
                    color: selected
                        ? const Color(GameConfig.coral)
                        : Colors.white.withValues(alpha: 0.9),
                    width: selected ? 3 : 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: selected
                          ? const Color(GameConfig.coral)
                              .withValues(alpha: 0.28)
                          : Colors.black.withValues(alpha: 0.12),
                      blurRadius: selected ? 12 : 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: color == null
                    ? const Text('🚫', style: TextStyle(fontSize: 22))
                    : selected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
              ),
            );
          },
        );
      },
    );
  }
}

Color _avatarBuilderColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

// ═══════════════════════════════════════════════════════════════
// Skill Dashboard Modal
// ═══════════════════════════════════════════════════════════════
class SkillDashboardModal extends StatelessWidget {
  const SkillDashboardModal({super.key, required this.gs});

  final GameState gs;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();

    final overallMasteryPercent = (gs.adaptLvlRaw * 10).clamp(0.0, 100.0);

    final recommendation = selectWeakSkillsPlan(gs.skillMap);

    final skills = [
      (
        operation: Operation.addition,
        symbol: '➕',
        label: 'Addition',
        color: const Color(GameConfig.mint),
      ),
      (
        operation: Operation.subtraction,
        symbol: '➖',
        label: 'Subtraction',
        color: const Color(GameConfig.coral),
      ),
      (
        operation: Operation.multiplication,
        symbol: '✖',
        label: 'Multiplication',
        color: const Color(GameConfig.mango),
      ),
      (
        operation: Operation.division,
        symbol: '➗',
        label: 'Division',
        color: const Color(GameConfig.sky),
      ),
    ];

    return ModalShell(
      icon: '📈',
      title: 'Skills Dashboard',
      maxHeight: 680,
      header: SkillDashboardHeader(settings: s),
      actions: [
        NeoButton(
          label: 'Close',
          color: GameConfig.coral,
          onPressed: gs.closeModal,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OverallMasteryCard(
            settings: s,
            masteryPercent: overallMasteryPercent,
          ),
          const SizedBox(height: 24),
          Text(
            'YOUR SKILLS',
            style: TextStyle(
              color: s.muted,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < skills.length; i++) ...[
            SkillMasteryCard(
              settings: s,
              symbol: skills[i].symbol,
              label: skills[i].label,
              masteryPercent:
                  gs.skillMap[skills[i].operation.name]?.mastery ?? 0,
              accentColor: skills[i].color,
            ),
            if (i < skills.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 22),
          WeakSkillsRecommendationCard(
            settings: s,
            plan: recommendation,
            onTap: () => gs.goToConfig('weakSkills'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Coin Shop Modal
// ═══════════════════════════════════════════════════════════════
enum _ShopSection { hub, avatars, hats, packs, buy }

class CoinShopModal extends StatefulWidget {
  const CoinShopModal({super.key, required this.gs});
  final GameState gs;

  @override
  State<CoinShopModal> createState() => _CoinShopModalState();
}

class _CoinShopModalState extends State<CoinShopModal> {
  _ShopSection _section = _ShopSection.hub;

  void _open(_ShopSection section) => setState(() => _section = section);
  void _backToHub() => setState(() => _section = _ShopSection.hub);

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    return ModalShell(
      icon: '🛍️',
      title: 'Coin Shop',
      maxHeight: 720,
      actions: [
        NeoButton(
            label: 'Done', color: GameConfig.coral, onPressed: gs.closeModal),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_section == _ShopSection.hub)
            _ShopHubPanel(onOpen: _open)
          else
            _ShopSectionPanel(
              section: _section,
              onBack: _backToHub,
              child: switch (_section) {
                _ShopSection.avatars => _ShopCatalogPanel(
                    items: GameConfig.shopItems['avatars']!,
                    gs: gs,
                  ),
                _ShopSection.hats => _ShopCatalogPanel(
                    items: GameConfig.shopItems['hats']!,
                    gs: gs,
                  ),
                _ShopSection.packs => _ShopPacksPanel(gs: gs),
                _ShopSection.buy => _BuyCoinsPanel(gs: gs),
                _ShopSection.hub => const SizedBox.shrink(),
              },
            ),
        ],
      ),
    );
  }
}

class _ShopHubPanel extends StatelessWidget {
  const _ShopHubPanel({required this.onOpen});

  final ValueChanged<_ShopSection> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ShopHubCard(
          key: const Key('shopHub_avatars'),
          icon: '🐾',
          title: 'Avatars',
          onTap: () => onOpen(_ShopSection.avatars),
        ),
        _ShopHubCard(
          key: const Key('shopHub_hats'),
          icon: '🎩',
          title: 'Hats',
          onTap: () => onOpen(_ShopSection.hats),
        ),
        _ShopHubCard(
          key: const Key('shopHub_packs'),
          icon: '⚡',
          title: 'Packs',
          onTap: () => onOpen(_ShopSection.packs),
        ),
        _ShopHubCard(
          key: const Key('shopHub_buy'),
          icon: '💳',
          title: 'Buy',
          onTap: () => onOpen(_ShopSection.buy),
        ),
      ],
    );
  }
}

class _ShopHubCard extends StatelessWidget {
  const _ShopHubCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final String icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: _shopCardDecoration(s),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(GameConfig.coral), Color(0xFFD4681A)],
                ),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: s.text,
                      fontFamily: AppFonts.head,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: s.muted, size: 30),
          ],
        ),
      ),
    );
  }
}

class _ShopSectionPanel extends StatelessWidget {
  const _ShopSectionPanel({
    required this.section,
    required this.onBack,
    required this.child,
  });

  final _ShopSection section;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final title = switch (section) {
      _ShopSection.avatars => 'Avatars',
      _ShopSection.hats => 'Hats',
      _ShopSection.packs => 'Packs',
      _ShopSection.buy => 'Buy',
      _ShopSection.hub => 'Shop',
    };
    final s = context.watch<SettingsService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('shopBackToHub'),
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Back to Shop'),
            style: TextButton.styleFrom(
              foregroundColor: s.muted,
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(child: _ShopSectionTitle(title)),
          ],
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _ShopCatalogPanel extends StatelessWidget {
  const _ShopCatalogPanel({
    required this.items,
    required this.gs,
  });

  final List<ShopItem> items;
  final GameState gs;

  @override
  Widget build(BuildContext context) {
    return _ShopItemGrid(items: items, gs: gs);
  }
}

class _ShopPacksPanel extends StatelessWidget {
  const _ShopPacksPanel({required this.gs});

  final GameState gs;

  @override
  Widget build(BuildContext context) {
    final items = GameConfig.shopItems['packs']!;
    return Column(
      children: [
        for (final item in items) ...[
          _ShopActionRow(
            item: item,
            gs: gs,
            onTap: () => gs.buyShopItem(item),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ShopSectionTitle extends StatelessWidget {
  const _ShopSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
      child: Text(
        title.toUpperCase(),
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          color: s.muted,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          fontFamily: AppFonts.head,
        ),
      ),
    );
  }
}

class _ShopItemGrid extends StatelessWidget {
  const _ShopItemGrid({required this.items, required this.gs});
  final List<ShopItem> items;
  final GameState gs;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 430 ? 3 : 2;
        final spacing = 10.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: cardWidth,
                height: 164,
                child: _ShopItemCard(item: item, gs: gs),
              ),
          ],
        );
      },
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({required this.item, required this.gs});

  final ShopItem item;
  final GameState gs;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    final owned = gs.shopOwned.contains(item.id);
    final canAfford = gs.coins >= item.price;
    final canBuy = !(owned && !item.consumable) && canAfford;
    return GestureDetector(
      onTap: canBuy ? () => gs.buyShopItem(item) : null,
      child: Opacity(
        opacity: canBuy || owned ? 1 : 0.48,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: _shopCardDecoration(s),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 5),
              Text(
                item.name.replaceAll('\n', ' '),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: s.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontFamily: AppFonts.head,
                ),
              ),
              const SizedBox(height: 4),
              if (!(owned && !item.consumable)) ...[
                _CoinPriceBadge(price: item.price),
                const SizedBox(height: 4),
              ] else
                const SizedBox(height: 4),
              if (owned && !item.consumable)
                const _ShopPricePill(text: 'Owned', owned: true)
              else
                const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopActionRow extends StatelessWidget {
  const _ShopActionRow(
      {required this.item, required this.gs, required this.onTap});

  final ShopItem item;
  final GameState gs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    final parts = item.name.split('\n');
    final title = item.special == 'watch'
        ? '+${GameState.dailyBonusCoins} Coins'
        : parts.first;
    final owned = gs.shopOwned.contains(item.id);
    final dailyBonusClaimed =
        item.special == 'watch' && gs.isDailyCoinsClaimedToday;
    final canAfford = item.special == 'watch' || gs.coins >= item.price;
    final canBuy =
        !((owned && !item.consumable) || dailyBonusClaimed) && canAfford;
    final actionText = dailyBonusClaimed
        ? 'Claimed'
        : (owned && !item.consumable)
            ? 'Owned'
            : item.special == 'watch'
                ? 'Free Daily'
                : '🪙 ${item.price}';
    final subtitle = item.special == 'watch'
        ? 'Daily bonus'
        : item.id == 'pack_powerups'
            ? 'x5 of each power-up'
            : item.id == 'pack_lives'
                ? 'For Master mode'
                : parts.skip(1).join(' ');

    return GestureDetector(
      key: Key('shopPack_${item.id}'),
      onTap: canBuy ? onTap : null,
      child: Opacity(
        opacity: canBuy || owned || dailyBonusClaimed ? 1 : 0.48,
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: _shopCardDecoration(s),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Center(
                  child: item.id == 'pack_lives'
                      ? const Icon(Icons.favorite_rounded,
                          color: Color(GameConfig.coral), size: 32)
                      : Text(item.emoji, style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          title,
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            color: s.text,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            fontFamily: AppFonts.head,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            color: item.special == 'watch'
                                ? const Color(GameConfig.mint)
                                : s.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _ShopPricePill(
                text: actionText,
                owned: (owned && !item.consumable) || dailyBonusClaimed,
                outlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoinPriceBadge extends StatelessWidget {
  const _CoinPriceBadge({required this.price});

  final int price;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(GameConfig.coin).withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: const Color(GameConfig.coin).withValues(alpha: 0.55),
        ),
      ),
      child: Text(
        '🪙 $price',
        maxLines: 1,
        softWrap: false,
        style: const TextStyle(
          color: Color(0xFF8A6200),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          fontFamily: AppFonts.body,
        ),
      ),
    );
  }
}

class _ShopPricePill extends StatelessWidget {
  const _ShopPricePill({
    required this.text,
    required this.owned,
    this.outlined = false,
  });

  final String text;
  final bool owned;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: outlined ? 38 : 30,
        minWidth: outlined ? 78 : 74,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: outlined ? 10 : 12,
        vertical: outlined ? 8 : 7,
      ),
      decoration: BoxDecoration(
        gradient: owned || outlined
            ? null
            : const LinearGradient(
                colors: [Color(GameConfig.coral), Color(0xFFD4681A)],
              ),
        color: owned || outlined
            ? const Color(GameConfig.coin).withValues(alpha: 0.10)
            : null,
        border: outlined
            ? Border.all(
                color: const Color(GameConfig.coin).withValues(alpha: 0.50),
                width: 1.5,
              )
            : null,
        borderRadius: BorderRadius.circular(99),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            color: owned || outlined ? const Color(0xFFB78300) : Colors.white,
            fontSize: outlined ? 13 : 13,
            fontWeight: FontWeight.w900,
            fontFamily: AppFonts.head,
          ),
        ),
      ),
    );
  }
}

class _BuyCoinsPanel extends StatelessWidget {
  const _BuyCoinsPanel({required this.gs});

  final GameState gs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RewardedAdCard(
          disabled: gs.adsRemoved || gs.isRewardedAdOnCooldown,
          onTap: () {
            gs.claimRewardedAdCoins();
          },
        ),
        const SizedBox(height: 10),
        _IapCard(
          key: const Key('iapProduct_100_coins'),
          icon: '🪙',
          title: '100 Coins',
          subtitle: 'Starter pack',
          price: gs.iapPriceFor(IapProducts.small),
          onTap: () => gs.beginIapPurchase(IapProducts.small),
        ),
        _IapCard(
          key: const Key('iapProduct_500_coins'),
          icon: '💰',
          title: '500 Coins',
          subtitle: '+50 bonus coins!',
          price: gs.iapPriceFor(IapProducts.medium),
          onTap: () => gs.beginIapPurchase(IapProducts.medium),
        ),
        _IapCard(
          key: const Key('iapProduct_1200_coins'),
          icon: '🏆',
          title: '1200 Coins',
          subtitle: '+200 bonus coins!',
          price: gs.iapPriceFor(IapProducts.large),
          onTap: () => gs.beginIapPurchase(IapProducts.large),
        ),
        _IapCard(
          key: const Key('iapProduct_ads_remove'),
          icon: '🚫',
          title: 'Remove Ads',
          subtitle:
              gs.adsRemoved ? 'Already active' : 'Forever, one-time purchase',
          price:
              gs.adsRemoved ? 'Owned' : gs.iapPriceFor(IapProducts.removeAds),
          onTap: () => gs.beginIapPurchase(IapProducts.removeAds),
        ),
        const Text(
          'Payments processed securely via Google Play.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Color(GameConfig.mutedLight)),
        ),
      ],
    );
  }
}

class _RewardedAdCard extends StatelessWidget {
  const _RewardedAdCard({required this.disabled, required this.onTap});

  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.62 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF211C3D),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(GameConfig.grape).withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(GameConfig.grape).withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 54,
                child: Center(
                  child: Text('🎬', style: TextStyle(fontSize: 42)),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Watch Ad',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontFamily: AppFonts.head,
                          fontSize: 20,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                constraints: const BoxConstraints(minWidth: 88, minHeight: 58),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      disabled ? '✓' : '+${GameState.rewardedAdCoins} 🪙',
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        color: Color(GameConfig.coin),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      disabled ? 'WAIT' : 'WATCH',
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        color: Color(0xFFD7D1EA),
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IapCard extends StatelessWidget {
  const _IapCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final String price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: _shopCardDecoration(s),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          color: s.text,
                          fontWeight: FontWeight.w900,
                          fontFamily: AppFonts.head,
                          fontSize: 17,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(
                          color: Color(GameConfig.mint),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              constraints: const BoxConstraints(minWidth: 68, minHeight: 34),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(GameConfig.mango),
                    Color(0xFFFF6B2A),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color:
                        const Color(GameConfig.mango).withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  price,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    color: Color(GameConfig.textLight),
                    fontWeight: FontWeight.w900,
                    fontFamily: AppFonts.head,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _shopCardDecoration(SettingsService s) {
  return BoxDecoration(
    color: s.surface2.withValues(alpha: s.dark ? 0.90 : 0.76),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: s.dark
          ? Colors.white.withValues(alpha: 0.10)
          : Colors.white.withValues(alpha: 0.84),
      width: 1.4,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.07),
        blurRadius: 16,
        offset: const Offset(0, 5),
      ),
    ],
  );
}

class AdultGateModal extends StatefulWidget {
  const AdultGateModal({super.key, required this.gs});

  final GameState gs;

  @override
  State<AdultGateModal> createState() => _AdultGateModalState();
}

class _AdultGateModalState extends State<AdultGateModal> {
  final TextEditingController _answerController = TextEditingController();
  bool _showQuestion = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    final challenge = gs.adultGateChallenge;
    final product = gs.pendingIapProduct;
    final price = product == null ? '' : gs.iapPriceFor(product);

    return ModalShell(
      icon: '🔐',
      title: 'Adult Gate',
      maxHeight: 500,
      actions: [
        NeoButton(
          label: gs.adultGateBusy ? 'Opening...' : 'Continue',
          color: GameConfig.coral,
          onPressed: gs.adultGateBusy
              ? () {}
              : () {
                  if (!_showQuestion) {
                    setState(() => _showQuestion = true);
                    return;
                  }
                  gs.submitAdultGateAnswer(_answerController.text);
                },
        ),
        NeoButton(
          label: 'Cancel',
          outlined: true,
          color: GameConfig.textLight,
          textColor: const Color(GameConfig.textLight),
          onPressed: gs.cancelAdultGate,
        ),
      ],
      child: _showQuestion
          ? _AdultGateQuestionStep(
              gs: gs,
              challenge: challenge,
              answerController: _answerController,
            )
          : _AdultGateWarningStep(product: product, price: price),
    );
  }
}

class _AdultGateWarningStep extends StatelessWidget {
  const _AdultGateWarningStep({required this.product, required this.price});

  final IapProduct? product;
  final String price;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: s.surface2.withValues(alpha: s.dark ? 0.9 : 0.78),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          ),
          child: Column(
            children: [
              Text(
                product?.label ?? 'Google Play purchase',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: s.text,
                  fontWeight: FontWeight.w900,
                  fontFamily: AppFonts.head,
                  fontSize: 20,
                ),
              ),
              if (price.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  price,
                  style: const TextStyle(
                    color: Color(GameConfig.mango),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Grown-up check',
          style: TextStyle(
            color: s.text,
            fontWeight: FontWeight.w900,
            fontFamily: AppFonts.head,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'A grown-up should continue\nbefore opening Google Play.',
            maxLines: 2,
            softWrap: false,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: s.text.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _AdultGateQuestionStep extends StatelessWidget {
  const _AdultGateQuestionStep({
    required this.gs,
    required this.challenge,
    required this.answerController,
  });

  final GameState gs;
  final AdultGateChallenge? challenge;
  final TextEditingController answerController;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Solve this before opening Google Play.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: s.text.withValues(alpha: 0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: s.dark ? 0.10 : 0.78),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(GameConfig.coral).withValues(alpha: 0.32),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${challenge?.prompt ?? '0 + 0'} =',
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: s.text,
                      fontWeight: FontWeight.w900,
                      fontFamily: AppFonts.head,
                      fontSize: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 96,
                child: TextField(
                  key: const Key('adultGateAnswerField'),
                  controller: answerController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) =>
                      gs.submitAdultGateAnswer(answerController.text),
                  style: TextStyle(
                    color: s.text,
                    fontWeight: FontWeight.w900,
                    fontFamily: AppFonts.head,
                    fontSize: 22,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: s.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(GameConfig.coral),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (gs.adultGateError.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            gs.adultGateError,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(GameConfig.coral),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Daily Challenges Modal
// ═══════════════════════════════════════════════════════════════
class _DailyCalendarBadge extends StatelessWidget {
  const _DailyCalendarBadge({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return Container(
      width: 54,
      height: 58,
      decoration: BoxDecoration(
        color: s.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: s.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 18,
            alignment: Alignment.center,
            color: const Color(GameConfig.coral),
            child: Text(
              months[date.month - 1],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                height: 1,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: s.text,
                  fontFamily: AppFonts.head,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DailyChallengesModal extends StatelessWidget {
  const DailyChallengesModal({super.key, required this.gs, this.today});
  final GameState gs;
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return ModalShell(
      icon: '📅',
      iconWidget: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _DailyCalendarBadge(date: today ?? DateTime.now()),
      ),
      title: 'Daily Challenges',
      maxHeight: 540,
      actions: [
        NeoButton(
            label: 'Close', color: GameConfig.coral, onPressed: gs.closeModal),
      ],
      child: Column(
        children: [
          const SizedBox(height: 6),
          ...gs.activeDailyChallenges.map((c) {
            final cur = gs.dailyProgress[c.id] ?? 0;
            final done = gs.dailyCompleted[c.id] == true;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: done
                    ? const Color(GameConfig.mint).withValues(alpha: 0.12)
                    : s.surface2.withValues(alpha: s.dark ? 0.9 : 0.72),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: done
                      ? const Color(GameConfig.mint)
                      : Colors.white.withValues(alpha: 0.68),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.title,
                          style: TextStyle(
                            color: s.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        Text(c.desc,
                            style: TextStyle(fontSize: 11, color: s.muted)),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: (cur / c.target).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: s.surface.withValues(alpha: 0.65),
                          color: done
                              ? const Color(GameConfig.mint)
                              : const Color(GameConfig.coral),
                        ),
                        Text(
                          '${cur.clamp(0, c.target)} / ${c.target}',
                          style: TextStyle(fontSize: 10, color: s.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      Text(
                        done ? '✓' : '+${c.reward}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color:
                              Color(done ? GameConfig.mint : GameConfig.coin),
                        ),
                      ),
                      Text(done ? 'Done' : '🪙',
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
