import 'package:go_router/go_router.dart';

import 'package:vivamente/features/admin/views/panel_view.dart';
import 'package:vivamente/features/auth/views/login_view.dart';
import 'package:vivamente/features/session/views/adulto_cedula_view.dart';
import 'package:vivamente/features/session/views/adulto_datos_view.dart';
import 'package:vivamente/features/session/views/bienvenida_view.dart';
import 'package:vivamente/features/session/views/evaluador_view.dart';
import 'package:vivamente/features/session/views/inicio_view.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const BienvenidaView()),
    GoRoute(path: '/evaluador', builder: (_, _) => const EvaluadorView()),
    GoRoute(path: '/adulto/cedula', builder: (_, _) => const AdultoCedulaView()),
    GoRoute(path: '/adulto/datos', builder: (_, _) => const AdultoDatosView()),
    GoRoute(path: '/inicio', builder: (_, _) => const InicioView()),
    GoRoute(path: '/login', builder: (_, _) => const LoginView()),
    GoRoute(path: '/panel', builder: (_, _) => const PanelView()),
  ],
);
