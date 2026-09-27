import 'package:vivamente/core/models/game.dart';

/// Parámetros de una ronda según la dificultad. Todas duran 2 minutos; cambia
/// el tamaño de la cuadrícula, cuántos objetivos hay y cuánto se les parecen
/// los distractores.
///
/// - Nivel 1: 5 × 6, pocos tipos de distractores y ninguno parecido.
/// - Nivel 2: 6 × 7, más variedad de distractores, ninguno parecido.
/// - Nivel 3: 6 × 8, cerca de la mitad de los distractores se parecen al
///   objetivo (A con 4 o R, 8 con B, ★ con ☆…).
class NivelBusqueda {
  const NivelBusqueda({
    required this.dificultad,
    required this.columnas,
    required this.filas,
    required this.objetivosMin,
    required this.objetivosMax,
    required this.variedad,
    this.proporcionParecidos = 0,
  });

  final Dificultad dificultad;
  final int columnas;
  final int filas;

  /// Cuántos objetivos hay en la cuadrícula; cambia en cada intento.
  final int objetivosMin;
  final int objetivosMax;

  /// Cuántos símbolos distintos se usan como distractores.
  final int variedad;

  /// Fracción de distractores tomados de los parecidos al objetivo.
  final double proporcionParecidos;

  static const duracion = Duration(minutes: 2);

  int get casillas => columnas * filas;

  static const _nivel1 = NivelBusqueda(
    dificultad: Dificultad.facil,
    columnas: 5,
    filas: 6,
    objetivosMin: 5,
    objetivosMax: 7,
    variedad: 8,
  );

  static const _nivel2 = NivelBusqueda(
    dificultad: Dificultad.medio,
    columnas: 6,
    filas: 7,
    objetivosMin: 7,
    objetivosMax: 9,
    variedad: 14,
  );

  static const _nivel3 = NivelBusqueda(
    dificultad: Dificultad.dificil,
    columnas: 6,
    filas: 8,
    objetivosMin: 8,
    objetivosMax: 11,
    variedad: 14,
    proporcionParecidos: 0.45,
  );

  static NivelBusqueda de(Dificultad d) => switch (d) {
        Dificultad.facil => _nivel1,
        Dificultad.medio => _nivel2,
        Dificultad.dificil => _nivel3,
      };
}
