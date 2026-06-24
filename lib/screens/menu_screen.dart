import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_state.dart';
import '../game_config.dart';
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
              icon: '🏆',
              title: 'Master Challenge',
              subtitle: 'BOSS BATTLES • 5 STAGES',
              color: const Color(GameConfig.coral),
              onTap: () => gs.goToConfig('master'),
            ),
            const SizedBox(height: 10),
            _CampaignCard(
              icon: gs.dailyBoss?.icon ?? '🐲',
              title: gs.dailyBoss?.name ?? 'Daily Boss',
              subtitle: gs.isDailyBossClaimedToday ? 'CLEARED TODAY' : 'NEW CHALLENGE TODAY',
              color: const Color(GameConfig.punch),
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
                _PracticeCard('+', 'ADDITION', const Color(GameConfig.mint), () => gs.goToConfig('addition')),
                _PracticeCard('−', 'SUBTRACTION', const Color(GameConfig.sky), () => gs.goToConfig('subtraction')),
                _PracticeCard('×', 'MULTIPLY', const Color(GameConfig.mango), () => gs.goToConfig('multiplication')),
                _PracticeCard('÷', 'DIVISION', const Color(GameConfig.punch), () => gs.goToConfig('division')),
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
                _NavBtn(icon: Icons.emoji_events, label: 'Hall of Fame', onTap: () => gs.showModal(GameModal.highScore)),
                _NavBtn(icon: Icons.military_tech, label: 'Achievements', onTap: () => gs.showModal(GameModal.achievements)),
                _NavBtn(icon: Icons.storefront, label: 'Shop', onTap: () => gs.showModal(GameModal.coinShop), isHome: true),
                _NavBtn(icon: Icons.bar_chart, label: 'Skills', onTap: () => gs.showModal(GameModal.skillDashboard)),
                _NavBtn(icon: Icons.calendar_today, label: 'Daily', onTap: () => gs.showModal(GameModal.dailyChallenges)),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '🟰 Designed by Mr. Mohamed Khairy, Mathematics Supervisor',
                style: TextStyle(
                  fontSize: 11,
                  color: s.muted,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
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
        gradient: const LinearGradient(colors: [Color(GameConfig.mango), Color(GameConfig.coral)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('🔥 ${gs.loginStreak}d streak',
        style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11,
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
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(GameConfig.coral),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text('=',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MATH CHALLENGE',
                style: TextStyle(
                  color: s.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: AppFonts.head,
                  height: 1.0,
                ),
              ),
              Text('BOSS BATTLE EDITION',
                style: TextStyle(
                  color: s.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        CoinPill(coins: gs.coins, settings: s),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.settings, color: s.text),
          onPressed: () => gs.showModal(GameModal.settings),
        ),
      ],
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
          Text(text,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        fontFamily: AppFonts.head,
                      ),
                    ),
                    Text(subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 26),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(symbol,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(label,
                style: const TextStyle(
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
                    Text('Mixed Operations',
                      style: TextStyle(
                        color: s.dark ? Colors.black : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        fontFamily: AppFonts.head,
                      ),
                    ),
                    Text('THE ULTIMATE TEST',
                      style: TextStyle(
                        color: (s.dark ? Colors.black : Colors.white).withValues(alpha: 0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('PLAY',
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              width: isHome ? 52 : 42,
              height: isHome ? 52 : 42,
              decoration: BoxDecoration(
                color: isHome ? const Color(GameConfig.coral) : Colors.white,
                shape: BoxShape.circle,
                border: isHome ? null : Border.all(color: Colors.grey.shade300),
                boxShadow: isHome ? [
                  BoxShadow(
                    color: const Color(GameConfig.coral).withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ] : null,
              ),
              child: Icon(icon,
                color: isHome ? Colors.white : Colors.grey.shade700,
                size: isHome ? 24 : 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
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
