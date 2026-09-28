import 'package:flutter/material.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/models/nivel_busqueda.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/views/encuentra_objetivo_flujo.dart';

/// Atención selectiva: en una cuadrícula de letras, números, figuras y frutas,
/// tocar solo el estímulo indicado antes de que acaben los 2 minutos.
class EncuentraObjetivoGame extends Game {
  const EncuentraObjetivoGame({this.dificultad = Dificultad.facil});

  static const idJuego = 'atencion.encuentra_objetivo';

  /// Instrucciones y resultado que se suman a la ronda.
  static const _preparacion = Duration(minutes: 1);

  @override
  final Dificultad dificultad;

  @override
  String get id => idJuego;

  @override
  String get titulo => 'Encuentra el objetivo';

  @override
  String get descripcion => 'Atención selectiva';

  @override
  String get instrucciones => 'Toque en la cuadrícula solo el estímulo indicado.';

  @override
  Dominio get dominio => Dominio.atencion;

  @override
  IconData get icono => Icons.grid_view_rounded;

  @override
  Duration get duracionEstimada => NivelBusqueda.duracion + _preparacion;

  /// El resultado de cada nivel se registra solo al terminar la ronda, así que
  /// «Volver al menú» solo navega; [finalizarJuego] no se usa.
  @override
  Widget build({required FinalizarJuego finalizarJuego, required VoidCallback onBack}) =>
      EncuentraObjetivoFlujo(onBack: onBack);
}
