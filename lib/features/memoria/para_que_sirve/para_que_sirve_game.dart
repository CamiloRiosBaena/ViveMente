import 'package:flutter/material.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/features/memoria/para_que_sirve/views/para_que_sirve_flujo.dart';

/// Memoria semántica: recuperar para qué sirve un objeto cotidiano, dónde va
/// y con qué se relaciona. Cada respuesta se acompaña de una explicación del
/// concepto (Tulving, 1972; Willis, 1996).
class ParaQueSirveGame extends Game {
  const ParaQueSirveGame({this.dificultad = Dificultad.facil});

  static const idJuego = 'memoria.para_que_sirve';

  @override
  final Dificultad dificultad;

  @override
  String get id => idJuego;

  @override
  String get titulo => '¿Para qué sirve?';

  @override
  String get descripcion => 'Memoria semántica';

  @override
  String get instrucciones => 'Elija para qué sirve cada objeto, dónde va o con qué se relaciona.';

  @override
  Dominio get dominio => Dominio.memoria;

  @override
  IconData get icono => Icons.lightbulb_outline_rounded;

  /// Práctica, seis preguntas con su explicación y resultado.
  @override
  Duration get duracionEstimada => const Duration(minutes: 4);

  /// El resultado de cada nivel se registra solo al terminar la ronda, así que
  /// «Volver al menú» solo navega; [finalizarJuego] no se usa.
  @override
  Widget build({required FinalizarJuego finalizarJuego, required VoidCallback onBack}) =>
      ParaQueSirveFlujo(onBack: onBack);
}
