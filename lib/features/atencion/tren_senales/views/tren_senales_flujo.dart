import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/features/atencion/tren_senales/providers/tren_senales_provider.dart';
import 'package:vivamente/features/atencion/tren_senales/views/tren_fin_practica_view.dart';
import 'package:vivamente/features/atencion/tren_senales/views/tren_instrucciones_view.dart';
import 'package:vivamente/features/atencion/tren_senales/views/tren_juego_view.dart';
import 'package:vivamente/features/atencion/tren_senales/views/tren_resultado_view.dart';

/// Pantallas de «El tren de las señales» según la fase del provider:
/// instrucciones → práctica → fin de práctica → ronda medida → resultado.
class TrenSenalesFlujo extends ConsumerStatefulWidget {
  const TrenSenalesFlujo({super.key, required this.finalizarJuego, required this.onBack});

  final FinalizarJuego finalizarJuego;
  final VoidCallback onBack;

  @override
  ConsumerState<TrenSenalesFlujo> createState() => _TrenSenalesFlujoState();
}

class _TrenSenalesFlujoState extends ConsumerState<TrenSenalesFlujo> {
  late final AppLifecycleListener _ciclo;

  @override
  void initState() {
    super.initState();
    // Si la app pasa a segundo plano en plena ronda, se pausa sola.
    _ciclo = AppLifecycleListener(onHide: () => ref.read(trenSenalesProvider.notifier).pausar());
  }

  @override
  void dispose() {
    _ciclo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fase = ref.watch(trenSenalesProvider.select((s) => s.fase));
    final notifier = ref.read(trenSenalesProvider.notifier);
    final jugando = fase == FaseTren.practica || fase == FaseTren.prueba;

    return PopScope(
      // En plena ronda, «atrás» del sistema pausa en vez de salir.
      canPop: !jugando,
      onPopInvokedWithResult: (salio, _) {
        if (!salio) notifier.pausar();
      },
      child: switch (fase) {
        FaseTren.instrucciones => TrenInstruccionesView(onBack: widget.onBack),
        FaseTren.practica || FaseTren.prueba => TrenJuegoView(onSalir: widget.onBack),
        FaseTren.finPractica => const TrenFinPracticaView(),
        FaseTren.resultado => TrenResultadoView(
            onContinuar: () => widget.finalizarJuego(ref.read(trenSenalesProvider).resultado!),
          ),
      },
    );
  }
}
