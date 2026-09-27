import 'package:vivamente/core/models/game.dart';

/// Cifras de una ronda de búsqueda.
class MetricasBusqueda {
  const MetricasBusqueda({
    required this.disponibles,
    this.aciertos = 0,
    this.errores = 0,
    this.tiempo = Duration.zero,
  });

  /// Objetivos que había en la cuadrícula.
  final int disponibles;

  /// Objetivos tocados (cada uno cuenta una sola vez).
  final int aciertos;

  /// Toques en casillas que no eran el objetivo.
  final int errores;

  /// Tiempo usado hasta terminar.
  final Duration tiempo;

  int get omisiones => disponibles - aciertos;

  /// Aciertos sobre todos los toques; 0 si no tocó nada.
  double get precision => aciertos + errores == 0 ? 0 : aciertos / (aciertos + errores);

  /// De 0 a 100: cada objetivo encontrado suma y cada error resta la mitad de
  /// lo que suma un acierto.
  int get puntaje =>
      disponibles == 0 ? 0 : (100 * (aciertos - 0.5 * errores) / disponibles).round().clamp(0, 100);

  MetricasBusqueda copyWith({int? aciertos, int? errores, Duration? tiempo}) => MetricasBusqueda(
        disponibles: disponibles,
        aciertos: aciertos ?? this.aciertos,
        errores: errores ?? this.errores,
        tiempo: tiempo ?? this.tiempo,
      );

  /// La latencia es el tiempo medio entre hallazgos (velocidad de búsqueda).
  ResultadoJuego aResultado(Dificultad dificultad) => ResultadoJuego(
        puntajeBruto: puntaje,
        puntajeMaximo: 100,
        duracion: tiempo,
        aciertos: aciertos,
        errores: errores,
        omisiones: omisiones,
        latenciaPromedio: aciertos == 0 ? 0 : tiempo.inMilliseconds / aciertos,
        dificultad: dificultad,
      );
}

/// «01:42».
String formatoReloj(Duration d) {
  final s = d.inSeconds;
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}
