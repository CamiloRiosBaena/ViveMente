import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/features/fluidez_verbal/comun/widgets/revision_respuestas.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/models/evaluador_categoria.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/palabras_categoria_game.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/providers/palabras_categoria_provider.dart';

/// Revisión de las palabras al terminar la ronda medida, antes del resultado.
class CategoriaRevisionView extends ConsumerWidget {
  const CategoriaRevisionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(palabrasCategoriaProvider);
    final notifier = ref.read(palabrasCategoriaProvider.notifier);

    return RevisionView(
      juegoId: PalabrasCategoriaGame.idJuego,
      items: itemsRevision(s),
      onAjustar: notifier.ajustar,
      onConfirmar: notifier.confirmar,
    );
  }
}

/// Las respuestas de la ronda como se muestran al revisarlas, también al
/// terminar la práctica.
List<ItemRevision> itemsRevision(PalabrasCategoriaState s) => [
      for (final (i, e) in s.evaluaciones.indexed)
        ItemRevision(
          texto: e.palabra,
          ajuste: s.ajustes[i],
          motivo: switch (e.veredicto) {
            Veredicto.valida => null,
            Veredicto.repetida => 'Ya la había dicho',
            Veredicto.otraCategoria => 'Es de ${e.categoria?.nombre.toLowerCase() ?? 'otra categoría'}',
            Veredicto.noReconocida => 'No la reconozco en ${s.categoria.nombre.toLowerCase()}',
          },
          grave: e.veredicto == Veredicto.otraCategoria,
        ),
    ];
