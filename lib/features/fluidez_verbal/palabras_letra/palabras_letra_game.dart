import 'package:flutter/material.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/models/nivel_palabras.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/views/palabras_letra_flujo.dart';

/// Fluidez fonológica: decir o escribir, antes de que acabe el tiempo, todas
/// las palabras posibles que empiecen con una letra. Ejercita la inhibición de
/// respuestas que no sirven y la flexibilidad para buscar palabras por su
/// sonido.
class PalabrasLetraGame extends Game {
  const PalabrasLetraGame({this.dificultad = Dificultad.facil});

  static const idJuego = 'fluidez_verbal.palabras_letra';

  /// Instrucciones y resultado que se suman a la ronda.
  static const _preparacion = Duration(minutes: 1);

  @override
  final Dificultad dificultad;

  @override
  String get id => idJuego;

  @override
  String get titulo => 'Palabras con una letra';

  @override
  String get descripcion => 'Fluidez fonológica';

  @override
  String get instrucciones => 'Diga o escriba palabras que empiecen con la letra indicada.';

  @override
  Dominio get dominio => Dominio.fluidezVerbal;

  @override
  IconData get icono => Icons.abc_rounded;

  @override
  Duration get duracionEstimada => NivelPalabras.de(dificultad).duracion + _preparacion;

  /// El resultado de cada nivel se registra solo al terminar la ronda, así que
  /// «Volver al menú» solo navega; [finalizarJuego] no se usa.
  @override
  Widget build({required FinalizarJuego finalizarJuego, required VoidCallback onBack}) =>
      PalabrasLetraFlujo(onBack: onBack);
}
