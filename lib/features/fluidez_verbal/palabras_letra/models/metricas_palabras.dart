import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/models/evaluador_palabras.dart';

/// Una palabra válida y cuándo se dio, desde el inicio de la ronda.
class PalabraDicha {
  const PalabraDicha(this.texto, this.momento, {this.dictada = false});

  final String texto;
  final Duration momento;

  /// Si llegó por el micrófono en vez del teclado.
  final bool dictada;
}

/// Cifras de una ronda de palabras.
class MetricasPalabras {
  const MetricasPalabras({
    required this.meta,
    this.palabras = const [],
    this.repetidas = 0,
    this.otraLetra = 0,
    this.noValidas = 0,
    this.tiempo = Duration.zero,
  });

  /// Palabras válidas que dan el puntaje completo en este nivel.
  final int meta;

  /// Palabras válidas, en el orden en que se dieron.
  final List<PalabraDicha> palabras;

  /// Perseveraciones: palabras repetidas o plurales de una ya dicha.
  final int repetidas;

  /// Intrusiones: palabras que no empiezan con la letra.
  final int otraLetra;

  /// Entradas que no se leen como palabra.
  final int noValidas;

  final Duration tiempo;

  int get validas => palabras.length;
  int get errores => repetidas + otraLetra + noValidas;

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

  /// Suma la palabra al contador que le toca según su [veredicto].
  MetricasPalabras anotar(Veredicto veredicto, PalabraDicha palabra) => switch (veredicto) {
        Veredicto.valida => _copiar(palabras: [...palabras, palabra]),
        Veredicto.repetida => _copiar(repetidas: repetidas + 1),
        Veredicto.otraLetra => _copiar(otraLetra: otraLetra + 1),
        Veredicto.noEsPalabra => _copiar(noValidas: noValidas + 1),
      };

  /// Quita una palabra válida que se registró por error (un dictado mal oído).
  MetricasPalabras quitar(int i) => _copiar(palabras: [...palabras]..removeAt(i));

  MetricasPalabras conTiempo(Duration t) => _copiar(tiempo: t);

  MetricasPalabras _copiar({
    List<PalabraDicha>? palabras,
    int? repetidas,
    int? otraLetra,
    int? noValidas,
    Duration? tiempo,
  }) =>
      MetricasPalabras(
        meta: meta,
        palabras: palabras ?? this.palabras,
        repetidas: repetidas ?? this.repetidas,
        otraLetra: otraLetra ?? this.otraLetra,
        noValidas: noValidas ?? this.noValidas,
        tiempo: tiempo ?? this.tiempo,
      );

  /// Los aciertos son las palabras válidas; los errores, repeticiones,
  /// intrusiones y entradas no válidas. La latencia es el ritmo entre palabras.
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

/// «01:30».
String formatoReloj(Duration d) {
  final s = d.inSeconds;
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}
