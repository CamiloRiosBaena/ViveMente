import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/services/reloj.dart';
import 'package:vivamente/core/services/voz.dart';
import 'package:vivamente/features/atencion/tren_senales/models/generador_trenes.dart';
import 'package:vivamente/features/atencion/tren_senales/models/metricas_tren.dart';
import 'package:vivamente/features/atencion/tren_senales/models/nivel_tren.dart';
import 'package:vivamente/features/atencion/tren_senales/models/tren.dart';
import 'package:vivamente/features/atencion/tren_senales/tren_senales_game.dart';
import 'package:vivamente/features/juegos/providers/juegos_provider.dart';

enum FaseTren { instrucciones, practica, finPractica, prueba, resultado }

/// Refuerzo tras cada evento: acierto (positivo), señal con otro tren o tren
/// objetivo que pasó sin señal (negativos).
enum RetroTren {
  ninguna,
  bien,
  noEra,
  sePaso;

  bool get positiva => this == bien;
}

class TrenSenalesState {
  const TrenSenalesState({
    required this.nivel,
    required this.objetivo,
    required this.ejemploDistractor,
    this.fase = FaseTren.instrucciones,
    this.enVia,
    this.respondido = false,
    this.transcurrido = Duration.zero,
    this.pausado = false,
    this.senales = 0,
    this.retro = RetroTren.ninguna,
    this.retroId = 0,
    this.metricas = const MetricasTren(),
    this.resultado,
  });

  final NivelTren nivel;

  /// Color que cuenta en este intento. Se sortea al entrar o al cambiar de nivel.
  final ColorTren objetivo;

  /// Tren que no cuenta, para el ejemplo «este no» de las instrucciones.
  final ColorTren ejemploDistractor;

  final FaseTren fase;

  /// Tren que está cruzando; nunca hay dos a la vez.
  final Tren? enVia;

  /// Ya se dio la señal para [enVia].
  final bool respondido;

  final Duration transcurrido;
  final bool pausado;

  /// Veces que se tocó el botón en la ronda medida.
  final int senales;
  final RetroTren retro;

  /// Sube con cada refuerzo, para que dos iguales seguidos se animen los dos.
  final int retroId;
  final MetricasTren metricas;

  /// Listo al terminar la ronda medida.
  final ResultadoJuego? resultado;

  bool get jugando => fase == FaseTren.practica || fase == FaseTren.prueba;
  bool get enPractica => fase == FaseTren.practica;

  /// Ritmo de los trenes en la fase actual.
  NivelTren get ritmo => enPractica ? nivel.practica : nivel;

  Duration get restante {
    final r = nivel.duracion - transcurrido;
    return r.isNegative ? Duration.zero : r;
  }

  /// Segundos que faltan, redondeados hacia arriba (no muestra «0» con tiempo).
  int get segundosRestantes => (restante.inMilliseconds / 1000).ceil();

  /// Fracción de la ronda medida que ya pasó.
  double get avance =>
      (transcurrido.inMilliseconds / nivel.duracion.inMilliseconds).clamp(0.0, 1.0);

  /// Pista «¡Ahora!» mientras pasa un objetivo sin señal, solo para aprender.
  bool get mostrarAhora =>
      enPractica && (enVia?.esObjetivo ?? false) && !respondido && retro == RetroTren.ninguna;

  /// Consigna completa, la misma que se lee en voz alta.
  String get instruccion {
    final c = objetivo.etiqueta;
    return 'Cuando pase el tren $c, toque el botón grande. '
        'Van a pasar trenes de varios colores. Solo el $c cuenta. '
        'Nivel ${nivel.dificultad.nivel}: dura ${nivel.etiquetaDuracion}. '
        'Antes hay ${NivelTren.trenesPractica} ejemplos de práctica.';
  }

  TrenSenalesState copyWith({
    FaseTren? fase,
    Tren? Function()? enVia,
    bool? respondido,
    Duration? transcurrido,
    bool? pausado,
    int? senales,
    RetroTren? retro,
    int? retroId,
    MetricasTren? metricas,
    ResultadoJuego? Function()? resultado,
  }) =>
      TrenSenalesState(
        nivel: nivel,
        objetivo: objetivo,
        ejemploDistractor: ejemploDistractor,
        fase: fase ?? this.fase,
        enVia: enVia != null ? enVia() : this.enVia,
        respondido: respondido ?? this.respondido,
        transcurrido: transcurrido ?? this.transcurrido,
        pausado: pausado ?? this.pausado,
        senales: senales ?? this.senales,
        retro: retro ?? this.retro,
        retroId: retroId ?? this.retroId,
        metricas: metricas ?? this.metricas,
        resultado: resultado != null ? resultado() : this.resultado,
      );
}

/// Motor de «El tren de las señales». La vista solo pinta este estado y llama
/// a sus métodos.
class TrenSenalesNotifier extends Notifier<TrenSenalesState> {
  /// Cada cuánto se revisa la vía.
  static const _intervalo = Duration(milliseconds: 50);

  /// Tiempo en pantalla de cada refuerzo.
  static const _duracionRetro = Duration(milliseconds: 1100);

  /// Aire tras el último tren de la práctica antes de cerrarla.
  static const _colaPractica = Duration(milliseconds: 600);

  late Reloj _reloj;
  Timer? _timer;
  List<Tren> _trenes = const [];
  int _siguiente = 0;
  Duration _fin = Duration.zero;
  Duration _retroHasta = Duration.zero;

  @override
  TrenSenalesState build() {
    final dificultad = ref.watch(dificultadJuegoProvider(TrenSenalesGame.idJuego));
    _reloj = ref.watch(relojProvider);
    final voz = ref.read(vozProvider);
    ref.onDispose(() {
      _detenerTimer();
      voz.callar();
    });

    final nivel = NivelTren.de(dificultad);
    final generador = ref.read(generadorTrenesProvider);
    final objetivo = generador.elegirObjetivo(dificultad);
    return TrenSenalesState(
      nivel: nivel,
      objetivo: objetivo,
      ejemploDistractor: generador.ejemploDistractor(nivel, objetivo),
    );
  }

  GeneradorTrenes get _generador => ref.read(generadorTrenesProvider);

  /// Lee la consigna en voz alta; si ya se está leyendo, la detiene.
  void escucharInstruccion() => ref.read(lecturaProvider.notifier).alternar(state.instruccion);

  void empezarPractica() {
    final nivel = state.nivel;
    _arrancar(
      FaseTren.practica,
      _generador.practica(nivel, state.objetivo),
      finRonda: (trenes) => GeneradorTrenes.fin(nivel.practica, trenes) + _colaPractica,
    );
  }

  void empezarPrueba() => _arrancar(
        FaseTren.prueba,
        _generador.prueba(state.nivel, state.objetivo),
        finRonda: (_) => state.nivel.duracion,
      );

  /// Vuelve a las instrucciones con el mismo color objetivo.
  void verInstrucciones() {
    _detenerTimer();
    _reloj.reiniciar();
    state = _inicial(FaseTren.instrucciones);
  }

  /// El adulto tocó ¡SEÑAL!
  void senal() {
    if (!state.jugando || state.pausado) return;
    final t = _reloj.transcurrido;
    final tren = state.enVia;
    final senales = state.fase == FaseTren.prueba ? state.senales + 1 : state.senales;

    if (tren != null && tren.esObjetivo) {
      // Tocar de nuevo por el mismo tren objetivo no suma ni resta.
      if (state.respondido) {
        state = state.copyWith(senales: senales);
        return;
      }
      state = _conRetro(
        state.copyWith(
          senales: senales,
          respondido: true,
          metricas: state.metricas.conAcierto(t - tren.salida),
        ),
        RetroTren.bien,
        t,
      );
    } else {
      state = _conRetro(
        state.copyWith(senales: senales, metricas: state.metricas.conComision()),
        RetroTren.noEra,
        t,
      );
    }
  }

  void pausar() {
    if (!state.jugando || state.pausado) return;
    _detenerTimer();
    _reloj.detener();
    state = state.copyWith(pausado: true, transcurrido: _reloj.transcurrido);
  }

  void reanudar() {
    if (!state.jugando || !state.pausado) return;
    state = state.copyWith(pausado: false);
    _reloj.iniciar();
    _iniciarTimer();
  }

  /// Revisa la vía: entra el tren que toca, sale el que terminó de cruzar y se
  /// cierra la ronda al acabar el tiempo. Lo llama el timer.
  @visibleForTesting
  void actualizar() {
    if (!state.jugando || state.pausado) return;
    final t = _reloj.transcurrido;
    var s = state;

    final actual = s.enVia;
    if (actual != null && t >= actual.salida + s.ritmo.cruce) {
      if (actual.esObjetivo) {
        s = s.copyWith(metricas: s.metricas.conObjetivoCerrado(respondido: s.respondido));
        if (!s.respondido) s = _conRetro(s, RetroTren.sePaso, t);
      }
      s = s.copyWith(enVia: () => null, respondido: false);
    }

    if (s.enVia == null && _siguiente < _trenes.length && t >= _trenes[_siguiente].salida) {
      final entra = _trenes[_siguiente];
      _siguiente++;
      s = s.copyWith(enVia: () => entra, respondido: false);
    }

    if (s.retro != RetroTren.ninguna && t >= _retroHasta) {
      s = s.copyWith(retro: RetroTren.ninguna);
    }

    // Solo se avisa a la vista si algo que se ve cambió: un tren, un refuerzo
    // o el segundo del contador.
    final cambioVia = !identical(s, state);
    final segundosAntes = state.segundosRestantes;
    s = s.copyWith(transcurrido: t);
    if (t >= _fin) {
      _terminar(s);
    } else if (cambioVia || s.segundosRestantes != segundosAntes) {
      state = s;
    }
  }

  TrenSenalesState _inicial(FaseTren fase) => TrenSenalesState(
        nivel: state.nivel,
        objetivo: state.objetivo,
        ejemploDistractor: state.ejemploDistractor,
        fase: fase,
      );

  void _arrancar(
    FaseTren fase,
    List<Tren> trenes, {
    required Duration Function(List<Tren>) finRonda,
  }) {
    ref.read(lecturaProvider.notifier).detener();
    _detenerTimer();
    _trenes = trenes;
    _siguiente = 0;
    _fin = finRonda(trenes);
    _reloj
      ..reiniciar()
      ..iniciar();
    state = _inicial(fase);
    _iniciarTimer();
  }

  void _terminar(TrenSenalesState s) {
    _detenerTimer();
    _reloj.detener();
    final base = s.copyWith(enVia: () => null, respondido: false, retro: RetroTren.ninguna);
    state = s.fase == FaseTren.practica
        ? base.copyWith(fase: FaseTren.finPractica)
        : base.copyWith(
            fase: FaseTren.resultado,
            resultado: () => s.metricas.aResultado(duracion: s.transcurrido, dificultad: s.nivel.dificultad),
          );
  }

  TrenSenalesState _conRetro(TrenSenalesState s, RetroTren r, Duration t) {
    _retroHasta = t + _duracionRetro;
    return s.copyWith(retro: r, retroId: s.retroId + 1);
  }

  void _iniciarTimer() => _timer = Timer.periodic(_intervalo, (_) => actualizar());

  void _detenerTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Uno solo en toda la app: recuerda el último color objetivo de cada nivel.
final generadorTrenesProvider = Provider<GeneradorTrenes>((_) => GeneradorTrenes());

final trenSenalesProvider =
    NotifierProvider.autoDispose<TrenSenalesNotifier, TrenSenalesState>(TrenSenalesNotifier.new);
