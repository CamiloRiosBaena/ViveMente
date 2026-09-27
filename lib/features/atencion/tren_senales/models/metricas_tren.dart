import 'package:vivamente/core/models/game.dart';

/// Registro de una ronda: se llena solo mientras pasan los trenes.
class MetricasTren {
  const MetricasTren({
    this.objetivos = 0,
    this.aciertos = 0,
    this.omisiones = 0,
    this.comisiones = 0,
    this.latencias = const [],
  });

  /// Trenes objetivo que ya terminaron de pasar.
  final int objetivos;

  /// Señales dadas mientras pasaba un tren objetivo.
  final int aciertos;

  /// Trenes objetivo que pasaron sin señal.
  final int omisiones;

  /// Señales sin tren objetivo en la vía (falsas alarmas).
  final int comisiones;

  /// Tiempo entre la aparición del tren objetivo y la señal, por acierto.
  final List<Duration> latencias;

  /// En milisegundos; 0 si no hubo aciertos.
  double get latenciaPromedio => latencias.isEmpty
      ? 0
      : latencias.fold<int>(0, (s, l) => s + l.inMilliseconds) / latencias.length;

  MetricasTren conAcierto(Duration latencia) => MetricasTren(
        objetivos: objetivos,
        aciertos: aciertos + 1,
        omisiones: omisiones,
        comisiones: comisiones,
        latencias: [...latencias, latencia],
      );

  MetricasTren conComision() => MetricasTren(
        objetivos: objetivos,
        aciertos: aciertos,
        omisiones: omisiones,
        comisiones: comisiones + 1,
        latencias: latencias,
      );

  /// Un tren objetivo salió de la pantalla; si no tuvo señal, es omisión.
  MetricasTren conObjetivoCerrado({required bool respondido}) => MetricasTren(
        objetivos: objetivos + 1,
        aciertos: aciertos,
        omisiones: respondido ? omisiones : omisiones + 1,
        comisiones: comisiones,
        latencias: latencias,
      );

  /// Puntaje: aciertos menos falsas alarmas, sobre el total de trenes objetivo.
  ResultadoJuego aResultado({required Duration duracion, required Dificultad dificultad}) =>
      ResultadoJuego(
        puntajeBruto: (aciertos - comisiones).clamp(0, objetivos),
        puntajeMaximo: objetivos == 0 ? 1 : objetivos,
        duracion: duracion,
        aciertos: aciertos,
        errores: comisiones,
        omisiones: omisiones,
        latenciaPromedio: latenciaPromedio,
        dificultad: dificultad,
      );
}
