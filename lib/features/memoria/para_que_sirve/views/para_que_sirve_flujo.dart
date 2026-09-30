import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/features/memoria/para_que_sirve/providers/para_que_sirve_provider.dart';
import 'package:vivamente/features/memoria/para_que_sirve/views/objetos_fin_practica_view.dart';
import 'package:vivamente/features/memoria/para_que_sirve/views/objetos_instrucciones_view.dart';
import 'package:vivamente/features/memoria/para_que_sirve/views/objetos_pregunta_view.dart';
import 'package:vivamente/features/memoria/para_que_sirve/views/objetos_resultado_view.dart';

/// Pantallas de «¿Para qué sirve?» según la fase del provider:
/// instrucciones → preguntas de práctica → fin de práctica → preguntas →
/// resultado.
class ParaQueSirveFlujo extends ConsumerStatefulWidget {
  const ParaQueSirveFlujo({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<ParaQueSirveFlujo> createState() => _ParaQueSirveFlujoState();
}

class _ParaQueSirveFlujoState extends ConsumerState<ParaQueSirveFlujo> {
  late final AppLifecycleListener _ciclo;

  @override
  void initState() {
    super.initState();
    // Si la app pasa a segundo plano en plena ronda, se pausa sola.
    _ciclo = AppLifecycleListener(onHide: () => ref.read(paraQueSirveProvider.notifier).pausar());
  }

  @override
  void dispose() {
    _ciclo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fase = ref.watch(paraQueSirveProvider.select((s) => s.fase));

    return PopScope(
      // En plena ronda, «atrás» del sistema pausa en vez de salir.
      canPop: fase != FaseObjetos.pregunta,
      onPopInvokedWithResult: (salio, _) {
        if (!salio) ref.read(paraQueSirveProvider.notifier).pausar();
      },
      child: switch (fase) {
        FaseObjetos.instrucciones => ObjetosInstruccionesView(onBack: widget.onBack),
        FaseObjetos.pregunta => ObjetosPreguntaView(onSalir: widget.onBack),
        FaseObjetos.finPractica => const ObjetosFinPracticaView(),
        FaseObjetos.resultado => ObjetosResultadoView(onVolver: widget.onBack),
      },
    );
  }
}
