import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_state.dart';
import '../game_config.dart';
import '../models/enums.dart';
import '../services/settings.dart';
import '../widgets/common.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

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
            _Header(s: s, gs: gs),
            const SizedBox(height: 16),

            // CAMPAIGN label
            _SectionLabel('CAMPAIGN', s, trailing: _streakBadge(gs, s)),
            _CampaignCard(
              icon: '➕',
              title: 'Operation Quest',
              subtitle: '5 TRAILS • 15 STAGES',
              color: s.accent(GameConfig.mango),
              onTap: gs.showOperationQuest,
            ),
            const SizedBox(height: 10),
            _CampaignCard(
              icon: '🏆',
              title: 'Master Challenge',
              subtitle: 'BOSS BATTLES • 5 STAGES',
              color: s.accent(GameConfig.coral),
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
              onTap: gs.isDailyBossClaimedToday ? () {} : gs.showDailyBoss,
            ),
            const SizedBox(height: 20),

            // QUICK PRACTICE
            _SectionLabel('QUICK PRACTICE', s),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _PracticeCard('+', 'ADDITION', s.opColor(Operation.addition),
                    () => gs.goToConfig('addition')),
                _PracticeCard(
                    '−',
                    'SUBTRACTION',
                    s.opColor(Operation.subtraction),
                    () => gs.goToConfig('subtraction')),
                _PracticeCard(
                    '×',
                    'MULTIPLY',
                    s.opColor(Operation.multiplication),
                    () => gs.goToConfig('multiplication')),
                _PracticeCard('÷', 'DIVISION', s.opColor(Operation.division),
                    () => gs.goToConfig('division')),
              ],
            ),
            const SizedBox(height: 14),

            // MIXED OPS bar
            _MixBar(s: s, onTap: () => gs.goToConfig('mixed')),
            const SizedBox(height: 24),

            // BOTTOM NAV
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBtn(
                    icon: Icons.emoji_events,
                    label: 'Hall of Fame',
                    onTap: () => gs.showModal(GameModal.highScore)),
                _NavBtn(
                    icon: Icons.military_tech,
                    label: 'Achievements',
                    onTap: () => gs.showModal(GameModal.achievements)),
                _NavBtn(
                    icon: Icons.storefront,
                    label: 'Shop',
                    onTap: () => gs.showModal(GameModal.coinShop),
                    isHome: true),
                _NavBtn(
                    icon: Icons.bar_chart,
                    label: 'Skills',
                    onTap: () => gs.showModal(GameModal.skillDashboard)),
                _DailyNavBtn(
                    onTap: () => gs.showModal(GameModal.dailyChallenges)),
              ],
            ),
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
    );
  }

  Widget _streakBadge(GameState gs, SettingsService s) {
    if (gs.loginStreak < 2) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(GameConfig.mango), Color(GameConfig.coral)]),
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
        width: 64,
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: s.surface,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 12,
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
            const SizedBox(height: 4),
            Text(
              'Daily',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: s.muted,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
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
    return Row(
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
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: IconButton(
            icon: Icon(Icons.settings, color: s.text),
            onPressed: () => gs.showModal(GameModal.settings),
          ),
        ),
      ],
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
      padding: const EdgeInsets.only(left: 4, bottom: 8),
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
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(color, const Color(GameConfig.grape), 0.25)!,
                const Color(GameConfig.coral),
                const Color(GameConfig.mango),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.32),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: s.dark ? 0.26 : 0.30),
                blurRadius: 24,
                offset: const Offset(0, 8),
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
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.36),
                  ),
                ),
                child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        fontFamily: AppFonts.head,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.88),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.6)),
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                child: const Icon(Icons.chevron_right,
                    color: Colors.white, size: 26),
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
    final darkColor = Color.lerp(color, Colors.black, 0.22)!;
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
              colors: [Color.lerp(color, Colors.white, 0.12)!, darkColor],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.24),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.42)),
                ),
                child: Center(
                  child: Text(
                    symbol,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MixBar extends StatelessWidget {
  const _MixBar({required this.s, required this.onTap});
  final SettingsService s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(GameConfig.grape), Color(GameConfig.coral)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Text('🧮', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mixed Operations',
                      style: TextStyle(
                        color: s.dark ? Colors.black : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        fontFamily: AppFonts.head,
                      ),
                    ),
                    Text(
                      'THE ULTIMATE TEST',
                      style: TextStyle(
                        color: (s.dark ? Colors.black : Colors.white)
                            .withValues(alpha: 0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'PLAY',
                  style: TextStyle(
                    color: const Color(GameConfig.coral),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
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
        width: 64,
        height: 72,
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
                            .withValues(alpha: isHome ? 0.35 : 0.07),
                    blurRadius: isHome ? 18 : 12,
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
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: s.muted,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
