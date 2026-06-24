import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'engine/game_state.dart' as gs;
import 'game_config.dart';
import 'services/storage.dart';
import 'services/settings.dart';
import 'services/audio.dart';
import 'screens/menu_screen.dart';
import 'screens/numtype_screen.dart';
import 'screens/config_screen.dart';
import 'screens/player_screen.dart';
import 'screens/game_screen.dart' as game_screen;
import 'theme.dart';
import 'widgets/modals.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  runApp(const MathChallengeApp());
}

class MathChallengeApp extends StatelessWidget {
  const MathChallengeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsService()),
        Provider<AudioService>(create: (ctx) {
          final s = ctx.read<SettingsService>();
          s.load(
            dark: Storage.getBool('mc_dark', false),
            sound: Storage.getBool('mc_sound', true),
            vibration: Storage.getBool('mc_vibration', true),
            dyslexia: Storage.getBool('mc_dyslexia', false),
            colorblind: Storage.getBool('mc_colorblind', false),
            lowPerf: Storage.getBool('mc_lowPerf', false),
            reduceMotion: Storage.getBool('mc_reduceMotion', false),
            animSpeed: Storage.getDouble('mc_animSpeed', 1.0),
          );
          return AudioService(s);
        }),
        ChangeNotifierProvider(create: (ctx) {
          final s = ctx.read<SettingsService>();
          final a = ctx.read<AudioService>();
          final state = gs.GameState(settings: s, audio: a);
          state.load();
          return state;
        }),
      ],
      child: Consumer<SettingsService>(
        builder: (context, s, _) => MaterialApp(
          title: 'Math Challenge: Boss Battle Edition',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(s),
          darkTheme: AppTheme.dark(s),
          themeMode: s.dark ? ThemeMode.dark : ThemeMode.light,
          home: const _AppShell(),
        ),
      ),
    );
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<gs.GameState>();
    final s = context.watch<SettingsService>();
    return Scaffold(
      backgroundColor: s.bg,
      body: Stack(
        children: [
          // Mesh background — soft radial gradients to match the original theme.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.2,
                  colors: [
                    const Color(GameConfig.mango).withValues(alpha: s.dark ? 0.15 : 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomRight,
                  radius: 1.2,
                  colors: [
                    const Color(GameConfig.sky).withValues(alpha: s.dark ? 0.12 : 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Foreground screens
          _screenFor(state.currentScreen),
          // Toast
          if (state.toastVisible)
            Positioned(
              top: 56,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: state.toastVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(GameConfig.coral),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(GameConfig.coral).withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(state.toastMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Modal layer
          const ModalRouter(),
        ],
      ),
    );
  }

  Widget _screenFor(gs.GameScreen s) {
    switch (s) {
      case gs.GameScreen.menu:     return const MenuScreen();
      case gs.GameScreen.numType:  return const NumTypeScreen();
      case gs.GameScreen.config:   return const ConfigScreen();
      case gs.GameScreen.player:   return const PlayerSetupScreen();
      case gs.GameScreen.game:     return const game_screen.GameScreen();
    }
  }
}
