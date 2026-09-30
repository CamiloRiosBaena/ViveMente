import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/providers/palabras_categoria_provider.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/views/categoria_fin_practica_view.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/views/categoria_instrucciones_view.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/views/categoria_juego_view.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/views/categoria_presentacion_view.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/views/categoria_resultado_view.dart';

/// Pantallas de «Palabras por categoría» según la fase del provider:
/// instrucciones → práctica (categoría en grande y ronda) → fin de práctica
/// → categoría en grande → ronda → resultado.
class PalabrasCategoriaFlujo extends ConsumerStatefulWidget {
  const PalabrasCategoriaFlujo({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<PalabrasCategoriaFlujo> createState() => _PalabrasCategoriaFlujoState();
}

class _PalabrasCategoriaFlujoState extends ConsumerState<PalabrasCategoriaFlujo> {
  late final AppLifecycleListener _ciclo;

  @override
  void initState() {
    super.initState();
    // Si la app pasa a segundo plano en plena ronda, se pausa sola.
    _ciclo = AppLifecycleListener(onHide: () => ref.read(palabrasCategoriaProvider.notifier).pausar());
  }

  @override
  void dispose() {
    _ciclo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fase = ref.watch(palabrasCategoriaProvider.select((s) => s.fase));

    return PopScope(
      // En plena ronda, «atrás» del sistema pausa en vez de salir; durante
      // los segundos de la categoría en grande no hace nada.
      canPop: fase == FaseCategoria.instrucciones ||
          fase == FaseCategoria.finPractica ||
          fase == FaseCategoria.resultado,
      onPopInvokedWithResult: (salio, _) {
        if (!salio) ref.read(palabrasCategoriaProvider.notifier).pausar();
      },
      child: switch (fase) {
        FaseCategoria.instrucciones => CategoriaInstruccionesView(onBack: widget.onBack),
        FaseCategoria.presentacion => const CategoriaPresentacionView(),
        FaseCategoria.jugando => CategoriaJuegoView(onSalir: widget.onBack),
        FaseCategoria.finPractica => const CategoriaFinPracticaView(),
        FaseCategoria.resultado => CategoriaResultadoView(onVolver: widget.onBack),
      },
    );
  }
}
