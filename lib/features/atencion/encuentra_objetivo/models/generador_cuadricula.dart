import 'dart:math';

import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/models/estimulo.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/models/nivel_busqueda.dart';

/// Sortea el objetivo y arma una cuadrícula nueva para cada intento.
class GeneradorCuadricula {
  GeneradorCuadricula({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Último objetivo de cada nivel, para no repetirlo en el intento siguiente.
  final _ultimoObjetivo = <Dificultad, String>{};

  Objetivo elegirObjetivo(Dificultad dificultad) {
    final opciones =
        CatalogoEstimulos.objetivos.where((o) => o.simbolo != _ultimoObjetivo[dificultad]).toList();
    final elegido = opciones[_random.nextInt(opciones.length)];
    _ultimoObjetivo[dificultad] = elegido.simbolo;
    return elegido;
  }

  /// Casillas de izquierda a derecha y de arriba abajo, con los objetivos en
  /// posiciones al azar.
  List<Estimulo> cuadricula(NivelBusqueda nivel, Objetivo objetivo) {
    final cantidad = nivel.objetivosMin + _random.nextInt(nivel.objetivosMax - nivel.objetivosMin + 1);
    final distractores = _distractores(nivel, objetivo);
    final casillas = [
      for (var i = 0; i < cantidad; i++) objetivo.estimulo,
      for (var i = cantidad; i < nivel.casillas; i++) distractores[_random.nextInt(distractores.length)],
    ]..shuffle(_random);
    return casillas;
  }

  /// Dos distractores para el ejemplo «estos no» de las instrucciones.
  List<Estimulo> ejemplos(NivelBusqueda nivel, Objetivo objetivo) {
    final opciones = _distractores(nivel, objetivo).toSet().toList()..shuffle(_random);
    return opciones.take(2).toList();
  }

  /// Lista con repeticiones: los parecidos pesan según [NivelBusqueda.proporcionParecidos].
  List<Estimulo> _distractores(NivelBusqueda nivel, Objetivo objetivo) {
    // Nunca el objetivo; fuera del nivel 3, tampoco sus parecidos.
    final excluir = {objetivo.simbolo, ...objetivo.parecidos};
    final variados = (CatalogoEstimulos.variados.where((s) => !excluir.contains(s)).toList()..shuffle(_random))
        .take(nivel.variedad)
        .map(Estimulo.de)
        .toList();
    if (nivel.proporcionParecidos == 0) return variados;

    // Se arma una bolsa de 100 donde los parecidos ocupan su proporción.
    final parecidos = objetivo.parecidos.map(Estimulo.de).toList();
    final nParecidos = (100 * nivel.proporcionParecidos).round();
    return [
      for (var i = 0; i < nParecidos; i++) parecidos[i % parecidos.length],
      for (var i = 0; i < 100 - nParecidos; i++) variados[i % variados.length],
    ];
  }
}
