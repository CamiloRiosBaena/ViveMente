import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';
import 'package:vivamente/features/juegos/providers/juegos_provider.dart';
import 'package:vivamente/features/juegos/providers/resultados_provider.dart';
import 'package:vivamente/features/session/widgets/guarda_sesion.dart';

/// Monta cualquier [Game] del catálogo. Al terminar, el resultado del nivel
/// jugado queda en [resultadosProvider] y se vuelve a la lista del dominio.
class JuegoView extends ConsumerWidget {
  const JuegoView({super.key, required this.juegoId});

  final String juegoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final juego = ref.watch(juegoProvider(juegoId));

    return GuardaSesion(
      // Un id que no existe se trata como una sesión inválida: vuelve al inicio.
      permite: (s) => s.lista && juego != null,
      destino: '/inicio',
      child: Builder(builder: (context) {
        void volver() => volverOIr(context, '/dominio/${juego!.dominio.name}');
        return juego!.build(
          onBack: volver,
          finalizarJuego: (resultado) {
            // Primero se sale: registrar cambia el nivel elegido y el juego
            // volvería a sus instrucciones mientras la pantalla se cierra.
            volver();
            ref.read(resultadosProvider.notifier).registrar(juego.id, juego.dificultad, resultado);
          },
        );
      }),
    );
  }
}
