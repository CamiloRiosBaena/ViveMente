import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/models/alimento.dart';

/// Cifras de una ronda: se calculan con lo que quedó en el plato al terminar.
/// Lo que el adulto puso y luego quitó no cuenta: corregirse es parte de
/// recordar.
class MetricasDesayuno {
  const MetricasDesayuno({
    required this.lista,
    required this.plato,
    required this.conOrden,
    this.tiempo = Duration.zero,
  });

  /// Lo que había que recordar, en orden.
  final List<Alimento> lista;

  /// Un puesto por alimento de la lista; `null` si quedó vacío.
  final List<Alimento?> plato;

  final bool conOrden;

  /// Tiempo usado en la bandeja, sin contar el de memorizar.
  final Duration tiempo;

  Iterable<Alimento> get _puestos => plato.whereType<Alimento>();

  /// Alimentos de la lista que están en el plato, en cualquier puesto.
  int get aciertos => _puestos.where(lista.contains).length;

  /// Alimentos en el plato que no estaban en la lista.
  int get errores => _puestos.where((a) => !lista.contains(a)).length;

  /// Alimentos de la lista que faltaron.
  int get omisiones => lista.length - aciertos;

  /// Alimentos en el mismo puesto que en la lista.
  int get enOrden => [for (var i = 0; i < plato.length && i < lista.length; i++) if (plato[i] == lista[i]) i].length;

  bool enSuPuesto(int i) => i < plato.length && plato[i] == lista[i];

  /// De 0 a 100. Cada alimento recordado suma y cada error resta la mitad de
  /// lo que suma un acierto. Con orden, la mitad del valor de cada alimento es
  /// por recordarlo y la otra mitad por ponerlo en su puesto.
  int get puntaje {
    if (lista.isEmpty) return 0;
    final recordado = conOrden ? 0.5 * aciertos + 0.5 * enOrden : aciertos.toDouble();
    return (100 * (recordado - 0.5 * errores) / lista.length).round().clamp(0, 100);
  }

  MetricasDesayuno copyWith({List<Alimento?>? plato, Duration? tiempo}) => MetricasDesayuno(
        lista: lista,
        plato: plato ?? this.plato,
        conOrden: conOrden,
        tiempo: tiempo ?? this.tiempo,
      );

  /// La latencia es el tiempo medio por alimento recordado.
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
