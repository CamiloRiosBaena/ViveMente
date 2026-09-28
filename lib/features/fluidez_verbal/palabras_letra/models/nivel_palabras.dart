import 'package:vivamente/core/models/game.dart';

/// Parámetros de una ronda según la dificultad. Cambian la letra que puede
/// tocar, el tiempo y la meta de palabras.
///
/// - Nivel 1: letras con muchas palabras (M, C, S, L, A), 90 segundos.
/// - Nivel 2: letras intermedias (F, T, R, D, B), 60 segundos.
/// - Nivel 3: letras con pocas palabras (G, N, V, E, J), 60 segundos.
///
/// La P nunca se asigna: es la del ejemplo de las instrucciones.
class NivelPalabras {
  const NivelPalabras({
    required this.dificultad,
    required this.letras,
    required this.duracion,
    required this.meta,
  });

  final Dificultad dificultad;

  /// Letras posibles; en cada intento se sortea una.
  final List<String> letras;
  final Duration duracion;

  /// Palabras válidas que dan el puntaje completo. Cerca de lo que un adulto
  /// mayor sin deterioro dice en ese tiempo con letras así.
  final int meta;

  /// Letra del ejemplo: nunca sale en una ronda, para no regalar palabras.
  static const letraEjemplo = 'P';
  static const palabrasEjemplo = ['Pelota', 'Pan', 'Puerta', 'Palo'];

  static const _nivel1 = NivelPalabras(
    dificultad: Dificultad.facil,
    letras: ['M', 'C', 'S', 'L', 'A'],
    duracion: Duration(seconds: 90),
    meta: 15,
  );

  static const _nivel2 = NivelPalabras(
    dificultad: Dificultad.medio,
    letras: ['F', 'T', 'R', 'D', 'B'],
    duracion: Duration(seconds: 60),
    meta: 12,
  );

  static const _nivel3 = NivelPalabras(
    dificultad: Dificultad.dificil,
    letras: ['G', 'N', 'V', 'E', 'J'],
    duracion: Duration(seconds: 60),
    meta: 10,
  );

  static NivelPalabras de(Dificultad d) => switch (d) {
        Dificultad.facil => _nivel1,
        Dificultad.medio => _nivel2,
        Dificultad.dificil => _nivel3,
      };

  /// «90 segundos», «1 minuto».
  String get textoDuracion => duracion.inSeconds % 60 == 0
      ? '${duracion.inMinutes} ${duracion.inMinutes == 1 ? 'minuto' : 'minutos'}'
      : '${duracion.inSeconds} segundos';
}
