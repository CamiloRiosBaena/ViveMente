import 'dart:math';

import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/models/categoria.dart';

/// Parámetros de una ronda según la dificultad. Todas duran 60 segundos;
/// cambia la categoría, de las que tienen más palabras a mano a las que
/// piden buscar más.
///
/// - Nivel 1: animales o frutas.
/// - Nivel 2: objetos del hogar o profesiones.
/// - Nivel 3: ciudades.
///
/// La práctica usa colores, que no sale en ningún nivel.
class NivelCategoria {
  const NivelCategoria({required this.dificultad, required this.categorias});

  final Dificultad dificultad;

  /// Categorías posibles; en cada intento se sortea una.
  final List<Categoria> categorias;

  static const duracion = Duration(seconds: 60);

  static const categoriaPractica = Categoria.colores;
  static const duracionPractica = Duration(seconds: 20);

  static const _nivel1 = NivelCategoria(
    dificultad: Dificultad.facil,
    categorias: [Categoria.animales, Categoria.frutas],
  );

  static const _nivel2 = NivelCategoria(
    dificultad: Dificultad.medio,
    categorias: [Categoria.hogar, Categoria.profesiones],
  );

  static const _nivel3 = NivelCategoria(
    dificultad: Dificultad.dificil,
    categorias: [Categoria.ciudades],
  );

  static NivelCategoria de(Dificultad d) => switch (d) {
        Dificultad.facil => _nivel1,
        Dificultad.medio => _nivel2,
        Dificultad.dificil => _nivel3,
      };
}

/// Sortea la categoría de cada intento sin repetir la anterior del nivel,
/// mientras haya otra.
class SorteoCategoria {
  SorteoCategoria({Random? random}) : _random = random ?? Random();

  final Random _random;
  final _ultima = <Dificultad, Categoria>{};

  Categoria elegir(NivelCategoria nivel) {
    final otras = nivel.categorias.where((c) => c != _ultima[nivel.dificultad]).toList();
    final opciones = otras.isEmpty ? nivel.categorias : otras;
    final c = opciones[_random.nextInt(opciones.length)];
    _ultima[nivel.dificultad] = c;
    return c;
  }
}
