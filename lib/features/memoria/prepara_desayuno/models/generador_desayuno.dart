import 'dart:math';

import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/models/alimento.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/models/nivel_desayuno.dart';

/// Sortea la lista del desayuno y arma la bandeja de cada intento.
class GeneradorDesayuno {
  GeneradorDesayuno({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Como mucho dos del mismo tipo, para que la lista parezca un desayuno y no
  /// un frutero.
  static const maxPorTipo = 2;

  /// Última lista de cada nivel, para no repetirla en el intento siguiente.
  final _ultimaLista = <Dificultad, Set<Alimento>>{};

  List<Alimento> lista(NivelDesayuno nivel) {
    final n = nivel.elementosMin + _random.nextInt(nivel.elementosMax - nivel.elementosMin + 1);
    final anterior = _ultimaLista[nivel.dificultad];
    List<Alimento> elegida;
    do {
      elegida = _sortear(n);
    } while (anterior != null && elegida.toSet().containsAll(anterior) && anterior.containsAll(elegida));
    _ultimaLista[nivel.dificultad] = elegida.toSet();
    return elegida;
  }

  /// Lista de la práctica. No cuenta como la última del nivel.
  List<Alimento> listaPractica() => _sortear(NivelDesayuno.elementosPractica);

  List<Alimento> _sortear(int n) {
    final mezclados = [...CatalogoAlimentos.todos]..shuffle(_random);
    final porTipo = <TipoAlimento, int>{};
    final elegidos = <Alimento>[];
    for (final a in mezclados) {
      if (elegidos.length == n) break;
      if ((porTipo[a.tipo] ?? 0) >= maxPorTipo) continue;
      porTipo[a.tipo] = (porTipo[a.tipo] ?? 0) + 1;
      elegidos.add(a);
    }
    return elegidos;
  }

  /// Los alimentos de [lista] y otros que no están en ella, en posiciones al
  /// azar.
  List<Alimento> bandeja(NivelDesayuno nivel, List<Alimento> lista) => _bandeja(nivel.bandeja, lista);

  List<Alimento> bandejaPractica(List<Alimento> lista) => _bandeja(NivelDesayuno.bandejaPractica, lista);

  List<Alimento> _bandeja(int tamano, List<Alimento> lista) {
    final otros = CatalogoAlimentos.todos.where((a) => !lista.contains(a)).toList()..shuffle(_random);
    return [...lista, ...otros.take(tamano - lista.length)]..shuffle(_random);
  }
}
