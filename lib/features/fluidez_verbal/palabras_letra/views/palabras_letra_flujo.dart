import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/providers/palabras_letra_provider.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/views/palabras_instrucciones_view.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/views/palabras_juego_view.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/views/palabras_presentacion_view.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/views/palabras_resultado_view.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/views/palabras_revision_view.dart';

/// Pantallas de «Palabras con una letra» según la fase del provider:
/// instrucciones → letra en grande → ronda → revisión → resultado.
class PalabrasLetraFlujo extends ConsumerStatefulWidget {
  const PalabrasLetraFlujo({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<PalabrasLetraFlujo> createState() => _PalabrasLetraFlujoState();
}

class _PalabrasLetraFlujoState extends ConsumerState<PalabrasLetraFlujo> {
  late final AppLifecycleListener _ciclo;

  @override
  void initState() {
    super.initState();
    // Si la app pasa a segundo plano en plena ronda, se pausa sola.
    _ciclo = AppLifecycleListener(onHide: () => ref.read(palabrasLetraProvider.notifier).pausar());
  }

  @override
  void dispose() {
    _ciclo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fase = ref.watch(palabrasLetraProvider.select((s) => s.fase));

    return PopScope(
      // En plena ronda, «atrás» del sistema pausa en vez de salir; durante
      // los segundos de la letra en grande o en la revisión no hace nada,
      // para no perder la ronda.
      canPop: fase == FasePalabras.instrucciones || fase == FasePalabras.resultado,
      onPopInvokedWithResult: (salio, _) {
        if (!salio) ref.read(palabrasLetraProvider.notifier).pausar();
      },
      child: switch (fase) {
        FasePalabras.instrucciones => PalabrasInstruccionesView(onBack: widget.onBack),
        FasePalabras.presentacion => const PalabrasPresentacionView(),
        FasePalabras.jugando => PalabrasJuegoView(onSalir: widget.onBack),
        FasePalabras.revision => const PalabrasRevisionView(),
        FasePalabras.resultado => PalabrasResultadoView(onVolver: widget.onBack),
      },
    );
  }
}
