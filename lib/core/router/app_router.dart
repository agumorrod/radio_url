import 'package:go_router/go_router.dart';
import 'package:radio_app/presentation/screens/main_shell.dart';
import 'package:radio_app/presentation/screens/settings_screen.dart';

/// Configuración de rutas - similar a @RequestMapping en Spring Boot
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Ruta principal: Shell con bottom navigation
    GoRoute(path: '/', builder: (context, state) => const MainShell()),

    // Ruta de ajustes (modal sobre la pantalla de inicio)
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
