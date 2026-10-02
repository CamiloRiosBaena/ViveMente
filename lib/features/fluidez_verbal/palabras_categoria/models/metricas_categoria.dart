import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/features/fluidez_verbal/comun/transcripcion.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/models/evaluador_categoria.dart';

/// Una palabra válida y cuándo se dio, desde el inicio de la ronda.
class PalabraDicha {
  const PalabraDicha(this.texto, this.momento, {this.dictada = false});

  /// Como está en el diccionario («perros» → «perro»).
  final String texto;
  final Duration momento;

  /// Si llegó por el micrófono en vez del teclado.
  final bool dictada;
}

/// Cifras de una ronda de palabras por categoría.
class MetricasCategoria {
  const MetricasCategoria({
    required this.meta,
    this.palabras = const [],
    this.repetidas = 0,
    this.otraCategoria = const [],
    this.noReconocidas = const [],
    this.tiempo = Duration.zero,
  });

  /// Palabras válidas que dan el puntaje completo.
  final int meta;

  /// Palabras válidas, en el orden en que se dieron.
  final List<PalabraDicha> palabras;

  /// Perseveraciones: palabras repetidas, o su plural o femenino.
  final int repetidas;

  /// Intrusiones: palabras de otra categoría, para mostrarlas.
  final List<String> otraCategoria;

  /// Lo que no está en ningún diccionario. No cuenta, pero se muestra para
  /// que el profesional revise si era válido.
  final List<String> noReconocidas;

  final Duration tiempo;

  /// Cifras de las [respuestas] de una ronda con sus [evaluaciones], según
  /// lo que decidió quien revisó: las aceptadas valen y las descartadas no
  /// cuentan para nada.
  factory MetricasCategoria.contar({
    required int meta,
    required List<RespuestaOida> respuestas,
    required List<Evaluacion> evaluaciones,
    required List<Ajuste> ajustes,
    required Duration tiempo,
  }) {
    var m = MetricasCategoria(meta: meta, tiempo: tiempo);
    for (final (i, r) in respuestas.indexed) {
      final e = evaluaciones[i];
      m = switch (ajustes[i]) {
        Ajuste.ninguno => m.anotar(e, r.momento, dictada: r.dictada),
        Ajuste.aceptada => m.anotar((veredicto: Veredicto.valida, palabra: e.palabra, categoria: e.categoria),
            r.momento,
            dictada: r.dictada),
        Ajuste.descartada => m,
      };
    }
    return m;
  }

  int get validas => palabras.length;
  int get errores => repetidas + otraCategoria.length + noReconocidas.length;

  /// De 0 a 100: la proporción de la meta alcanzada.
  int get puntaje => (100 * validas / meta).round().clamp(0, 100);

  /// Tiempo medio entre una palabra válida y la siguiente (la primera se
  /// cuenta desde el inicio). 0 si no hubo ninguna.
  double get ritmoMs => validas == 0 ? 0 : palabras.last.momento.inMilliseconds / validas;

  /// Válidas en cada tramo de 15 segundos: muestra si se agotó al final.
  List<int> porTramo(Duration total) {
    final tramos = List.filled((total.inSeconds / 15).ceil(), 0);
    for (final p in palabras) {
      tramos[(p.momento.inSeconds ~/ 15).clamp(0, tramos.length - 1)]++;
    }
    return tramos;
  }

  /// Suma la palabra al contador que le toca según su evaluación.
  MetricasCategoria anotar(Evaluacion e, Duration momento, {bool dictada = false}) => switch (e.veredicto) {
        Veredicto.valida => _copiar(palabras: [...palabras, PalabraDicha(e.palabra, momento, dictada: dictada)]),
        Veredicto.repetida => _copiar(repetidas: repetidas + 1),
        Veredicto.otraCategoria => _copiar(otraCategoria: [...otraCategoria, e.palabra]),
        Veredicto.noReconocida => _copiar(noReconocidas: [...noReconocidas, e.palabra]),
      };

  MetricasCategoria conTiempo(Duration t) => _copiar(tiempo: t);

  MetricasCategoria _copiar({
    List<PalabraDicha>? palabras,
    int? repetidas,
    List<String>? otraCategoria,
    List<String>? noReconocidas,
    Duration? tiempo,
  }) =>
      MetricasCategoria(
        meta: meta,
        palabras: palabras ?? this.palabras,
        repetidas: repetidas ?? this.repetidas,
        otraCategoria: otraCategoria ?? this.otraCategoria,
        noReconocidas: noReconocidas ?? this.noReconocidas,
        tiempo: tiempo ?? this.tiempo,
      );

  /// Los aciertos son las palabras válidas; los errores, repeticiones,
  /// intrusiones y no reconocidas. La latencia es el ritmo entre palabras.
  ResultadoJuego aResultado(Dificultad dificultad) => ResultadoJuego(
        puntajeBruto: validas,
        puntajeMaximo: meta,
        duracion: tiempo,
        aciertos: validas,
        errores: errores,
        latenciaPromedio: ritmoMs,
        dificultad: dificultad,
      );
}

/// «01:00».
String formatoReloj(Duration d) {
  final s = d.inSeconds;
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}
