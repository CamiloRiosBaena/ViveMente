import 'package:flutter/material.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/models/nivel_desayuno.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/views/prepara_desayuno_flujo.dart';

/// Memoria de trabajo: retener la lista de un desayuno mientras se ve unos
/// segundos y luego sacar esos alimentos de una bandeja revuelta; en el nivel
/// 3, en el mismo orden (Baddeley, 2000; Willis, 1996).
class PreparaDesayunoGame extends Game {
  const PreparaDesayunoGame({this.dificultad = Dificultad.facil});

  static const idJuego = 'memoria.prepara_desayuno';

  /// Instrucciones, bandeja y resultado que se suman a la lista.
  static const _preparacion = Duration(minutes: 2);

  @override
  final Dificultad dificultad;

  @override
  String get id => idJuego;

  @override
  String get titulo => 'Prepara el desayuno';

  @override
  String get descripcion => 'Memoria de trabajo';

  @override
  String get instrucciones => 'Recuerde la lista del desayuno y ponga esos alimentos en el plato.';

  @override
  Dominio get dominio => Dominio.memoria;

  @override
  IconData get icono => Icons.free_breakfast_outlined;

  @override
  Duration get duracionEstimada =>
      NivelDesayuno.exposicion(NivelDesayuno.de(dificultad).elementosMax) + _preparacion;

  /// El resultado de cada nivel se registra solo al terminar la ronda, así que
  /// «Volver al menú» solo navega; [finalizarJuego] no se usa.
  @override
  Widget build({required FinalizarJuego finalizarJuego, required VoidCallback onBack}) =>
      PreparaDesayunoFlujo(onBack: onBack);
}
