import 'dart:math';

import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/models/nivel_palabras.dart';

/// Sortea la letra de cada intento sin repetir la anterior del mismo nivel.
class SorteoLetra {
  SorteoLetra({Random? random}) : _random = random ?? Random();

  final Random _random;
  final _ultima = <Dificultad, String>{};

  String elegir(NivelPalabras nivel) {
    final opciones = nivel.letras.where((l) => l != _ultima[nivel.dificultad]).toList();
    final letra = opciones[_random.nextInt(opciones.length)];
    _ultima[nivel.dificultad] = letra;
    return letra;
  }
}
