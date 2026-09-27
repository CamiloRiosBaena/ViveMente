import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/providers/encuentra_objetivo_provider.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/views/busqueda_instrucciones_view.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/views/busqueda_juego_view.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/views/busqueda_resultado_view.dart';

/// Pantallas de «Encuentra el objetivo» según la fase del provider:
/// instrucciones → cuadrícula → resultado.
class EncuentraObjetivoFlujo extends ConsumerStatefulWidget {
  const EncuentraObjetivoFlujo({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<EncuentraObjetivoFlujo> createState() => _EncuentraObjetivoFlujoState();
}

class _EncuentraObjetivoFlujoState extends ConsumerState<EncuentraObjetivoFlujo> {
  late final AppLifecycleListener _ciclo;

  @override
  void initState() {
    super.initState();
    // Si la app pasa a segundo plano en plena ronda, se pausa sola.
    _ciclo = AppLifecycleListener(onHide: () => ref.read(encuentraObjetivoProvider.notifier).pausar());
  }

  @override
  void dispose() {
    _ciclo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fase = ref.watch(encuentraObjetivoProvider.select((s) => s.fase));

    return PopScope(
      // En plena ronda, «atrás» del sistema pausa en vez de salir.
      canPop: fase != FaseBusqueda.jugando,
      onPopInvokedWithResult: (salio, _) {
        if (!salio) ref.read(encuentraObjetivoProvider.notifier).pausar();
      },
      child: switch (fase) {
        FaseBusqueda.instrucciones => BusquedaInstruccionesView(onBack: widget.onBack),
        FaseBusqueda.jugando => BusquedaJuegoView(onSalir: widget.onBack),
        FaseBusqueda.resultado => BusquedaResultadoView(onVolver: widget.onBack),
      },
    );
  }
}
