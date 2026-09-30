import 'package:vivamente/core/models/game.dart';

/// Qué se pregunta en cada nivel.
///
/// - Nivel 1: la función directa del objeto («¿Para qué sirve?»).
/// - Nivel 2: el lugar o grupo al que pertenece («¿Dónde va?»), eligiendo
///   entre tres contenedores temáticos.
/// - Nivel 3: el objeto con el que se relaciona por su uso o su origen
///   (llave → puerta, abeja → miel).
enum TipoPregunta { funcion, lugar, pareja }

class NivelObjetos {
  const NivelObjetos({required this.dificultad, required this.tipo, required this.enunciado});

  final Dificultad dificultad;
  final TipoPregunta tipo;
  final String enunciado;

  /// Preguntas de la ronda medida y de la práctica.
  static const preguntas = 6;
  static const preguntasPractica = 2;

  /// Opciones de cada pregunta.
  static const opciones = 3;

  static const _nivel1 = NivelObjetos(
    dificultad: Dificultad.facil,
    tipo: TipoPregunta.funcion,
    enunciado: '¿Para qué sirve este objeto?',
  );

  static const _nivel2 = NivelObjetos(
    dificultad: Dificultad.medio,
    tipo: TipoPregunta.lugar,
    enunciado: '¿Dónde va este objeto?',
  );

  static const _nivel3 = NivelObjetos(
    dificultad: Dificultad.dificil,
    tipo: TipoPregunta.pareja,
    enunciado: '¿Con cuál se relaciona?',
  );

  static NivelObjetos de(Dificultad d) => switch (d) {
        Dificultad.facil => _nivel1,
        Dificultad.medio => _nivel2,
        Dificultad.dificil => _nivel3,
      };

  /// «su función», para la consigna.
  String get queSeBusca => switch (tipo) {
        TipoPregunta.funcion => 'para qué sirve',
        TipoPregunta.lugar => 'dónde va',
        TipoPregunta.pareja => 'con cuál se relaciona',
      };
}
