import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/features/fluidez_verbal/comun/widgets/revision_respuestas.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/models/evaluador_palabras.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/palabras_letra_game.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/providers/palabras_letra_provider.dart';

/// Revisión de las palabras al terminar la ronda, antes del resultado.
class PalabrasRevisionView extends ConsumerWidget {
  const PalabrasRevisionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(palabrasLetraProvider);
    final notifier = ref.read(palabrasLetraProvider.notifier);

    return RevisionView(
      juegoId: PalabrasLetraGame.idJuego,
      items: [
        for (final (i, r) in s.respuestas.indexed)
          ItemRevision(
            texto: r.texto,
            ajuste: s.ajustes[i],
            motivo: switch (s.veredictos[i]) {
              Veredicto.valida => null,
              Veredicto.repetida => 'Ya la había dicho',
              Veredicto.otraLetra => 'No empieza con ${s.letra}',
              Veredicto.noEsPalabra => 'No es una palabra',
            },
            grave: s.veredictos[i] == Veredicto.otraLetra || s.veredictos[i] == Veredicto.noEsPalabra,
          ),
      ],
      onAjustar: notifier.ajustar,
      onConfirmar: notifier.confirmar,
    );
  }
}
