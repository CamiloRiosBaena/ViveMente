import 'package:flutter/material.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/features/atencion/tren_senales/models/nivel_tren.dart';
import 'package:vivamente/features/atencion/tren_senales/views/tren_senales_flujo.dart';

/// Atención sostenida: tocar ¡SEÑAL! solo cuando pasa el tren del color
/// objetivo, que se sortea en cada intento.
class TrenSenalesGame extends Game {
  const TrenSenalesGame({this.dificultad = Dificultad.facil});

  static const idJuego = 'atencion.tren_senales';

  /// Instrucciones y práctica que se suman a la ronda medida.
  static const _preparacion = Duration(seconds: 90);

  @override
  final Dificultad dificultad;

  @override
  String get id => idJuego;

  @override
  String get titulo => 'Tren de las señales';

  @override
  String get descripcion => 'Atención sostenida';

  @override
  String get instrucciones => 'Cuando pase el tren del color indicado, toque el botón grande.';

  @override
  Dominio get dominio => Dominio.atencion;

  @override
  IconData get icono => Icons.train_rounded;

  @override
  Duration get duracionEstimada => NivelTren.de(dificultad).duracion + _preparacion;

  @override
  Widget build({required FinalizarJuego finalizarJuego, required VoidCallback onBack}) =>
      TrenSenalesFlujo(finalizarJuego: finalizarJuego, onBack: onBack);
}
