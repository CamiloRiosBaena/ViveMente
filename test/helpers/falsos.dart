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
  void Function(String texto, bool esFinal)? _alOir;
  VoidCallback? _alTerminar;

  /// Simula que el reconocedor oyó [texto].
  void oir(String texto, {bool esFinal = true}) => _alOir?.call(texto, esFinal);

  /// Simula que el reconocedor se cerró solo, tras un silencio.
  void cerrarSolo() {
    escuchando = false;
    _alTerminar?.call();
  }

  @override
  set alTerminar(VoidCallback? callback) => _alTerminar = callback;

  @override
  Future<bool> escuchar({required void Function(String texto, bool esFinal) alOir}) async {
    if (!disponible) return false;
    _alOir = alOir;
    escuchando = true;
    aperturas++;
    return true;
  }

  @override
  Future<void> detener() async {
    if (!escuchando) return;
    escuchando = false;
    _alTerminar?.call();
  }
}
