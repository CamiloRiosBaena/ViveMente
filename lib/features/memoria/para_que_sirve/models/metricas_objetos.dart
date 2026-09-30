import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/features/memoria/para_que_sirve/models/pregunta.dart';

/// Lo que respondió en una pregunta y cuánto tardó en hacerlo.
class Respuesta {
  const Respuesta(this.pregunta, this.elegida, this.latencia);

  final Pregunta pregunta;

  /// Índice de la opción que eligió.
  final int elegida;
  final Duration latencia;

  bool get correcta => elegida == pregunta.correcta;
}

/// Cifras de una ronda.
class MetricasObjetos {
  const MetricasObjetos({required this.total, this.respuestas = const []});

  /// Preguntas de la ronda.
  final int total;
  final List<Respuesta> respuestas;

  int get aciertos => respuestas.where((r) => r.correcta).length;
  int get errores => respuestas.length - aciertos;

  /// Preguntas que quedaron sin responder (si salió antes de terminar).
  int get omisiones => total - respuestas.length;

  /// Tiempo pensando las respuestas, sin contar el de leer las explicaciones.
  Duration get tiempo => respuestas.fold(Duration.zero, (s, r) => s + r.latencia);

  /// De 0 a 100: la fracción de preguntas acertadas.
  int get puntaje => total == 0 ? 0 : (100 * aciertos / total).round();

  MetricasObjetos anotar(Respuesta r) => MetricasObjetos(total: total, respuestas: [...respuestas, r]);

  /// La latencia es el tiempo medio en responder.
  ResultadoJuego aResultado(Dificultad dificultad) => ResultadoJuego(
        puntajeBruto: puntaje,
        puntajeMaximo: 100,
        duracion: tiempo,
        aciertos: aciertos,
        errores: errores,
        omisiones: omisiones,
        latenciaPromedio: respuestas.isEmpty ? 0 : tiempo.inMilliseconds / respuestas.length,
        dificultad: dificultad,
      );
}

/// «01:42».
String formatoReloj(Duration d) {
  final s = d.inSeconds;
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}
