import 'dart:math';

import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/features/memoria/para_que_sirve/models/banco_objetos.dart';
import 'package:vivamente/features/memoria/para_que_sirve/models/nivel_objetos.dart';
import 'package:vivamente/features/memoria/para_que_sirve/models/pregunta.dart';

/// Arma las preguntas de cada ronda: objetos al azar, sin repetir los de la
/// ronda anterior del nivel mientras alcancen, y distractores que no se
/// puedan tomar por correctos.
class GeneradorPreguntas {
  GeneradorPreguntas({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Objetos de la última ronda de cada nivel.
  final _recientes = <Dificultad, Set<Objeto>>{};

  /// [cantidad] preguntas del nivel, sin los objetos de [excluir] (por
  /// ejemplo, los de la práctica recién hecha).
  List<Pregunta> ronda(NivelObjetos nivel, int cantidad, {Set<Objeto> excluir = const {}}) {
    final preguntas = switch (nivel.tipo) {
      TipoPregunta.funcion => _elegir(
          BancoObjetos.funciones.where((f) => f != BancoObjetos.ejemplo).toList(),
          (f) => f.objeto,
          nivel,
          cantidad,
          excluir,
        ).map((f) => _funcion(nivel, f)).toList(),
      TipoPregunta.lugar => _elegir(BancoObjetos.lugares, (l) => l.objeto, nivel, cantidad, excluir)
          .map((l) => _lugar(nivel, l))
          .toList(),
      TipoPregunta.pareja => _elegir(BancoObjetos.parejas.where((p) => p != BancoObjetos.ejemploPareja).toList(),
              (p) => p.objeto, nivel, cantidad, excluir)
          .map((p) => _pareja(nivel, p))
          .toList(),
    };
    _recientes[nivel.dificultad] = preguntas.map((p) => p.objeto).toSet();
    return preguntas;
  }

  /// Sortea [cantidad] elementos, primero entre los que no salieron en la
  /// ronda anterior y, si no alcanzan, completando con esos.
  List<T> _elegir<T>(List<T> banco, Objeto Function(T) objeto, NivelObjetos nivel, int cantidad, Set<Objeto> excluir) {
    final recientes = _recientes[nivel.dificultad] ?? const {};
    final disponibles = banco.where((e) => !excluir.contains(objeto(e))).toList()..shuffle(_random);
    final nuevos = disponibles.where((e) => !recientes.contains(objeto(e)));
    final repetidos = disponibles.where((e) => recientes.contains(objeto(e)));
    return [...nuevos, ...repetidos].take(cantidad).toList();
  }

  Pregunta _funcion(NivelObjetos nivel, ObjetoFuncion f) {
    final otras = BancoObjetos.funciones.where(f.compatibleCon).map((o) => o.funcion).toSet().toList()
      ..shuffle(_random);
    return _armar(nivel, f.objeto, Opcion(f.funcion), otras.take(NivelObjetos.opciones - 1).map(Opcion.new),
        f.explicacion);
  }

  Pregunta _lugar(NivelObjetos nivel, ObjetoLugar l) {
    final otros = Lugar.values.where((x) => x != l.lugar).toList()..shuffle(_random);
    Opcion opcion(Lugar x) => Opcion(x.etiqueta, icono: x.icono);
    return _armar(nivel, l.objeto, opcion(l.lugar), otros.take(NivelObjetos.opciones - 1).map(opcion), l.explicacion);
  }

  Pregunta _pareja(NivelObjetos nivel, Pareja p) {
    final otras = BancoObjetos.parejas.where(p.compatibleCon).map((o) => o.pareja).toSet().toList()
      ..shuffle(_random);
    Opcion opcion(Objeto o) => Opcion(o.nombre, emoji: o.emoji);
    return _armar(
        nivel, p.objeto, opcion(p.pareja), otras.take(NivelObjetos.opciones - 1).map(opcion), p.explicacion);
  }

  Pregunta _armar(NivelObjetos nivel, Objeto objeto, Opcion correcta, Iterable<Opcion> distractores, String explicacion) {
    final opciones = [correcta, ...distractores]..shuffle(_random);
    return Pregunta(
      objeto: objeto,
      enunciado: nivel.enunciado,
      opciones: opciones,
      correcta: opciones.indexOf(correcta),
      explicacion: explicacion,
    );
  }
}
