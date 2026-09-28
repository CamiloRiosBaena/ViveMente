import 'dart:math';

import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/features/atencion/tren_senales/models/nivel_tren.dart';
import 'package:vivamente/features/atencion/tren_senales/models/tren.dart';

/// Sortea el color objetivo y arma la secuencia de trenes de una ronda. Pasa un
/// tren a la vez y el último termina de cruzar antes de que acabe el tiempo.
class GeneradorTrenes {
  GeneradorTrenes({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Último objetivo de cada nivel, para no repetirlo en el intento siguiente.
  final _ultimoObjetivo = <Dificultad, ColorTren>{};

  /// Más de dos objetivos seguidos se vuelven predecibles.
  static const _maxObjetivosSeguidos = 2;

  /// Color objetivo de un intento nuevo en [dificultad]; nunca el mismo de la
  /// vez anterior en ese nivel.
  ColorTren elegirObjetivo(Dificultad dificultad) {
    final opciones = PaletaTren.objetivos.where((c) => c != _ultimoObjetivo[dificultad]).toList();
    return _ultimoObjetivo[dificultad] = opciones[_random.nextInt(opciones.length)];
  }

  /// Un distractor para mostrar como «este no» en las instrucciones.
  ColorTren ejemploDistractor(NivelTren nivel, ColorTren objetivo) {
    final opciones = nivel.distractoresPara(objetivo);
    return opciones[_random.nextInt(opciones.length)];
  }

  List<Tren> prueba(NivelTren nivel, ColorTren objetivo) {
    final disponible = nivel.duracion - NivelTren.arranque - nivel.cruce;
    final total = disponible.inMilliseconds ~/ nivel.paso.inMilliseconds + 1;
    final objetivos = max(1, (total * nivel.proporcionObjetivo).round());
    return _armar(nivel, objetivo, total, objetivos);
  }

  List<Tren> practica(NivelTren nivel, ColorTren objetivo) {
    const total = NivelTren.trenesPractica;
    return _armar(nivel.practica, objetivo, total, total ~/ 2);
  }

  /// Momento en que la vía queda vacía tras el último tren.
  static Duration fin(NivelTren nivel, List<Tren> trenes) =>
      trenes.isEmpty ? Duration.zero : trenes.last.salida + nivel.cruce;

  List<Tren> _armar(NivelTren nivel, ColorTren objetivo, int total, int objetivos) {
    final orden = _orden(total, objetivos);
    final distractores = nivel.distractoresPara(objetivo);
    final trenes = <Tren>[];
    ColorTren? anterior;

    for (var i = 0; i < total; i++) {
      final esObjetivo = orden[i];
      final locomotora = esObjetivo ? objetivo : _distractor(distractores, anterior);
      anterior = locomotora;
      trenes.add(Tren(
        id: i,
        locomotora: locomotora,
        vagones: _vagones(nivel, locomotora, objetivo, esObjetivo),
        salida: NivelTren.arranque + nivel.paso * i,
        esObjetivo: esObjetivo,
      ));
    }
    return trenes;
  }

  /// `true` donde va un tren objetivo. Se baraja hasta que no haya rachas largas.
  List<bool> _orden(int total, int objetivos) {
    final orden = [for (var i = 0; i < total; i++) i < objetivos];
    for (var intento = 0; intento < 50; intento++) {
      orden.shuffle(_random);
      if (_rachaMaxima(orden) <= _maxObjetivosSeguidos) break;
    }
    return orden;
  }

  static int _rachaMaxima(List<bool> orden) {
    var maxima = 0, actual = 0;
    for (final o in orden) {
      actual = o ? actual + 1 : 0;
      maxima = max(maxima, actual);
    }
    return maxima;
  }

  /// Evita repetir el color del tren anterior para que se note el cambio.
  ColorTren _distractor(List<ColorTren> distractores, ColorTren? anterior) {
    final opciones = distractores.where((c) => c != anterior).toList();
    final lista = opciones.isEmpty ? distractores : opciones;
    return lista[_random.nextInt(lista.length)];
  }

  /// El primer vagón repite la locomotora y los demás son de relleno. En los
  /// distractores del nivel 3 el primer vagón puede ser del color objetivo.
  List<ColorTren> _vagones(NivelTren nivel, ColorTren locomotora, ColorTren objetivo, bool esObjetivo) {
    final cantidad = 2 + _random.nextInt(2);
    final engano = !esObjetivo && _random.nextDouble() < nivel.probabilidadVagonEngano;
    return [
      engano ? objetivo : locomotora,
      for (var i = 1; i < cantidad; i++) ColorTren.relleno,
    ];
  }
}
