import 'package:go_router/go_router.dart';

import 'package:vivamente/core/models/game.dart';

import 'package:vivamente/features/admin/views/panel_view.dart';
import 'package:vivamente/features/auth/views/login_view.dart';
import 'package:vivamente/features/juegos/views/dominio_view.dart';
import 'package:vivamente/features/juegos/views/juego_view.dart';
import 'package:vivamente/features/session/views/adulto_cedula_view.dart';
import 'package:vivamente/features/session/views/adulto_datos_view.dart';
import 'package:vivamente/features/session/views/bienvenida_view.dart';
import 'package:vivamente/features/session/views/evaluador_view.dart';
import 'package:vivamente/features/session/views/inicio_view.dart';
import 'package:vivamente/features/splash/views/splash_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/', builder: (_, _) => const BienvenidaView()),
    GoRoute(path: '/evaluador', builder: (_, _) => const EvaluadorView()),
    GoRoute(path: '/adulto/cedula', builder: (_, _) => const AdultoCedulaView()),
    GoRoute(path: '/adulto/datos', builder: (_, _) => const AdultoDatosView()),
    GoRoute(path: '/inicio', builder: (_, _) => const InicioView()),
    GoRoute(
      path: '/dominio/:dominio',
      redirect: (_, state) =>
          Dominio.values.asNameMap().containsKey(state.pathParameters['dominio']) ? null : '/inicio',
      builder: (_, state) =>
          DominioView(dominio: Dominio.values.byName(state.pathParameters['dominio']!)),
    ),
    GoRoute(
      path: '/juego/:id',
      builder: (_, state) => JuegoView(juegoId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/login', builder: (_, _) => const LoginView()),
    GoRoute(path: '/panel', builder: (_, _) => const PanelView()),
  ],
);
