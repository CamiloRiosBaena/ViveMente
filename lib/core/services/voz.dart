import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Lectura en voz alta. Va detrás de un contrato para poder probar sin audio.
abstract class Voz {
  /// Empieza a leer [texto]. Devuelve `false` si el equipo no tiene un motor
  /// de voz disponible o la lectura no pudo arrancar.
  Future<bool> decir(String texto);
  Future<void> callar();

  /// Se llama cuando la lectura termina, se corta o falla.
  set alTerminar(VoidCallback? callback);
}

class VozTts implements Voz {
  VozTts() {
    _tts.setCompletionHandler(_terminar);
    _tts.setCancelHandler(_terminar);
    _tts.setErrorHandler((_) => _terminar());
  }

  final _tts = FlutterTts();
  Future<bool>? _preparada;
  VoidCallback? _alTerminar;

  /// Español de Colombia si el equipo lo trae; si no, cualquier español.
  static const _idiomas = ['es-CO', 'es-US', 'es-419', 'es-MX', 'es-ES', 'es'];

  /// Más pausada que la velocidad normal. En web 1.0 es la normal; en Android
  /// e iOS lo es 0.5.
  static const _velocidad = kIsWeb ? 0.85 : 0.42;

  /// Si el motor no responde en este tiempo se da la lectura por fallida.
  static const _espera = Duration(seconds: 4);

  static bool get _esAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  set alTerminar(VoidCallback? callback) => _alTerminar = callback;

  void _terminar() => _alTerminar?.call();

  /// `false` si no hay motor de voz. En Android se revisa antes de hablar: si
  /// no hay motor, flutter_tts reintenta conectarse sin fin y traba la app.
  Future<bool> _preparar() async {
    try {
      if (_esAndroid) {
        final motores = await _tts.getEngines.timeout(_espera);
        if (motores is! List || motores.isEmpty) return false;
      }
      for (final idioma in _idiomas) {
        if (await _tts.isLanguageAvailable(idioma).timeout(_espera) == true) {
          await _tts.setLanguage(idioma);
          break;
        }
      }
      await _tts.setSpeechRate(_velocidad);
      await _tts.awaitSpeakCompletion(false);
      return true;
    } catch (_) {
      // Plataforma sin soporte o motor que no responde.
      return false;
    }
  }

  @override
  Future<bool> decir(String texto) async {
    if (!await (_preparada ??= _preparar())) {
      // Se vuelve a revisar la próxima vez, por si instalan un motor de voz.
      _preparada = null;
      return false;
    }
    try {
      await _tts.stop();
      return await _tts.speak(texto).timeout(_espera) == 1;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> callar() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Sin motor no hay nada que detener.
    }
    _terminar();
  }
}

final vozProvider = Provider<Voz>((_) => VozTts());

enum EstadoLectura { quieta, leyendo, noDisponible }

/// Si se está leyendo algo en voz alta, o si el equipo no tiene voz.
class LecturaNotifier extends Notifier<EstadoLectura> {
  @override
  EstadoLectura build() {
    ref.watch(vozProvider).alTerminar = () {
      if (ref.mounted && state == EstadoLectura.leyendo) state = EstadoLectura.quieta;
    };
    return EstadoLectura.quieta;
  }

  Voz get _voz => ref.read(vozProvider);

  Future<void> leer(String texto) async {
    state = EstadoLectura.leyendo;
    final empezo = await _voz.decir(texto);
    if (!empezo && ref.mounted) state = EstadoLectura.noDisponible;
  }

  Future<void> detener() async {
    await _voz.callar();
    if (ref.mounted) state = EstadoLectura.quieta;
  }

  /// Lee [texto] o, si ya estaba leyendo, se detiene.
  Future<void> alternar(String texto) =>
      state == EstadoLectura.leyendo ? detener() : leer(texto);
}

final lecturaProvider = NotifierProvider<LecturaNotifier, EstadoLectura>(LecturaNotifier.new);
