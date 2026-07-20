import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_state.dart';
import '../game_config.dart';
import '../models/enums.dart';
import '../services/settings.dart';
import '../widgets/common.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  static const _weakSkillsGradient = <Color>[
    Color(0xFF7C3AED), // bright violet
    Color(0xFFDB2777), // deep pink / magenta
    Color(0xFFFF6B6B), // coral / light red
  ];

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final s = context.watch<SettingsService>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(s: s, gs: gs),
                const SizedBox(height: 20),

                // PERSONALIZED LEARNING
                _SectionLabel('RECOMMENDED FOR YOU', s),
                _CampaignCard(
                  key: const Key('weak-skills-practice-row'),
                  icon: '🚀',
                  title: 'Weak Skills Practice',
                  subtitle: 'Build Your Skills',
                  color: const Color(0xFF7C3AED),
                  gradientColors: _weakSkillsGradient,
                  onTap: () => gs.goToConfig('weakSkills'),
                ),
                const SizedBox(height: 22),

                // CHALLENGES
                _SectionLabel(
                  'CHALLENGES',
                  s,
                  trailing: _streakBadge(gs, s),
                ),
                _CampaignCard(
                  icon: '🏆',
                  title: 'Master Challenge',
                  subtitle: 'BOSS BATTLES • 5 STAGES',
                  color: s.accent(GameConfig.coral),
                  gradientColors: const [
                    Color(0xFF6D28D9),
                    Color(0xFF9D174D),
                    Color(0xFFFF6B6B),
                  ],
                  onTap: () => gs.goToConfig('master'),
                ),
                const SizedBox(height: 10),
                _CampaignCard(
                  icon: gs.dailyBoss?.icon ?? '🐲',
                  title: gs.dailyBoss?.name ?? 'Daily Boss',
                  subtitle: gs.isDailyBossClaimedToday
                      ? 'CLEARED TODAY'
                      : 'NEW CHALLENGE TODAY',
                  color: s.accent(GameConfig.punch),
                  gradientColors: const [
                    Color(0xFFD94660),
                    Color(0xFFF15A45),
                    Color(0xFFFF8A3D),
                  ],
                  onTap: gs.isDailyBossClaimedToday ? () {} : gs.showDailyBoss,
                ),
                const SizedBox(height: 10),
                _CampaignCard(
                  icon: '🧭',
                  title: 'Operation Quest',
                  subtitle: '7 TRAILS • 21 STAGES',
                  color: s.accent(GameConfig.mango),
                  gradientColors: const [
                    Color(0xFFF97316),
                    Color(0xFFFB7185),
                    Color(0xFFF59E0B),
                  ],
                  onTap: gs.showOperationQuest,
                ),
                const SizedBox(height: 24),

                // QUICK PRACTICE
                _SectionLabel('QUICK PRACTICE', s),
                const SizedBox(height: 2),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = (constraints.maxWidth - 12) / 2;
                    final cardHeight = (cardWidth / 1.62).clamp(88.0, 132.0);

                    return Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: _PracticeCard(
                            '+',
                            'Addition',
                            s.opColor(Operation.addition),
                            () => gs.goToConfig('addition'),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: _PracticeCard(
                            '−',
                            'Subtraction',
                            s.opColor(Operation.subtraction),
                            () => gs.goToConfig('subtraction'),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: _PracticeCard(
                            '×',
                            'Multiplication',
                            s.opColor(Operation.multiplication),
                            () => gs.goToConfig('multiplication'),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: _PracticeCard(
                            '÷',
                            'Division',
                            s.opColor(Operation.division),
                            () => gs.goToConfig('division'),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: _PracticeCard(
                            '?',
                            'Missing Operation',
                            s.opColor(Operation.mixed),
                            () => gs.goToConfig('missingOperation'),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: _PracticeCard(
                            '🧮',
                            'Mixed Operations',
                            s.opColor(Operation.mixed),
                            () => gs.goToConfig('mixed'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 26),

                // SECONDARY NAVIGATION
                _BottomNavDock(gs: gs),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '🎓 Designed by Mr. Mohamed Khairy, Mathematics Supervisor',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 11,
                          color: s.muted,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
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

  Widget _streakBadge(GameState gs, SettingsService s) {
    if (gs.loginStreak < 2) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(GameConfig.mango), Color(GameConfig.coral)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '🔥 ${gs.loginStreak}d streak',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _BottomNavDock extends StatelessWidget {
  const _BottomNavDock({required this.gs});

  final GameState gs;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      decoration: BoxDecoration(
        color: s.surface.withValues(alpha: s.dark ? 0.86 : 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: s.dark ? 0.16 : 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: s.dark ? 0.18 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _NavBtn(
              icon: Icons.emoji_events,
              label: 'Hall of Fame',
              onTap: () => gs.showModal(GameModal.highScore),
            ),
          ),
          Expanded(
            child: _NavBtn(
              icon: Icons.military_tech,
              label: 'Achievements',
              onTap: () => gs.showModal(GameModal.achievements),
            ),
          ),
          Expanded(
            child: _NavBtn(
              icon: Icons.storefront,
              label: 'Shop',
              onTap: () => gs.showModal(GameModal.coinShop),
              isHome: true,
            ),
          ),
          Expanded(
            child: _NavBtn(
              icon: Icons.bar_chart,
              label: 'Skills',
              onTap: () => gs.showModal(GameModal.skillDashboard),
            ),
          ),
          Expanded(
            child: _DailyNavBtn(
              onTap: () => gs.showModal(GameModal.dailyChallenges),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyNavBtn extends StatelessWidget {
  const _DailyNavBtn({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: s.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.75),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.calendar_today_outlined,
                  size: 22,
                  color: s.muted,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Daily',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: s.muted,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.s, required this.gs});

  final SettingsService s;
  final GameState gs;

  @override
  Widget build(BuildContext context) {
    const brandIconSize = 48.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
      decoration: BoxDecoration(
        color: s.surface.withValues(alpha: s.dark ? 0.78 : 0.90),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: s.dark ? 0.14 : 0.70),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: s.dark ? 0.16 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _EqualBrandIcon(size: brandIconSize),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: brandIconSize,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('MATH', style: _brandWordStyle(s)),
                        Text('CHALLENGE', style: _brandWordStyle(s)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'BOSS BATTLE EDITION',
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        color: s.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: CoinPill(coins: gs.coins, settings: s),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: IconButton(
              icon: Icon(Icons.settings, color: s.text),
              onPressed: () => gs.showModal(GameModal.settings),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _brandWordStyle(SettingsService s) {
    return TextStyle(
      color: s.text,
      fontSize: 24,
      fontWeight: FontWeight.w900,
      fontFamily: AppFonts.head,
      height: 0.82,
    );
  }
}

class _EqualBrandIcon extends StatelessWidget {
  const _EqualBrandIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(GameConfig.coral),
            Color(0xFFD4681A),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(GameConfig.coral).withValues(alpha: 0.24),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.48,
          height: size * 0.30,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _EqualBrandBar(),
              _EqualBrandBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _EqualBrandBar extends StatelessWidget {
  const _EqualBrandBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.s, {this.trailing});

  final String text;
  final SettingsService s;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 9),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              color: s.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.gradientColors,
  });

  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final List<Color>? gradientColors;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    final colors = gradientColors ??
        [
          Color.lerp(color, const Color(GameConfig.grape), 0.25)!,
          const Color(GameConfig.coral),
          const Color(GameConfig.mango),
        ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 86),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.30),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: s.dark ? 0.22 : 0.24),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.34),
                  ),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      icon,
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        fontFamily: AppFonts.head,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.90),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.58),
                  ),
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard(this.symbol, this.label, this.color, this.onTap);

  final String symbol;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final darkColor = Color.lerp(color, Colors.black, 0.18)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(color, Colors.white, 0.16)!,
                darkColor,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.26),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.40),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      symbol,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
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

class _NavBtn extends StatelessWidget {
  const _NavBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isHome = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isHome;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: isHome ? 52 : 42,
              height: isHome ? 52 : 42,
              decoration: BoxDecoration(
                gradient: isHome
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(GameConfig.coral),
                          Color(0xFFD4681A),
                        ],
                      )
                    : null,
                color: isHome ? null : s.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isHome
                      ? Colors.white.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.75),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isHome ? const Color(GameConfig.coral) : Colors.black)
                            .withValues(alpha: isHome ? 0.30 : 0.06),
                    blurRadius: isHome ? 16 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: isHome ? Colors.white : s.muted,
                size: isHome ? 24 : 20,
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 9.2,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                  color: s.muted,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
