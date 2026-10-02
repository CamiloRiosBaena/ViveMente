import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Reconocimiento de voz: convierte en texto lo que se dicta al micrófono. Va
/// detrás de un contrato para poder probar sin micrófono.
abstract class Dictado {
  /// Empieza a escuchar. [alOir] recibe lo reconocido; con `final` en `true`
  /// ese texto ya no cambiará. Devuelve `false` si el equipo no tiene
  /// reconocimiento de voz o no se dio permiso para el micrófono.
  Future<bool> escuchar({required void Function(String texto, bool esFinal) alOir});

  /// Deja de escuchar; lo que se alcanzó a oír llega como resultado final.
  Future<void> detener();

  /// Se llama una vez por cada [escuchar] que arrancó, cuando deja de
  /// escuchar: por [detener], por un silencio largo o por error.
  set alTerminar(VoidCallback? callback);
}

class DictadoVoz implements Dictado {
  final _stt = SpeechToText();
  Future<bool>? _preparado;
  String? _idioma;
  VoidCallback? _alTerminar;

  /// Si hay una escucha abierta; evita avisar dos veces el mismo cierre.
  bool _escuchando = false;

  /// Español de Colombia si el equipo lo trae; si no, cualquier español.
  static const _idiomas = ['es_CO', 'es_US', 'es_419', 'es_MX', 'es_ES'];

  /// Silencio tras el cual el reconocedor se cierra. Algunos equipos lo
  /// cierran antes por su cuenta; quien lo usa decide si vuelve a abrirlo.
  static const _pausa = Duration(seconds: 10);

  @override
  set alTerminar(VoidCallback? callback) => _alTerminar = callback;

  void _terminar() {
    if (!_escuchando) return;
    _escuchando = false;
    _alTerminar?.call();
  }

  Future<bool> _preparar() async {
    try {
      final listo = await _stt.initialize(
        onStatus: (estado) {
          if (estado == SpeechToText.doneStatus) _terminar();
        },
        onError: (_) => _terminar(),
      );
      if (!listo) return false;
      final disponibles = (await _stt.locales()).map((l) => l.localeId).toList();
      _idioma = _idiomas.where((i) => disponibles.any((d) => _mismo(d, i))).firstOrNull ??
          disponibles.where((d) => d.toLowerCase().startsWith('es')).firstOrNull;
      return true;
    } catch (_) {
      // Plataforma sin soporte o permiso negado.
      return false;
    }
  }

  static bool _mismo(String a, String b) => a.replaceAll('-', '_').toLowerCase() == b.toLowerCase();

  @override
  Future<bool> escuchar({required void Function(String texto, bool esFinal) alOir}) async {
    if (!await (_preparado ??= _preparar())) {
      // Se vuelve a revisar la próxima vez, por si dan el permiso.
      _preparado = null;
      return false;
    }
    try {
      // Se marca antes: en algunos equipos el cierre llega antes de que
      // listen() termine.
      _escuchando = true;
      await _stt.listen(
        onResult: (r) {
          // Cada equipo entrega distinto; en depuración se ve qué llega.
          if (kDebugMode) debugPrint('dictado${r.finalResult ? ' (final)' : ''}: «${r.recognizedWords}»');
          alOir(r.recognizedWords, r.finalResult);
        },
        listenOptions: SpeechListenOptions(
          localeId: _idioma,
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
          pauseFor: _pausa,
          listenFor: const Duration(minutes: 3),
        ),
      );
      return true;
    } catch (_) {
      _escuchando = false;
      return false;
    }
  }

  @override
  Future<void> detener() async {
    try {
      await _stt.stop();
    } catch (_) {
      // Si no estaba escuchando no hay nada que detener.
    }
    _terminar();
  }
}

final dictadoProvider = Provider<Dictado>((_) => DictadoVoz());
