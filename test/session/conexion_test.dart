import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vivamente/core/services/conexion.dart';
import 'package:vivamente/core/widgets/aviso_sin_conexion.dart';

import '../helpers/falsos.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  const aviso = 'Sin conexión a internet. La app la necesita para funcionar.';

  Future<ConexionFalsa> abrir(WidgetTester tester, {required bool hay}) async {
    final red = ConexionFalsa(hay: hay);
    await tester.pumpWidget(ProviderScope(
      overrides: [conexionProvider.overrideWithValue(red)],
      child: const MaterialApp(home: AvisoSinConexion(child: Scaffold(body: Text('contenido')))),
    ));
    await tester.pumpAndSettle();
    return red;
  }

  testWidgets('con red no se ve el aviso', (tester) async {
    await abrir(tester, hay: true);
    expect(find.text(aviso), findsNothing);
    expect(find.text('contenido'), findsOneWidget);
  });

  testWidgets('el aviso aparece al perder la red y se va al volver', (tester) async {
    final red = await abrir(tester, hay: true);

    red.poner(false);
    await tester.pumpAndSettle();
    expect(find.text(aviso), findsOneWidget);
    expect(find.text('contenido'), findsOneWidget);

    red.poner(true);
    await tester.pumpAndSettle();
    expect(find.text(aviso), findsNothing);
  });

  testWidgets('si abre sin red el aviso sale de una vez', (tester) async {
    await abrir(tester, hay: false);
    expect(find.text(aviso), findsOneWidget);
  });
}
