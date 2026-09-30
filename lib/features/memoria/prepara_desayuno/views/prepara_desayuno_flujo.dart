import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/providers/prepara_desayuno_provider.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/views/desayuno_bandeja_view.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/views/desayuno_fin_practica_view.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/views/desayuno_instrucciones_view.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/views/desayuno_lista_view.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/views/desayuno_resultado_view.dart';

/// Pantallas de «Prepara el desayuno» según la fase del provider:
/// instrucciones → práctica (lista y bandeja) → fin de práctica → lista a
/// memorizar → bandeja → resultado.
class PreparaDesayunoFlujo extends ConsumerStatefulWidget {
  const PreparaDesayunoFlujo({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<PreparaDesayunoFlujo> createState() => _PreparaDesayunoFlujoState();
}

class _PreparaDesayunoFlujoState extends ConsumerState<PreparaDesayunoFlujo> {
  late final AppLifecycleListener _ciclo;

  @override
  void initState() {
    super.initState();
    // Si la app pasa a segundo plano en plena ronda, se pausa sola.
    _ciclo = AppLifecycleListener(onHide: () => ref.read(preparaDesayunoProvider.notifier).pausar());
  }

  @override
  void dispose() {
    _ciclo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fase = ref.watch(preparaDesayunoProvider.select((s) => s.fase));

    return PopScope(
      // En plena ronda, «atrás» del sistema pausa en vez de salir.
      canPop: fase == FaseDesayuno.instrucciones ||
          fase == FaseDesayuno.finPractica ||
          fase == FaseDesayuno.resultado,
      onPopInvokedWithResult: (salio, _) {
        if (!salio) ref.read(preparaDesayunoProvider.notifier).pausar();
      },
      child: switch (fase) {
        FaseDesayuno.instrucciones => DesayunoInstruccionesView(onBack: widget.onBack),
        FaseDesayuno.memorizar => DesayunoListaView(onSalir: widget.onBack),
        FaseDesayuno.bandeja => DesayunoBandejaView(onSalir: widget.onBack),
        FaseDesayuno.finPractica => const DesayunoFinPracticaView(),
        FaseDesayuno.resultado => DesayunoResultadoView(onVolver: widget.onBack),
      },
    );
  }
}
