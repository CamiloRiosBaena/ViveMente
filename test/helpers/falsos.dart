import 'package:flutter/foundation.dart';
import 'package:vivamente/core/services/dictado.dart';
import 'package:vivamente/core/services/reloj.dart';
import 'package:vivamente/core/services/voz.dart';

/// Reloj que solo avanza cuando la prueba lo pide.
class RelojFalso implements Reloj {
  Duration _t = Duration.zero;
  bool _corriendo = false;

  void avanzar(Duration d) {
    if (_corriendo) _t += d;
  }

  @override
  Duration get transcurrido => _t;
  @override
  bool get corriendo => _corriendo;
  @override
  void iniciar() => _corriendo = true;
  @override
  void detener() => _corriendo = false;
  @override
  void reiniciar() {
    _corriendo = false;
    _t = Duration.zero;
  }
}

/// Voz que solo anota lo que se le pidió leer.
class VozFalsa implements Voz {
  final dichos = <String>[];

  /// `false` simula un equipo sin motor de voz.
  bool disponible = true;
  VoidCallback? _alTerminar;

  @override
  set alTerminar(VoidCallback? callback) => _alTerminar = callback;

  @override
  Future<bool> decir(String texto) async {
    if (!disponible) return false;
    dichos.add(texto);
    return true;
  }

  @override
  Future<void> callar() async {
    await Future<void>.value();
    _alTerminar?.call();
  }
}

/// Dictado que la prueba alimenta a mano con [oir].
class DictadoFalso implements Dictado {
  /// `false` simula un equipo sin micrófono o sin permiso.
  bool disponible = true;
  bool escuchando = false;

  /// Cuántas veces se abrió el micrófono.
  int aperturas = 0;

  /// Con `false`, [detener] no entrega lo último que oyó, como un equipo
  /// que nunca manda el resultado final.
  bool entregaFinal = true;

  /// A quién avisar en cada escucha, en orden: la última es la abierta.
  final _escuchas = <void Function(String texto, bool esFinal)>[];
  VoidCallback? _alTerminar;

  /// Lo último que oyó la escucha abierta y si ya fue el resultado final.
  String _ultimo = '';
  bool _final = true;

  /// Simula que el reconocedor oyó [texto] en la escucha abierta.
  void oir(String texto, {bool esFinal = true}) {
    if (escuchando) {
      _ultimo = texto;
      _final = esFinal;
    }
    if (_escuchas.isNotEmpty) _escuchas.last(texto, esFinal);
  }

  /// Simula que llega tarde algo de la escucha número [escucha] (desde 0).
  void oirEn(int escucha, String texto, {bool esFinal = true}) => _escuchas[escucha](texto, esFinal);

  /// Simula que el reconocedor se cerró solo, tras un silencio, sin
  /// entregar el resultado final.
  void cerrarSolo() {
    escuchando = false;
    _alTerminar?.call();
  }

  @override
  set alTerminar(VoidCallback? callback) => _alTerminar = callback;

  @override
  Future<bool> escuchar({required void Function(String texto, bool esFinal) alOir}) async {
    if (!disponible) return false;
    _escuchas.add(alOir);
    escuchando = true;
    _ultimo = '';
    _final = true;
    aperturas++;
    return true;
  }

  /// Como el reconocedor real: al detenerlo entrega como final lo que oía.
  @override
  Future<void> detener() async {
    if (!escuchando) return;
    escuchando = false;
    if (!_final && entregaFinal) _escuchas.last(_ultimo, true);
    _final = true;
    _alTerminar?.call();
  }
}
