import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vivamente/core/models/localidad.dart';
import 'package:vivamente/core/services/localidades_local.dart';
import 'package:vivamente/core/services/ubicacion.dart';
import 'package:vivamente/core/widgets/mapa_ubicacion.dart';
import 'package:vivamente/features/session/providers/sesion_provider.dart';
import 'package:vivamente/features/session/views/evaluador_view.dart';
import 'package:vivamente/features/session/views/ubicacion_view.dart';

import '../helpers/falsos.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Localidades de muestra', () {
    final local = LocalidadesLocal(LectorUbicacionFalso());

    test('un punto dentro del radio cae en la localidad', () async {
      final l = await local.localidadEn(4.6019, -74.0699);
      expect(l?.id, 'unad-jag');
    });

    test('un punto lejano queda como provisional mientras no hay back', () async {
      final l = await local.localidadEn(6.2442, -75.5812);
      expect(l?.id, LocalidadesLocal.provisional.id);
    });
  });

  group('Sesión', () {
    test('la ubicación se conserva al elegir evaluador y adulto', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final sesion = c.read(sesionProvider.notifier);

      expect(c.read(sesionProvider).hayEvaluador, isFalse);
      sesion.fijarUbicacion(Ubicacion(
        latitud: 1,
        longitud: 2,
        precisionMetros: 5,
        fecha: DateTime(2026),
        localidad: LocalidadesLocal.provisional,
      ));
      await sesion.iniciarConCedula('52100200');
      await sesion.elegirAdulto('41238950');

      final s = c.read(sesionProvider);
      expect(s.ubicacion?.latitud, 1);
      expect(s.lista, isTrue);
    });
  });

  group('Pantalla de ubicación', () {
    late LectorUbicacionFalso gps;
    late ProviderContainer c;

    Future<void> abrir(WidgetTester tester, String inicio) async {
      gps = LectorUbicacionFalso();
      c = ProviderContainer(overrides: [lectorUbicacionProvider.overrideWithValue(gps)]);
      addTearDown(c.dispose);
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final router = GoRouter(initialLocation: inicio, routes: [
        GoRoute(path: '/ubicacion', builder: (_, _) => const UbicacionView()),
        GoRoute(path: '/evaluador', builder: (_, _) => const EvaluadorView()),
      ]);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('verifica y deja pasar al evaluador', (tester) async {
      await abrir(tester, '/ubicacion');
      await tester.tap(find.text('Verificar ubicación'));
      await tester.pumpAndSettle();

      expect(find.text('Ubicación verificada'), findsOneWidget);
      expect(find.textContaining('José Acevedo'), findsOneWidget);
      expect(find.byType(MapaUbicacion), findsOneWidget);
      expect(c.read(sesionProvider).hayUbicacion, isFalse);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(c.read(sesionProvider).hayUbicacion, isTrue);
      expect(find.text('Cédula del evaluador'), findsOneWidget);
    });

    testWidgets('sin permiso avisa y permite reintentar', (tester) async {
      await abrir(tester, '/ubicacion');
      gps.fallo = FalloUbicacion.permisoNegado;
      await tester.tap(find.text('Verificar ubicación'));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo ubicar'), findsOneWidget);
      gps.fallo = null;
      await tester.tap(find.text('Intentar de nuevo'));
      await tester.pumpAndSettle();
      expect(gps.lecturas, 2);
      expect(find.text('Ubicación verificada'), findsOneWidget);
    });

    testWidgets('el evaluador sin ubicación devuelve a la ubicación', (tester) async {
      await abrir(tester, '/evaluador');
      expect(find.text('Verificar ubicación'), findsOneWidget);
    });
  });
}
