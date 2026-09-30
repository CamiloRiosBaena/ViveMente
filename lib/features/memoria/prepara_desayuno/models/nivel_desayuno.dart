import 'package:vivamente/core/models/game.dart';

/// Parámetros de una ronda según la dificultad. Cambian cuántos alimentos hay
/// que recordar, cuántos trae la bandeja y si cuenta el orden.
///
/// - Nivel 1: 3 alimentos, bandeja de 8.
/// - Nivel 2: 4 o 5 alimentos, bandeja de 12.
/// - Nivel 3: 4 o 5 alimentos en el orden exacto de la lista, bandeja de 12.
///
/// La lista queda a la vista entre 10 y 15 segundos: 3 por alimento.
class NivelDesayuno {
  const NivelDesayuno({
    required this.dificultad,
    required this.elementosMin,
    required this.elementosMax,
    required this.bandeja,
    this.conOrden = false,
  });

  final Dificultad dificultad;

  /// Cuántos alimentos tiene la lista; cambia en cada intento.
  final int elementosMin;
  final int elementosMax;

  /// Alimentos en la bandeja, los de la lista incluidos.
  final int bandeja;

  /// Si hay que ponerlos en el plato en el mismo orden de la lista.
  final bool conOrden;

  /// La práctica es corta: 2 alimentos en una bandeja de 6, con el orden
  /// del nivel.
  static const elementosPractica = 2;
  static const bandejaPractica = 6;

  static const _porElemento = Duration(seconds: 3);
  static const _exposicionMin = Duration(seconds: 10);
  static const _exposicionMax = Duration(seconds: 15);

  /// Cuánto se ve una lista de [elementos] alimentos antes de ocultarse.
  static Duration exposicion(int elementos) {
    final t = _porElemento * elementos;
    if (t < _exposicionMin) return _exposicionMin;
    if (t > _exposicionMax) return _exposicionMax;
    return t;
  }

  /// «3 alimentos», «4 o 5 alimentos».
  String get textoElementos =>
      elementosMin == elementosMax ? '$elementosMin alimentos' : '$elementosMin o $elementosMax alimentos';

  static const _nivel1 = NivelDesayuno(
    dificultad: Dificultad.facil,
    elementosMin: 3,
    elementosMax: 3,
    bandeja: 8,
  );

  static const _nivel2 = NivelDesayuno(
    dificultad: Dificultad.medio,
    elementosMin: 4,
    elementosMax: 5,
    bandeja: 12,
  );

  static const _nivel3 = NivelDesayuno(
    dificultad: Dificultad.dificil,
    elementosMin: 4,
    elementosMax: 5,
    bandeja: 12,
    conOrden: true,
  );

  static NivelDesayuno de(Dificultad d) => switch (d) {
        Dificultad.facil => _nivel1,
        Dificultad.medio => _nivel2,
        Dificultad.dificil => _nivel3,
      };
}
