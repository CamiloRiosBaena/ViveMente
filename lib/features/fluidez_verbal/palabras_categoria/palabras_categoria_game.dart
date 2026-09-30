import 'package:flutter/material.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/models/nivel_categoria.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/views/palabras_categoria_flujo.dart';

/// Fluidez semántica: decir o escribir, en 60 segundos, todas las palabras
/// posibles de una categoría (animales, frutas, objetos del hogar,
/// profesiones o ciudades). Estimula la velocidad de acceso y la búsqueda
/// estratégica en la memoria semántica.
class PalabrasCategoriaGame extends Game {
  const PalabrasCategoriaGame({this.dificultad = Dificultad.facil});

  static const idJuego = 'fluidez_verbal.palabras_categoria';

  /// Instrucciones, práctica y resultado que se suman a la ronda.
  static const _preparacion = Duration(minutes: 2);

  @override
  final Dificultad dificultad;

  @override
  String get id => idJuego;

  @override
  String get titulo => 'Palabras por categoría';

  @override
  String get descripcion => 'Fluidez semántica';

  @override
  String get instrucciones => 'Diga o escriba palabras de la categoría indicada.';

  @override
  Dominio get dominio => Dominio.fluidezVerbal;

  @override
  IconData get icono => Icons.category_outlined;

  @override
  Duration get duracionEstimada => NivelCategoria.duracion + _preparacion;

  /// El resultado de cada nivel se registra solo al terminar la ronda, así que
  /// «Volver al menú» solo navega; [finalizarJuego] no se usa.
  @override
  Widget build({required FinalizarJuego finalizarJuego, required VoidCallback onBack}) =>
      PalabrasCategoriaFlujo(onBack: onBack);
}
